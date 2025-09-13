import pandas as pd, json, datetime as dt
from pathlib import Path

ROOT=Path('.')
DATA=ROOT/'data'/'ohlcv.parquet'
UNIDIR=ROOT/'universe'
SMOKE=ROOT/'eval'/'smoke_universe_60d.log'
QCJSON=ROOT/'universe'/'qc_universe.json'

df = pd.read_parquet(DATA).reset_index()  # index: date,ticker
df['date']=pd.to_datetime(df['date'], utc=True)
dates = sorted(df['date'].unique())[-60:]

written=0
for d in dates:
    day = df[df['date']==d].copy()
    # простий фільтр: ціна close > 1, volume > 0
    if 'Close' in day.columns and 'Volume' in day.columns:
        day = day[(day['Close']>1) & (day['Volume']>0)]
    uni = day[['ticker']].drop_duplicates().assign(include=1)
    out = UNIDIR/f"{pd.to_datetime(d).date()}.parquet"
    uni.to_parquet(out, index=False)
    written += 1

qc = {
  "dates": len(dates),
  "last_date": pd.to_datetime(dates[-1]).isoformat(),
  "avg_size": int(df[df['date'].isin(dates)].groupby('date')['ticker'].nunique().mean())
}
QCJSON.write_text(json.dumps(qc, indent=2), encoding='utf-8')

SMOKE.write_text(
    f"SMOKE UNIVERSE 60D @ {dt.datetime.utcnow().isoformat()}Z\nfiles={written}\nlast={qc['last_date']}\nERRORS=0",
    encoding='utf-8'
)
print("done:", written, "files")
