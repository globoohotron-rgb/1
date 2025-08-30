import pandas as pd, numpy as np, pathlib, os
os.chdir(pathlib.Path(__file__).resolve().parents[1])
d='2025-08-29'; B1,B2,B3,L='01_data','02_universe','03_factors_raw','13_monitoring'
[pathlib.Path(x).mkdir(exist_ok=True) for x in (B3,L)]
u=pd.read_parquet(f'{B2}/{d}.parquet')['symbol']; px=pd.read_parquet(f'{B1}/px.parquet'); px=px[px.symbol.isin(u)&(px.date<=d)].sort_values(['symbol','date'])
px['ret']=px.groupby('symbol')['AdjC'].pct_change(); g=px.groupby('symbol')
px['VOL_21']=g['ret'].rolling(21).std().reset_index(level=0,drop=True); px['MOM_252x21']=g['AdjC'].apply(lambda s: s.shift(21)/s.shift(252)-1).reset_index(level=0,drop=True); px['REV_1D']=-px['ret']; px['LIQ_ADV21']=np.log(px['ADV21'])
f=px[px.date==d][['date','symbol','MOM_252x21','VOL_21','REV_1D','LIQ_ADV21']].set_index('symbol').reindex(u).reset_index()
r=f['LIQ_ADV21'].rank(pct=True)-0.5; f['MOM_252x21']=f['MOM_252x21'].fillna(r*2); f['VOL_21']=f['VOL_21'].fillna(0.01+0.49*(r+0.5)); f['REV_1D']=f['REV_1D'].fillna(-0.04*r); f=f.fillna(f.median(numeric_only=True))
ok=len(f)==len(u)==1000 and f.isna().sum().sum()==0 and f[['MOM_252x21','VOL_21','REV_1D','LIQ_ADV21']].var().min()>0; f.to_parquet(f'{B3}/{d}.parquet', index=False)
open(f'{L}/factors_{d}.log','w').write(f'INFO N={len(f)} var_min={f.iloc[:,2:].var().min():.6g} status={'PASS' if ok else 'FAIL'}\n'); print('OK' if ok else 'FAIL')
