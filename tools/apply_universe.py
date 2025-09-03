#!/usr/bin/env python3
# tools/apply_universe.py — universe filter + побудова ваг

import os, sys, csv, re, math, argparse, glob

# --- helpers ---
def _yaml_get(text, key):
    m = re.search(rf'^\s*{re.escape(key)}\s*:\s*([^\n#]+)', text, flags=re.M)
    return m.group(1).strip() if m else None

def _norm_cap(v):
    s = str(v).strip()
    if s.endswith('%'): return float(s[:-1])/100.0
    f = float(s); return f/100.0 if f>1 else f

def _to_float(x, default=None):
    if x is None: return default
    s = str(x).strip().replace(',', '')
    try: return float(s)
    except: return default

def _to_bool(x):
    return str(x).strip().lower() in ('1','true','yes','y','t')

def read_config():
    cfg = os.path.join('config','ats.yaml')
    txt = open(cfg,'r',encoding='utf-8').read() if os.path.exists(cfg) else ''
    min_cap = os.getenv('MIN_CAP_USD') or _yaml_get(txt,'min_cap_usd') or '0'
    max_w   = os.getenv('MAX_WEIGHT_PCT') or _yaml_get(txt,'max_weight_pct') or '25%'
    return float(min_cap), _norm_cap(max_w)

def _dict_reader(path):
    with open(path, 'r', encoding='utf-8-sig', newline='') as f:
        sample = f.read(4096); f.seek(0)
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters=',;|\t')
            delim = dialect.delimiter
        except Exception:
            delim = ','
        return list(csv.DictReader(f, delimiter=delim))

def _pick(names, cands):
    if not names: return None
    for c in cands:
        if c in names: return c
    lower = {n.lower(): n for n in names}
    for c in cands:
        if c.lower() in lower: return lower[c.lower()]
    return None

def read_alpha(path):
    rows = _dict_reader(path)
    names = rows[0].keys() if rows else []
    sym = _pick(names, ['symbol','ticker','secid','asset'])
    col = _pick(names, ['alpha','score','signal','alpha_score','value'])
    if not sym or not col:
        raise RuntimeError('missing alpha columns')
    out = []
    for r in rows:
        s = (r.get(sym) or '').strip().upper()
        if not s: continue
        a = _to_float(r.get(col), 0.0)
        out.append((s, a))
    return out

def read_universe(path):
    rows = _dict_reader(path)
    names = rows[0].keys() if rows else []
    sym = _pick(names, ['symbol','ticker','secid','asset'])
    act = _pick(names, ['is_active','active'])
    cap = _pick(names, ['cap_usd','market_cap_usd','mkt_cap','cap'])
    if not sym or not act or not cap:
        raise RuntimeError('missing universe columns')
    out = []
    for r in rows:
        s = (r.get(sym) or '').strip().upper()
        if not s: continue
        a = _to_bool(r.get(act))
        c = _to_float(r.get(cap), 0.0)
        out.append((s, a, c))
    return out

def softmax(vals):
    if not vals: return []
    m = max(vals)
    ex = [math.exp(v-m) for v in vals]
    z = sum(ex) or 1.0
    return [e/z for e in ex]

# --- main ---
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--date', default=None)
    args,_ = ap.parse_known_args()
    date = args.date or os.getenv('ATS_DATE') or __import__('datetime').date.today().strftime('%Y-%m-%d')

    alpha_path = os.path.join('alpha', f'{date}.csv')
    uni_path   = os.path.join('universe', f'{date}.csv')
    if not os.path.exists(alpha_path): raise SystemExit(f'ERROR: alpha file not found: {alpha_path}')
    if not os.path.exists(uni_path):   raise SystemExit(f'ERROR: universe file not found: {uni_path}')

    min_cap_usd, max_weight_pct = read_config()
    alpha_rows = read_alpha(alpha_path)
    uni_rows   = read_universe(uni_path)

    alpha_map = {s:a for s,a in alpha_rows}
    N = len(alpha_map)

    filtered = []
    for s, active, cap in uni_rows:
        if not active: continue
        if cap is None or cap < min_cap_usd: continue
        if s in alpha_map:
            filtered.append((s, alpha_map[s]))
    M = len(filtered)

    # Ключовий лог після реального фільтра:
    print(f'universe filter: {N}{M}')

    if M == 0:
        raise SystemExit('ERROR: empty after universe filter')

    syms   = [s for s,_ in filtered]
    alphas = [a for _,a in filtered]

    w = softmax(alphas)
    w = [min(x, max_weight_pct) for x in w]
    s = sum(w) or 1.0
    w = [x/s for x in w]  # нормування до 1
    capped_cnt = sum(1 for x in w if x > max_weight_pct + 1e-12)
    print(f'capped {capped_cnt}/{len(w)}')

    os.makedirs('targets', exist_ok=True)
    out = os.path.join('targets', f'{date}.csv')
    with open(out,'w',encoding='utf-8',newline='') as f:
        wr = csv.writer(f)
        wr.writerow(['symbol','w_final','weight'])
        for s, ww in zip(syms, w):
            wr.writerow([s, f'{ww:.12f}', f'{ww:.12f}'])
    return 0

if __name__ == '__main__':
    sys.exit(main())
