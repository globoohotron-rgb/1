#!/usr/bin/env python3
# tools/apply_universe.py  universe-діагностика + побудова ваг
# Друкує:
#   1) universe path=<abs> exists=<True/False>
#   2) universe filter: NM   або   NN (SKIP: <reason>)
# Потім рахує ваги: softmax  cap(max_weight_pct)  нормування до 1, пише targets/<date>.csv

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
    cfg = os.path.join('config','ats.yaml')
    txt = open(cfg,'r',encoding='utf-8').read() if os.path.exists(cfg) else ''
    min_cap = os.getenv('MIN_CAP_USD') or _yaml_get(txt,'min_cap_usd') or '0'
    max_w   = os.getenv('MAX_WEIGHT_PCT') or _yaml_get(txt,'max_weight_pct') or '25%'
    return float(min_cap), _norm_cap(max_w)

def find_file(folder, date):
    p = os.path.join(folder, f'{date}.csv')
    if os.path.exists(p): return p
    files = sorted(glob.glob(os.path.join(folder,'*.csv')), key=lambda x:(os.path.getmtime(x),x), reverse=True)
    return files[0] if files else p  # повертаємо очікуваний шлях (для діагностики)

def detect_col(names, candidates):
    for c in candidates:
        if c in names: return c
    lower = {n.lower(): n for n in names}
    for c in candidates:
        if c.lower() in lower: return lower[c.lower()]
    return None

def read_alpha(path):
    rows=[]
    with open(path,'r',encoding='utf-8',newline='') as f:
        rdr = csv.DictReader(f)
        sym = detect_col(rdr.fieldnames or [], ['symbol','ticker','secid','asset'])
        col = detect_col(rdr.fieldnames or [], ['alpha','score','signal','alpha_score'])
        if not sym or not col:
            raise RuntimeError('missing required columns in alpha')
        for r in rdr:
            s = (r[sym] or '').strip().upper()
            a = _to_float(r[col], 0.0)
            if s: rows.append((s,a))
    return rows

def read_universe(path):
    rows=[]
    with open(path,'r',encoding='utf-8',newline='') as f:
        rdr = csv.DictReader(f)
        sym = detect_col(rdr.fieldnames or [], ['symbol','ticker','secid','asset'])
        act = detect_col(rdr.fieldnames or [], ['is_active','active'])
        cap = detect_col(rdr.fieldnames or [], ['cap_usd','market_cap_usd','mkt_cap','cap'])
        if not sym or not act or not cap:
            raise RuntimeError('missing required columns in universe')
        for r in rdr:
            s = (r[sym] or '').strip().upper()
            a = _to_bool(r[act])
            c = _to_float(r[cap], 0.0)
            if s: rows.append((s,a,c))
    return rows

def softmax(vals):
    if not vals: return []
    m = max(vals)
    exps = [math.exp(v-m) for v in vals]
    z = sum(exps)
    return [e/z for e in exps] if z>0 else [1.0/len(vals)]*len(vals)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--date', default=None)
    args,_ = ap.parse_known_args()
    date = args.date or os.getenv('ATS_DATE') or __import__('datetime').date.today().strftime('%Y-%m-%d')

    alpha_path = find_file('alpha', date)
    uni_path   = find_file('universe', date)

    # 1) ДІАГНОСТИКА ШЛЯХУ
    uni_abs = os.path.abspath(uni_path)
    uni_ex  = os.path.exists(uni_path)
    print(f'universe path={uni_abs} exists={uni_ex}', flush=True)

    # 2) Читаємо alpha (N) та universe (для M); при помилках  SKIP і фолбек
    skip_reason = None
    alpha_rows = []
    try:
        if not os.path.exists(alpha_path):
            skip_reason = 'alpha not found'
        else:
            alpha_rows = read_alpha(alpha_path)
    except Exception:
        skip_reason = 'alpha read error'
    alpha_map = {s:a for s,a in alpha_rows}
    N = len(alpha_map)

    filtered = list(alpha_map.items())  # фолбек: без фільтра
    M = N

    if skip_reason is None:
        if not uni_ex:
            skip_reason = 'universe not found'
        else:
            try:
                min_cap_usd, max_weight_pct = read_config()  # читаємо тут, щоб diag охоплював і поріг
                uni_rows = read_universe(uni_path)
                # застосовуємо фільтр
                fm = []
                for s,active,cap in uni_rows:
                    if not active: continue
                    if cap is None or cap < min_cap_usd: continue
                    if s in alpha_map:
                        fm.append((s, alpha_map[s]))
                if not fm:
                    skip_reason = 'empty after filter'
                else:
                    filtered = fm
                    M = len(filtered)
            except RuntimeError as e:
                skip_reason = str(e)
            except Exception:
                skip_reason = 'universe read error'

    # 3) ДІАГНОСТИЧНИЙ РЯДОК ФІЛЬТРА
    if skip_reason:
        print(f'universe filter: {N}{N} (SKIP: {skip_reason})', flush=True)
    else:
        print(f'universe filter: {N}{M}', flush=True)

    # 4) Побудова ваг (на filtered або фолбеку)
    if not filtered:
        # крайній фолбек, щоб не впасти
        filtered = list(alpha_map.items())
        M = len(filtered)

    # конфіг для cap (повторно, якщо не читали)
    try:
        _, max_weight_pct
    except NameError:
        _, max_weight_pct = read_config()

    syms   = [s for s,_ in filtered]
    alphas = [a for _,a in filtered]

    w = softmax(alphas)
    capped = [min(x, max_weight_pct) for x in w]
    capped_cnt = sum(1 for x in w if x>max_weight_pct)
    s = sum(capped) or 1.0
    w_norm = [x/s for x in capped]
    print(f'capped {capped_cnt}/{len(syms)}', flush=True)

    os.makedirs('targets', exist_ok=True)
    out_path = os.path.join('targets', f'{date}.csv')
    with open(out_path,'w',encoding='utf-8',newline='') as f:
        wr = csv.writer(f)
        wr.writerow(['symbol','w_final','weight'])
        for sym, ww in zip(syms, w_norm):
            wr.writerow([sym, f'{ww:.12f}', f'{ww:.12f}'])
    return 0

if __name__ == '__main__':
    sys.exit(main())
