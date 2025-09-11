# AI Access Check  Copilot Workspace Index

Дата: 2025-08-30 11:37
Репозиторій: https://github.com/globoohotron-rgb/1

## 1) Universe (очікуваний файл і рядки)

Файл: 02_universe/build_universe.py  
Лінки:  

- читання/фільтр/запис: [https://github.com/globoohotron-rgb/1/blob/main/02_universe/build_universe.py#L5-L9](https://github.com/globoohotron-rgb/1/blob/main/02_universe/build_universe.py#L5-L9)

Відповідь Copilot (цитата):
> px=pd.read_parquet(f'{B1}/px.parquet')

u=(px.query('date==@d and AdjC>=5').dropna(subset=['AdjC','ADV21']).sort_values('ADV21',ascending=False).head(1500))[['symbol']]
assert len(u)>=500; u.to_parquet(f'{B2}/{d}.parquet', index=False)

## 2) Factors v0 (очікуваний файл і рядки)

Файл: 03_factors_raw/build_factors.py  

Лінки:  

- обчислення факторів: [https://github.com/globoohotron-rgb/1/blob/main/03_factors_raw/build_factors.py#L7-L10](https://github.com/globoohotron-rgb/1/blob/main/03_factors_raw/build_factors.py#L7-L10)
- вибір на дату/вирівнювання: [https://github.com/globoohotron-rgb/1/blob/main/03_factors_raw/build_factors.py#L8-L10](https://github.com/globoohotron-rgb/1/blob/main/03_factors_raw/build_factors.py#L8-L10)

Відповідь Copilot (цитата):
> px['VOL_21']=g['ret'].rolling(21).std().reset_index(level=0,drop=True); px['MOM_252x21']=g['AdjC'].apply(lambda s: s.shift(21)/s.shift(252)-1).reset_index(level=0,drop=True); px['REV_1D']=-px['ret']; px['LIQ_ADV21']=np.log(px['ADV21'])

f=px[px.date==d][['date','symbol','MOM_252x21','VOL_21','REV_1D','LIQ_ADV21']].set_index('symbol').reindex(u).reset_index()

## 3) QC (очікуваний файл і рядки)

Файл: 14_testing_runbook/qc_all.py  
Лінки:  

- перевірки колонок/універсума/NaN/варіацій: [https://github.com/globoohotron-rgb/1/blob/main/14_testing_runbook/qc_all.py#L5-L7](https://github.com/globoohotron-rgb/1/blob/main/14_testing_runbook/qc_all.py#L5-L7)

Відповідь Copilot (цитата):
> assert set(f.columns)=={'date','symbol','MOM_252x21','VOL_21','REV_1D','LIQ_ADV21'}

assert set(f['symbol'])==set(u['symbol']) and len(f)==len(u)==1000

assert f.isna().sum().sum()==0 and f[['MOM_252x21','VOL_21','REV_1D','LIQ_ADV21']].var().min()>0

---

## Результат
- [x] Усі посилання вище відкриваються у браузері без 404  
- [x] Кожна відповідь Copilot містить цитати з правильних файлів  
- [x] Немає фрази I dont have access  
**STATUS:** PASS
