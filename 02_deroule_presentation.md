# Déroulé minuté (12 min) — qui dit quoi

| Min | Slide | Contenu | Orateur |
|---|---|---|---|
| 0:00–1:00 | 1–2 | Intro + problème HelvetiCart (la prod qui souffre) | A |
| 1:00–3:30 | 3 | Architecture : colonnaire + MPP, Serverless vs provisionné | A |
| 3:30–5:00 | 4 | Regard critique : promesses tenues vs marketing | B |
| 5:00–7:00 | 5–6 | Coûts (scénario 230 $/mois) + lock-in | B |
| 7:00–10:00 | 7–8 | **Démo live** (3 min max : COPY → requête rapide → INSERTs lents) | C |
| 10:00–11:30 | 9–10 | Recommandations + verdict | D |
| 11:30–12:00 | 11 | Références, transition questions | D |

## Réponses préparées aux questions probables

- **« Pourquoi pas Snowflake/BigQuery ? »** — Comparables techniquement. Redshift gagne si on est déjà sur AWS (IAM, S3, pas de nouveau contrat). BigQuery = facturation au scan plus volatile ; Snowflake = excellent mais contrat séparé et souvent plus cher à petite échelle.
- **« Pourquoi pas juste un réplica Postgres en lecture ? »** — Soulage la prod mais reste un row-store : les agrégations sur 45 M de lignes restent lentes. Valable en dessous de ~50-100 GB.
- **« Et DuckDB / un truc local ? »** — Très bon jusqu'à quelques centaines de GB sur une seule machine, mais pas de partage multi-utilisateurs/BI centralisée native.
- **« Le chiffre de 230 $ est fiable ? »** — C'est une estimation basée sur les prix publics (juin 2026) et des hypothèses d'usage explicites ; la vraie variable est le nombre d'heures de compute. D'où les usage limits.
- **« Cold start de la démo ? »** — Oui, quelques secondes au réveil de l'endpoint Serverless — c'est une des limites qu'on assume.
