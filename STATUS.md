*** Begin Patch
*** Add File: STATUS.md
+# STATUS — 2025-09-01
+
+## Gates (Roadmap)
+1) Gate 1: Data & Universe — Ready, якщо: PIT, WEEKLY snapshot, TZ/дати вирівняні, 0 дублікатів, 0 ERROR. → **VERDICT:** UNKNOWN. Evidence: —
+2) Gate 2: Factors & Alpha — Ready, якщо: 0 NaN; |ρ|<0.90; alpha IS-пороги SPEC; без leakage. → **VERDICT:** UNKNOWN. Evidence: —
+3) Gate 3: Risk & Portfolio — Ready, якщо: risk_model валідний; |β|, σ в межах; targets узгоджені; OOS стабільний. → **VERDICT:** UNKNOWN. Evidence: —
+
+## 15 блоків (світлофор)
+| # | Блок | Артефакт(и) | Ready, якщо… | Status | Next step |
+|---|------|-------------|--------------|--------|-----------|
+| 1 | Data Ingest & Returns | data/ohlcv/*, data/returns/* | 0 дублікатів/NaN; інваріанти OHLС; outliers позначені | UNKNOWN | Зібрати daily QC-звіт за 60 днів |
+| 2 | Universe (Weekly PIT Snapshot) | universe/YYYY-MM-DD.parquet | N∈[500,1500]; weekly churn ≤15% | UNKNOWN | Зібрати перший WEEKLY snapshot |
+| 3 | Factors — Compute | factors.parquet (raw→clean) | формули/вікна коректні; без leakage | UNKNOWN | Додати unit-тести формул |
+| 4 | Factors — Post (Std/Neutralize) | factors.parquet | 0 NaN; середня |ρ|<0.90; 0 ERROR | UNKNOWN | Згенерувати factors.parquet (std) |
+| 5 | Alpha Aggregation | alpha.parquet | SPEC-метод; IS-пороги досягнуті; без leakage | UNKNOWN | Зібрати alpha.parquet за 1 дату |
+| 6 | Risk — Beta | risk_model/beta.parquet | |β| в межах; індекси узгоджені | UNKNOWN | Обчислити beta.parquet (252д) |
+| 7 | Risk — Covariance (Σ) | risk_model/cov_{date}.npz, risk_model/scales.json | Σ PSD; стабільні скейли | UNKNOWN | Порахувати cov_{date}.npz (LW) |
+| 8 | Vol Targeting | targets.parquet | σ_ex-ante в ±10% до σ_target | UNKNOWN | Додати σ-таргет у targets.parquet |
+| 9 | Portfolio (Optimization) | targets.parquet | виконані капи/ліміти; β_net≤0.05 | UNKNOWN | Згенерувати targets.parquet за 1 тиждень |
+| 10 | Turnover & Liquidity | targets.parquet | Turnover 20–30%; ADV-ліміти ок | UNKNOWN | Звести churn/ADV звіт за тиждень |
+| 11 | Execution (Simulator) | orders_{date}.parquet | 0 NaN/Inf; ADV-ліміти; 0 ERROR | UNKNOWN | Згенерувати orders_{date}.parquet (1 день) |
+| 12 | Trading Costs | orders_{date}.parquet | TC 10–30% gross; fill ≥95% | UNKNOWN | Додати TC-оцінку до orders_* |
+| 13 | Monitoring & Reports | performance.json | валідний JSON; дашборди згенеровані | UNKNOWN | Згенерувати performance.json |
+| 14 | Testing & Runbook | тести, логи, чек-листи | 0 ERROR; наскрізний прогін 60 роб.днів | UNKNOWN | Запустити саніті-бек-тест на 60д |
+| 15 | Governance & PR (SPEC/AC) | SPEC/AC/RUNBOOK/REPORT | PASS за AC; повний пакет; чейнджлог | UNKNOWN | Створити SPEC/AC за шаблоном |
+
+**Легенда:** PASS = усі AC виконані; FAIL = поріг порушено; UNKNOWN = немає артефакту/верифікації.  
+Орієнтирні пороги: |β_portfolio|≤0.05; σ_ex-ante в ±10% до σ_target=10% ann.; Turnover 20–30%; TC 10–30% gross; fill-rate ≥95%; 0 ERROR.
+
*** End Patch
