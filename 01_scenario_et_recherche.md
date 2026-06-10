# Scénario & synthèse de recherche — Workshop Redshift

## Cas d'usage choisi : "HelvetiCart"

PME e-commerce suisse fictive, ~80 employés, basée à Lausanne.

**Problème.** Toutes les données (commandes, clients, clickstream web) vivent dans le PostgreSQL de production. Les dashboards BI et les analyses ad-hoc des data analysts ralentissent la prod ; certaines requêtes d'agrégation prennent plusieurs minutes.

**Données.**
- ~45 M de lignes de commandes (5 ans d'historique), croissance ~30 GB/mois
- Clickstream web : ~200 M d'événements
- Volume total analytique : **~600 GB**

**Solution proposée.** Décharger l'analytique vers **Redshift Serverless** (région eu-central-1 Frankfurt — pas de Redshift Serverless garanti à Zurich, à vérifier) :
- Ingestion nocturne depuis Postgres (COPY depuis S3, ou zero-ETL si Aurora)
- Dashboards BI (QuickSight/Metabase) + requêtes ad-hoc des analysts branchés sur Redshift
- La prod Postgres ne sert plus que le transactionnel

**Pourquoi c'est "parfait" pour Redshift :** OLAP pur (scans + agrégations sur grosses tables), charge intermittente (heures de bureau → Serverless facture à la seconde), écosystème AWS déjà utilisé (S3), SQL Postgres-compatible donc migration douce pour les analysts.

## Scénario de coût (chiffres à re-vérifier sur aws.amazon.com/redshift/pricing)

Hypothèses : Serverless base 8 RPU, ~3 h de compute facturé/jour ouvré (dashboards matin + ad-hoc), Frankfurt ≈ $0.39/RPU-h, storage géré ≈ $0.024/GB-mois.

| Poste | Calcul | $/mois |
|---|---|---|
| Compute Serverless | 8 RPU × 3 h × 22 j × $0.39 | ~206 |
| Storage géré | 600 GB × $0.024 | ~14 |
| S3 staging + transferts | forfait | ~10 |
| **Total** | | **~230 $/mois (~185 CHF)** |

Points critiques à présenter :
- Le minimum facturé est 60 s par "réveil" → des petites requêtes éparses coûtent cher relativement.
- Si les analysts laissent tourner des requêtes mal écrites, la facture est variable (pas de plafond par défaut → configurer les usage limits !).
- Comparaison : cluster provisionné ra3.xlplus reserved serait plus prévisible mais ~$600+/mois — Serverless gagne pour une charge intermittente.
- Essai gratuit : $300 de crédits / 90 jours pour les nouveaux comptes Serverless (parfait pour la démo).

## Synthèse technique (pour les slides)

**Architecture.** Data warehouse MPP : un leader node planifie, des compute nodes exécutent en parallèle. Stockage **colonnaire** compressé → on ne lit que les colonnes nécessaires. Depuis RA3/Serverless : compute et storage découplés (storage géré sur S3, cache SSD local). AQUA/optimisations auto, Spectrum pour requêter S3 directement, zero-ETL depuis Aurora. (Détails : paper SIGMOD'22.)

**Forces.** Très rapide sur agrégations/scans massifs ; SQL Postgres-like ; intégration AWS (S3, IAM, Glue, QuickSight) ; Serverless = zéro admin de cluster ; pricing storage/compute séparés.

**Faiblesses (à dire honnêtement).**
- Mauvais en OLTP : INSERT ligne-à-ligne très lents, pas fait pour < quelques GB
- Latence plancher de ~100 ms+ même sur des requêtes triviales (et cold start Serverless de plusieurs secondes)
- Tuning encore utile sur provisioned (DISTKEY/SORTKEY, VACUUM, ANALYZE)
- Concurrence limitée vs BigQuery/Snowflake sans concurrency scaling ($)
- Coût difficile à prévoir en Serverless sans garde-fous

**Vendor lock-in.**
- Le SQL est ~Postgres mais les mécanismes clés sont propriétaires : COPY/UNLOAD, DISTKEY/SORTKEY, Spectrum, system tables
- Données sortables via UNLOAD vers S3 en Parquet → la *donnée* n'est pas captive, mais les *pipelines, la sémantique de coût et l'IAM* le sont
- Frais de sortie ("egress") AWS si on migre ailleurs
- Mitigation : garder les données brutes en Parquet sur S3 (lakehouse), Redshift comme moteur remplaçable

**Quand utiliser / ne pas utiliser.**
- ✅ Analytique sur >100 GB, charge BI/batch, déjà sur AWS, équipe SQL
- ❌ < quelques GB (Postgres suffit), OLTP, besoin multi-cloud, requêtes utilisateur temps réel à faible latence

## Sources

- [Pricing officiel](https://aws.amazon.com/redshift/pricing/) · [Free trial $300](https://aws.amazon.com/redshift/free-trial/) · [FAQ](https://aws.amazon.com/redshift/faqs/)
- [Paper SIGMOD'22](https://dl.acm.org/doi/10.1145/3514221.3526029)
- [Billing Serverless (docs)](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-billing.html)
- Comparatifs critiques : [CloudZero pricing guide](https://www.cloudzero.com/blog/redshift-pricing/), [Striim comparison](https://www.striim.com/blog/cloud-data-warehouse-comparison-redshift-vs-bigquery-vs-azure-vs-snowflake-for-real-time-data/), [Definite — alternatives pour petites boîtes](https://www.definite.app/blog/snowflake-alternatives-for-startups)
