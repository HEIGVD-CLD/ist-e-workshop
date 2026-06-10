-- ============================================================
-- Démo HelvetiCart — Redshift Serverless (Query Editor v2)
-- Ordre d'exécution : 1) DDL  2) COPY  3) requêtes force  4) faiblesse
-- ============================================================

-- 1. DDL ------------------------------------------------------
CREATE TABLE orders (
    order_id     BIGINT,
    customer_id  INT,
    order_date   DATE,
    category     VARCHAR(20),
    canton       CHAR(2),
    channel      VARCHAR(15),
    quantity     SMALLINT,
    amount_chf   DECIMAL(10,2)
)
DISTSTYLE AUTO
SORTKEY (order_date);

-- 2. Chargement massif depuis S3 (LA méthode Redshift) --------
-- Remplacer <BUCKET> et <IAM_ROLE_ARN>. ~5M lignes en <30 s.
COPY orders
FROM 's3://<BUCKET>/orders.csv.gz'
IAM_ROLE '<IAM_ROLE_ARN>'
CSV GZIP;

SELECT COUNT(*) FROM orders;

-- 3. FORCE : agrégations analytiques sur des millions de lignes
-- (montrer le temps d'exécution ; relancer = result cache instantané)

-- CA mensuel par canal (scan complet, ~1-2 s)
SELECT DATE_TRUNC('month', order_date) AS mois, channel,
       SUM(amount_chf) AS ca, COUNT(*) AS nb
FROM orders
GROUP BY 1, 2
ORDER BY 1, 2;

-- Top catégories par canton en 2025 + panier moyen
SELECT canton, category,
       SUM(amount_chf) AS ca,
       AVG(amount_chf) AS panier_moyen,
       RANK() OVER (PARTITION BY canton ORDER BY SUM(amount_chf) DESC) AS rang
FROM orders
WHERE order_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY canton, category
QUALIFY rang <= 3
ORDER BY canton, rang;

-- Clients réguliers : >10 commandes (window + having)
SELECT customer_id, COUNT(*) AS nb, SUM(amount_chf) AS total
FROM orders GROUP BY customer_id HAVING COUNT(*) > 10
ORDER BY total DESC LIMIT 20;

-- 4. FAIBLESSE : Redshift n'est PAS une base transactionnelle --
-- a) Une requête triviale a quand même ~100 ms+ de latence :
SELECT 1;

-- b) INSERTs ligne à ligne = catastrophiques (lancer et commenter)
--    1000 inserts unitaires prennent des MINUTES vs <1 s sur Postgres.
--    (en montrer 5-10 suffit pour faire passer le message)
INSERT INTO orders VALUES (99999991, 1, '2026-06-12', 'books', 'VD', 'web', 1, 25.00);
INSERT INTO orders VALUES (99999992, 1, '2026-06-12', 'books', 'VD', 'web', 1, 25.00);
INSERT INTO orders VALUES (99999993, 1, '2026-06-12', 'books', 'VD', 'web', 1, 25.00);

-- 5. Bonus lock-in : la porte de sortie = UNLOAD vers Parquet --
-- UNLOAD ('SELECT * FROM orders')
-- TO 's3://<BUCKET>/export/orders_'
-- IAM_ROLE '<IAM_ROLE_ARN>' FORMAT PARQUET;
