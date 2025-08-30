import pandas as pd, pathlib, os
os.chdir(pathlib.Path(__file__).resolve().parents[1])
d='2025-08-29'; U,F,L='02_universe','03_factors_raw','13_monitoring'
u=pd.read_parquet(f'{U}/{d}.parquet'); f=pd.read_parquet(f'{F}/{d}.parquet')
assert set(f.columns)=={'date','symbol','MOM_252x21','VOL_21','REV_1D','LIQ_ADV21'}
assert set(f['symbol'])==set(u['symbol']) and len(f)==len(u)==1000
assert f.isna().sum().sum()==0 and f[['MOM_252x21','VOL_21','REV_1D','LIQ_ADV21']].var().min()>0
print(open(f'{L}/universe_{d}.log').read().strip()); print(open(f'{L}/factors_{d}.log').read().strip()); print('PASS')
