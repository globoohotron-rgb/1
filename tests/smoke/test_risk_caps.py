# Smoke-тест на перевірку risk-cap:
# 1) жодна |вага| у targets/<date>.csv не перевищує max_weight_pct із config/ats.yaml
# 2) сума абсолютних ваг = 1 (gross==1)
# 3) у логах "ats run" є рядок "capped N/..." (N може бути 0)
#
# Запуск: python tests/smoke/test_risk_caps.py

import os
import sys
import re
import glob
import subprocess

def _normalize_cap(value):
    """Повертає cap у частках (0..1). Дозволяє '0.015', '1.5', '1.5%'."""
    if isinstance(value, str):
        s = value.strip()
        if s.endswith('%'):
            s = s[:-1].strip()
            cap = float(s) / 100.0
        else:
            cap = float(s)
    else:
        cap = float(value)
    if cap > 1.0:
        cap = cap / 100.0
    if not (0.0 < cap <= 1.0):
        raise ValueError(f"max_weight_pct поза діапазоном після нормалізації: {cap}")
    return cap

def _yaml_get_max_cap(yaml_text):
    """Дістає max_weight_pct з YAML (спершу через PyYAML, якщо є; інакше  через regex)."""
    try:
        import yaml  # type: ignore
        cfg = yaml.safe_load(yaml_text)
    except Exception:
        cfg = None

    def _find_key(obj, key):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k == key:
                    return v
                found = _find_key(v, key)
                if found is not None:
                    return found
        elif isinstance(obj, list):
            for it in obj:
                found = _find_key(it, key)
                if found is not None:
                    return found
        return None

    val = _find_key(cfg, "max_weight_pct") if cfg is not None else None
    if val is not None:
        return val

    m = re.search(r'^\s*max_weight_pct\s*:\s*([^\n#]+)', yaml_text, flags=re.M)
    if m:
        return m.group(1).strip()
    return None

def read_max_cap():
    env_override = os.getenv("MAX_WEIGHT_PCT")
    if env_override:
        try:
            return _normalize_cap(env_override)
        except Exception as e:
            print(f"TEST FAIL: неправильний MAX_WEIGHT_PCT: {e}", file=sys.stderr)
            sys.exit(1)

    path = os.path.join("config", "ats.yaml")
    if not os.path.exists(path):
        print("TEST FAIL: відсутній config/ats.yaml (можна задати MAX_WEIGHT_PCT у змінній оточення)", file=sys.stderr)
        sys.exit(1)
    text = open(path, "r", encoding="utf-8").read()
    raw = _yaml_get_max_cap(text)
    if raw is None:
        print("TEST FAIL: у config/ats.yaml не знайдено ключ max_weight_pct", file=sys.stderr)
        sys.exit(1)
    try:
        return _normalize_cap(raw)
    except Exception as e:
        print(f"TEST FAIL: max_weight_pct не прочитано: {e}", file=sys.stderr)
        sys.exit(1)

def run_ats_and_capture_logs():
    """Пробуємо виконати 'ats run' (спершу з --dry-run), інакше читаємо останній лог із logs/*.log."""
    cmd = os.getenv("ATS_BIN", "ats")
    tries = [
        [cmd, "run", "--dry-run"],
        [cmd, "run"],
    ]
    for args in tries:
        try:
            cp = subprocess.run(args, capture_output=True, text=True, timeout=int(os.getenv("ATS_SMOKE_TIMEOUT", "90")))
            out = (cp.stdout or "") + "\n" + (cp.stderr or "")
            if out.strip():
                return out
        except FileNotFoundError:
            break
        except Exception:
            continue
    logs = sorted(glob.glob(os.path.join("logs", "*.log")), key=lambda p: (os.path.getmtime(p), p), reverse=True)
    if logs:
        try:
            return open(logs[0], "r", encoding="utf-8", errors="ignore").read()
        except Exception:
            pass
    return ""

def latest_targets_csv():
    files = sorted(glob.glob(os.path.join("targets", "*.csv")), key=lambda p: (os.path.getmtime(p), p), reverse=True)
    return files[0] if files else None

def read_weights_from_csv(path):
    import csv
    with open(path, "r", encoding="utf-8", newline="") as f:
        rdr = csv.DictReader(f)
        candidates = ["w_final", "weight", "w", "weight_pct"]
        col = next((c for c in candidates if c in (rdr.fieldnames or [])), None)
        if not col:
            raise RuntimeError(f"не знайдено колонку ваг у {path}; очікувались: {candidates}")
        ws = []
        for row in rdr:
            try:
                ws.append(float(row[col]))
            except Exception as e:
                raise RuntimeError(f"некоректне значення ваги у {path}: {e}")
        if not ws:
            raise RuntimeError(f"порожній файл {path}")
        return ws, col

def approx_equal(a, b, tol=1e-6):
    return abs(a - b) <= tol

def main():
    cap = read_max_cap()

    # 3) лог має містити "capped N/..."
    logtext = run_ats_and_capture_logs()
    m = re.search(r'capped\s+(\d+)\s*/\s*(\d+)', logtext)
    if not m:
        print('TEST FAIL: в логах "ats run" не знайдено рядок виду: capped N/... (N може бути 0)', file=sys.stderr)
        sys.exit(1)

    # 12) перевірки targets/<date>.csv
    csv_path = latest_targets_csv()
    if not csv_path:
        print("TEST FAIL: не знайдено targets/<date>.csv", file=sys.stderr)
        sys.exit(1)
    try:
        ws, col = read_weights_from_csv(csv_path)
    except Exception as e:
        print(f"TEST FAIL: {e}", file=sys.stderr)
        sys.exit(1)

    max_abs = max(abs(w) for w in ws)
    over = [w for w in ws if abs(w) - cap > 1e-12]
    gross = sum(abs(w) for w in ws)

    if over:
        print(f"TEST FAIL: {len(over)} ваг(и) перевищують cap={cap:.6f}; max|w|={max_abs:.6f}; файл={csv_path}", file=sys.stderr)
        sys.exit(1)
    if not approx_equal(gross, 1.0, tol=1e-6):
        print(f"TEST FAIL: сума абсолютних ваг (gross) = {gross:.12f} != 1.0 (col={col}; файл={csv_path})", file=sys.stderr)
        sys.exit(1)

    print('TEST PASS: усі ваги в межах cap, gross=1, та у логах "ats run" присутній рядок "capped N/..."')

if __name__ == "__main__":
    main()
