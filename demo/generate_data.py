#!/usr/bin/env python3
"""Génère les données de démo HelvetiCart (commandes e-commerce).

Usage:  python generate_data.py [n_rows]   (défaut 5_000_000)
Sortie: orders.csv.gz (~150 MB pour 5M lignes) à uploader sur S3.
NB: 5M lignes suffisent pour la démo ; monter à 20-50M si le budget crédits le permet.
"""
import csv, gzip, random, sys, datetime as dt

N = int(sys.argv[1]) if len(sys.argv) > 1 else 5_000_000
random.seed(42)

CATEGORIES = ["electronics", "fashion", "home", "sports", "beauty", "toys", "books", "food"]
CANTONS = ["VD", "GE", "ZH", "BE", "VS", "FR", "NE", "TI", "BS", "SG"]
CHANNELS = ["web", "mobile_app", "marketplace"]
START = dt.date(2021, 1, 1)
DAYS = (dt.date(2026, 6, 1) - START).days

with gzip.open("orders.csv.gz", "wt", newline="") as f:
    w = csv.writer(f)
    for i in range(1, N + 1):
        day = START + dt.timedelta(days=int(random.triangular(0, DAYS, DAYS * 0.8)))
        w.writerow([
            i,                                            # order_id
            random.randint(1, 200_000),                   # customer_id
            day.isoformat(),                              # order_date
            random.choice(CATEGORIES),                    # category
            random.choice(CANTONS),                       # canton
            random.choice(CHANNELS),                      # channel
            random.randint(1, 8),                         # quantity
            round(random.lognormvariate(3.6, 0.9), 2),    # amount_chf
        ])
        if i % 1_000_000 == 0:
            print(f"{i:,} lignes...", file=sys.stderr)
print("OK -> orders.csv.gz", file=sys.stderr)
