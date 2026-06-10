# Démo Redshift — mode d'emploi (à faire par un humain, ~1h)

Seule partie que je ne peux pas faire : elle nécessite un compte AWS + carte de crédit.

## Préparation (la veille, pas le jour J)

1. **Compte AWS** : utiliser un compte n'ayant jamais activé Redshift Serverless → **$300 de crédits / 90 jours** (largement assez ; la démo coûte ~0 CHF avec ça).
2. **Région** : `eu-central-1` (Frankfurt).
3. **Générer les données** : `python generate_data.py` → `orders.csv.gz` (~150 MB).
4. **S3** : créer un bucket, uploader `orders.csv.gz`.
5. **Redshift Serverless** (console → Redshift → Serverless) :
   - Workgroup : base capacity **8 RPU** (minimum, suffisant)
   - Namespace : laisser le rôle IAM par défaut, lui ajouter l'accès S3 (`AmazonS3ReadOnlyAccess` suffit pour COPY)
   - Noter l'ARN du rôle IAM
6. Dans **Query Editor v2**, dérouler `demo.sql` une première fois (remplacer `<BUCKET>` et `<IAM_ROLE_ARN>`). Chronométrer chaque étape.
7. **Capturer des screenshots/vidéo de secours** à chaque étape (console, COPY, requêtes avec temps d'exécution, inserts lents). Plan B obligatoire si le wifi/AWS lâche le jour J.

## Le jour J (3 min max dans la présentation)

1. Query Editor déjà ouvert, table déjà chargée.
2. Montrer `COUNT(*)` → 5 M de lignes.
3. Lancer la requête "CA mensuel" → ~1-2 s sur 5M lignes → **force**.
4. Lancer `SELECT 1` puis 2-3 INSERTs unitaires → lenteur visible → **faiblesse, pas une base transactionnelle**.
5. Mentionner UNLOAD Parquet → porte de sortie anti lock-in.

## Après la présentation

**Supprimer le workgroup + namespace + bucket S3** pour ne rien payer.

## Pièges connus

- Le résultat cache rend les re-runs instantanés : pour re-montrer le vrai temps, `SET enable_result_cache_for_session TO off;`
- Cold start Serverless : lancer une requête 5 min avant de présenter pour réveiller l'endpoint (ou en faire un argument : montrer le cold start = honnêteté).
- Facturation minimum 60 s par réveil → ne pas s'inquiéter, couvert par les crédits.
