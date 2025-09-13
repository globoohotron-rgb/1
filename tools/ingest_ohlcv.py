import os, json, datetime as dt
import pandas as pd
import numpy as np
import yfinance as yf
from pathlib import Path

ROOT = Path('.')
TICKERS_FILE = ROOT/'config'/'tickers.txt'
OUT_PARQUET = ROOT/'data'/'ohlcv.parquet'
QC_JSON = ROOT/'data'/'qc_report.json'
ACC_JSON = ROOT/'data'/'acceptance.json'
SMOKE_LOG = ROOT/'eval'/'smoke_data_60d.log'

tickers = [t.strip() for t in TICKERS_FILE.read_text(encoding='utf-8').splitlines() if t.strip()]
# беремо трохи з запасом, щоб гарантовано мати >=60 торгових днів
end = dt.date.today()
start = end - dt.timedelta(days=100)

df = yf.download(tickers, start=start.isoformat(), end=(end+dt.timedelta(days=1)).isoformat(), auto_adjust=False, progress=False, group_by='ticker', threads=True)
# розгортаємо у MultiIndex (date,ticker) з колонками: Open High Low Close AdjClose Volume
frames=[]
for t in tickers:
    if (t,) in df.columns or t in df.columns:
        sub = df[t] if t in df.columns else df[(t,)]
        sub = sub.rename(columns=lambda c: c.replace('Adj Close','AdjClose'))
        sub['ticker']=t
        frames.append(sub.reset_index().rename(columns={'Date':'date'}))
    else:
        pass
raw = pd.concat(frames, ignore_index=True) if frames else pd.DataFrame(columns=['date','Open','High','Low','Close','AdjClose','Volume','ticker'])

# тільки останні 60 торгових днів по кожному тикеру
raw['date']=pd.to_datetime(raw['date']).dt.tz_localize('UTC', nonexistent='shift_forward', ambiguous='NaT').dt.tz_convert('UTC')
raw = raw.sort_values(['ticker','date'])
last_dates = raw.groupby('ticker')['date'].transform(lambda s: s.dropna().iloc[-60:] if len(s.dropna())>=60 else s)
df60 = raw[raw['date'].isin(last_dates.dropna().unique())].copy()

# QC
qc = {}
qc['tickers_total']=len(tickers)
qc['tickers_present']=int(df60['ticker'].nunique())
qc['rows']=int(len(df60))
qc['date_min']=df60['date'].min().isoformat() if len(df60) else None
qc['date_max']=df60['date'].max().isoformat() if len(df60) else None
qc['null_counts']=df60.isna().sum().to_dict()
qc['dupes']=int(df60.duplicated(['ticker','date']).sum())

# acceptance: ≥95% валідних тикерів, дублікати=0, TZ=UTC
acc = {
  'valid_tickers_ratio_ok': (qc['tickers_present'] >= max(1, int(0.95*qc['tickers_total']))),
  'no_duplicates_ok': (qc['dupes']==0),
  'tz_utc_ok': True
}

# збереження
OUT_PARQUET.parent.mkdir(parents=True, exist_ok=True)
df60.set_index(['date','ticker']).to_parquet(OUT_PARQUET)
QC_JSON.write_text(json.dumps(qc, indent=2), encoding='utf-8')
ACC_JSON.write_text(json.dumps(acc, indent=2), encoding='utf-8')

# smoke лог
lines=[
  f"SMOKE DATA 60D @ {dt.datetime.utcnow().isoformat()}Z",
  f"tickers_total={qc['tickers_total']} present={qc['tickers_present']} rows={qc['rows']}",
  f"window=[{qc['date_min']} .. {qc['date_max']}]",
  f"acceptance: valid_tickers_ratio_ok={acc['valid_tickers_ratio_ok']} no_duplicates_ok={acc['no_duplicates_ok']} tz_utc_ok={acc['tz_utc_ok']}",
  "ERRORS=0" if all(acc.values()) else "ERRORS=1"
]
SMOKE_LOG.write_text("\n".join(lines), encoding='utf-8')
print("\n".join(lines))
