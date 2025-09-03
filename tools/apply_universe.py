#!/usr/bin/env python3
# tools/apply_universe.py
import os, sys, csv, re, math, argparse, glob

def _yaml_get(text, key):
    try:
        import yaml  # type: ignore
        data = yaml.safe_load(text)
    except Exception:
        data = None
    def find(obj, k):
        if isinstance(obj, dict):
            for kk, vv in obj.items():
                if kk == k: return vv
                fv = find(vv, k)
                if fv is not None: return fv
        elif isinstance(obj, list):
            for it in obj:
                fv = find(it, k)
                if fv is not None: return fv
        return None
    v = find(data, key) if data is not None else None
    if v is not None:
        return str(v)
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
    s = str(x).strip().lower()
    return s in ('1','true','yes','y','t')

def read_config():
    cfg_path = os.path.join('config','ats.yaml')
    txt = open(cfg_path,'r',encoding='utf-8').read() if os.path.exists(cfg_path) else ''
    min_cap = os.getenv('MIN_CAP_USD')
    max_w   = os.getenv('MAX_WEIGHT_PCT')
    if min_cap is None:
        raw = _yaml_get(txt,'min_cap_usd')
        min_cap = raw if raw is not None else '0'
    if max_w is None:
        raw = _yaml_get(txt,'max_weight_pct')
        if raw is None: raise SystemExit('ERROR: немає max_weight_pct (або задайте $MAX_WEIGHT_PCT)')
        max_w = raw
    return float(min_cap), _norm_cap(max_w)

def find_file(folder, date):
    p = os.path.join(folder, f'{date}.csv')
    if os.path.exists(p): return p
    files = sorted(glob.glob(os.path.join(folder,'*.csv')), key=lambda x:(os.path.getmtime(x),x), reverse=True)
    return files[0] if files else None

def detect_col(names, candidates):
    for c in candidates:
        if c in names: return c
    lowered = {n.lower(): n for n in names}
    for c in candidates:
        if c.lower() in lowered: return lowered[c.lower()]
    return None

def read_alpha(path):
    with open(path,'r',encoding='utf-8',newline='') as f:
        rdr = csv.DictReader(f)
        sym_col = detect_col(rdr.fieldnames or [], ['symbol','ticker','secid','asset'])
        a_col   = detect_col(rdr.fieldnames or [], ['alpha','score','signal','alpha_score'])
        if not sym_col or not a_col:
            raise SystemExit(f'ERROR: alpha {path} має містити symbol та alpha')
        rows=[]
        for r in rdr:
            s = (r[sym_col] or '').strip().upper()
            a = _to_float(r[a_col], default=0.0)
            if s!='': rows.append((s, a))
        return rows

def read_universe(path):
    with open(path,'r',encoding='utf-8',newline='') as f:
        rdr = csv.DictReader(f)
        sym_col = detect_col(rdr.fieldnames or [], ['symbol','ticker','secid','asset'])
        act_col = detect_col(rdr.fieldnames or [], ['is_active','active'])
        cap_col = detect_col(rdr.fieldnames or [], ['cap_usd','market_cap_usd','mkt_cap','cap'])
        if not sym_col or not act_col or not cap_col:
            raise SystemExit(f'ERROR: universe {path} має містити symbol, is_active, cap_usd')
        rows=[]
        for r in rdr:
            s = (r[sym_col] or '').strip().upper()
            active = _to_bool(r[act_col])
            cap = _to_float(r[cap_col], default=0.0)
            if s!='': rows.append((s, active, cap))
        return rows

def softmax(vals):
    if not vals: return []
    m = max(vals)
    exps = [math.exp(v-m) for v in vals]
    z = sum(exps)
    if z <= 0: return [1.0/len(vals)]*len(vals)
    return [e/z for e in exps]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--date', required=False, default=None)
    args, _ = ap.parse_known_args()
    date = args.date or (os.getenv('ATS_DATE') or '')
    if not date:
        date = __import__('datetime').date.today().strftime('%Y-%m-%d')

    alpha_path = find_file('alpha', date)
    uni_path   = find_file('universe', date)
    if not alpha_path or not uni_path:
        raise SystemExit(f'ERROR: не знайдено alpha/universe для дати {date}')

    min_cap_usd, max_weight_pct = read_config()
    alpha_rows = read_alpha(alpha_path)
    uni_rows   = read_universe(uni_path)

    alpha_map = {s:a for s,a in alpha_rows}
    N = len(alpha_map)

    uni_map = {s:(act,cap) for s,act,cap in uni_rows}
    filtered = []
    for s,(act,cap) in uni_map.items():
        if not act: continue
        if cap is None or cap < min_cap_usd: continue
        if s in alpha_map:
            filtered.append((s, alpha_map[s]))
    M = len(filtered)

    if M == 0: raise SystemExit('ERROR: після фільтра universe порожньо')

    # ключовий лог для smoke-тесту  ДРУКУЄМО ВІДРАЗУ
    print(f"universe filter: {N}->{M}", flush=True)
    print(f"universe filter: {N}→{M}", flush=True)

    # weights: softmax -> cap -> normalize
    syms   = [s for s,_ in filtered]
    alphas = [a for _,a in filtered]
    w = softmax(alphas)
    capped = [min(x, max_weight_pct) for x in w]
    capped_cnt = sum(1 for x in w if x>max_weight_pct)
    s = sum(capped)
    w_norm = [x/s for x in capped] if s>0 else [1.0/M]*M
    print(f'capped {capped_cnt}/{M}', flush=True)

    # write targets/<date>.csv
    out_path = os.path.join('targets', f'{date}.csv')
    os.makedirs('targets', exist_ok=True)
    with open(out_path,'w',encoding='utf-8',newline='') as f:
        wr = csv.writer(f)
        wr.writerow(['symbol','w_final','weight'])
        for sym, ww in zip(syms, w_norm):
            wr.writerow([sym, f'{ww:.12f}', f'{ww:.12f}'])
    return 0

if __name__ == '__main__':
    sys.exit(main())




