# tools/orders_fills.py
import argparse, os
import pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("--date", required=True)
args, _ = ap.parse_known_args()
d = args.date

tgt = f"targets/{d}.csv"
if not os.path.exists(tgt):
    raise SystemExit(f"[orders/fills] FAIL: targets file missing: {tgt}")

df = pd.read_csv(tgt)  # очікуємо колонки: asset, weight
if df.empty:
    raise SystemExit(f"[orders/fills] FAIL: targets empty: {tgt}")

os.makedirs("orders", exist_ok=True)
os.makedirs("execution", exist_ok=True)

# orders = дзеркало targets
orders_path = f"orders/{d}.csv"
df.to_csv(orders_path, index=False)
print(f"[orders] mirror -> {orders_path} (N={len(df)})")

# fills = 100% fill (дзеркало orders)
fills_path = f"execution/{d}.csv"
df.to_csv(fills_path, index=False)
print(f"[fills] 100% fill -> {fills_path}")
