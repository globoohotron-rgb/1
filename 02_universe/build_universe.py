import pandas as pd, os, pathlib
os.chdir(pathlib.Path(__file__).resolve().parents[1])
d='2025-08-29'; prev='2025-08-22'; B1,B2,L='01_data','02_universe','13_monitoring'
pathlib.Path(B2).mkdir(exist_ok=True); pathlib.Path(L).mkdir(exist_ok=True)
px=pd.read_parquet(f'{B1}/px.parquet')
u=(px.query('date==@d and AdjC>=5').dropna(subset=['AdjC','ADV21']).sort_values('ADV21',ascending=False).head(1500))[['symbol']]
assert len(u)>=500; u.to_parquet(f'{B2}/{d}.parquet', index=False)
churn=0; p=f'{B2}/{prev}.parquet'
if os.path.exists(p): P=set(pd.read_parquet(p)['symbol']); T=set(u['symbol']); churn=1-len(P&T)/len(P|T); assert churn<=0.15
open(f'{L}/universe_{d}.log','w').write(f'INFO N={len(u)} churn={churn:.2%} status=PASS\n'); print('OK')
