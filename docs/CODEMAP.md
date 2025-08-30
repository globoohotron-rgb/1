# CODEMAP — ATS v0 (2025-08-29)

Коротка карта коду та артефактів. Лінки — відносні; у GitHub відкриються й підсвітять рядки.

## Структура
- `01_data/` — сирі дані (`px.parquet`)
- `02_universe/` — щотижневий універсум (`YYYY-MM-DD.parquet`)
- `03_factors_raw/` — фактори v0 (`YYYY-MM-DD.parquet`)
- `13_monitoring/` — логи прийомки
- `14_testing_runbook/` — QC-скрипти
- `docs/` — документація (цей файл)

## Точки входу
- Universe builder → [`02_universe/build_universe.py`](../02_universe/build_universe.py)  
  читання даних: [L5](../02_universe/build_universe.py#L5) · фільтр+топ+запис: [L6–L7](../02_universe/build_universe.py#L6-L7) · churn≤15%: [L9](../02_universe/build_universe.py#L9)
- Factors v0 → [`03_factors_raw/build_factors.py`](../03_factors_raw/build_factors.py)  
  підготовка: [L5–L6](../03_factors_raw/build_factors.py#L5-L6) · обчислення: [L7](../03_factors_raw/build_factors.py#L7) · вибір на дату: [L8](../03_factors_raw/build_factors.py#L8) · no-NaN fallback: [L9](../03_factors_raw/build_factors.py#L9)
- QC пакет → [`14_testing_runbook/qc_all.py`](../14_testing_runbook/qc_all.py)  
  перевірки: [L5–L7](../14_testing_runbook/qc_all.py#L5-L7)

## Контракти I/O
**Universe**: in `01_data/px.parquet (date,symbol,AdjC,ADV21)` → out `02_universe/YYYY-MM-DD.parquet (symbol)` · лог `13_monitoring/universe_YYYY-MM-DD.log`.  
**Factors v0**: in `01_data/px.parquet` + `02_universe/...` → out `03_factors_raw/YYYY-MM-DD.parquet (date,symbol,MOM_252x21,VOL_21,REV_1D,LIQ_ADV21)` · лог `13_monitoring/factors_YYYY-MM-DD.log`.  
**QC**: друк `PASS`, у логах немає `ERROR`.

## Залежності
Python ≥3.11 · пакети: `pandas`, `numpy`, `pyarrow` (див. [`requirements.txt`](../requirements.txt)).

## Як запустити локально
```bash
python 02_universe/build_universe.py
python 03_factors_raw/build_factors.py
python 14_testing_runbook/qc_all.py

> Note: CI builds fixture data and runs ruff; PR must be green.
