# tools/targets_from_alpha.py
import argparse, os, sys
import numpy as np
import pandas as pd

def find_existing(paths):
    for p in paths:
        if p and os.path.exists(p): return p
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", required=True)
    args, _ = ap.parse_known_args()
    d = args.date

    # де шукати alpha
    alpha_path = find_existing([
        f"alpha/{d}.csv",
        f"05_alpha/{d}.csv",
        f"05_alpha/alpha_{d}.csv",
    ])
    if not alpha_path:
        print(f"[targets] FAIL: alpha file not found for date {d} (looked in alpha/ and 05_alpha/)", file=sys.stderr)
        sys.exit(1)

    df = pd.read_csv(alpha_path)
    if df.empty:
        # fallback на пустий alpha
        print(f"[targets] fallback 1/N: alpha empty -> writing uniform weights", file=sys.stderr)
        sys.exit(1)

    # нормалізуємо назви колонок
    df.columns = [c.strip().lower() for c in df.columns]
    # шукаємо колонку з активом і з альфою
    asset_col = next((c for c in ["asset","ticker","symbol","secid","id","isin","bbg"] if c in df.columns), None)
    alpha_col = "alpha" if "alpha" in df.columns else (next((c for c in ["score","signal","pred"] if c in df.columns), None))
    if asset_col is None or alpha_col is None:
        print(f"[targets] FAIL: need columns [asset/ticker/...] and [alpha/score/signal], got: {list(df.columns)}", file=sys.stderr)
        sys.exit(1)

    df = df[[asset_col, alpha_col]].copy()
    df[alpha_col] = pd.to_numeric(df[alpha_col], errors="coerce")
    df = df.dropna(subset=[alpha_col])
    if df.empty:
        print(f"[targets] fallback 1/N: no valid alpha values -> writing uniform weights", file=sys.stderr)
        # все одно згенеруємо рівні ваги за наявними активами (якщо їх 0 — вийдемо з помилкою)
        sys.exit(1)

    a = df[alpha_col].to_numpy(dtype=float)
    n = a.size
    # перевірка "всі однакові"
    if np.allclose(a, a[0], atol=0, rtol=0):
        w = np.full(n, 1.0/n)
        fallback = True
    else:
        # softmax (стабільний)
        z = a - a.max()
        e = np.exp(z)
        w = e / e.sum()
        fallback = False

    out = pd.DataFrame({
        "asset": df[asset_col].astype(str).to_numpy(),
        "weight": w
    })
    out_dir = "targets"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{d}.csv")
    # гарантуємо суму 1 з машинною точністю
    s = out["weight"].sum()
    if s != 0:
        out["weight"] = out["weight"] / s
    out.to_csv(out_path, index=False)

    uniq = out["weight"].round(12).nunique()
    if fallback:
        print(f"[targets] fallback 1/N (N={n}) -> {out_path}")
    else:
        print(f"[targets] softmax computed (N={n}, sum={out['weight'].sum():.6f}, uniq_weights={uniq}) -> {out_path}")

if __name__ == "__main__":
    main()
