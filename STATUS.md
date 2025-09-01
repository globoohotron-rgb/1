# STATUS  2025-09-01

## Gates (Roadmap)
1) Gate 1: Data & Universe — Ready, якщо: PIT, WEEKLY snapshot, TZ/дати вирівняні, 0 дублікатів, 0 ERROR.  **VERDICT:** FAIL. Evidence: universe/2025-09-01.csv
2) Gate 2: Factors & Alpha  Ready, якщо: 0 NaN; |ρ|<0.90; alpha IS-пороги SPEC; без leakage.  **VERDICT:** UNKNOWN. Evidence: 03_factors_raw/, docs/MODULE_CONTRACT_TEMPLATE.md
3) Gate 3: Risk & Portfolio  Ready, якщо: risk_model валідний; |β|, σ в межах; targets узгоджені; OOS стабільний.  **VERDICT:** UNKNOWN. Evidence: targets/2025-09-01.csv

## 15 блоків (світлофор)
| # | Блок | Артефакт(и) | Ready, якщо | Status | Next step |
|---|------|-------------|--------------|--------|-----------|
| 1 | Data Ingest & Returns | data/ohlcv/*; data/returns/* | 0 дублікатів/NaN; інваріанти OHLC; outliers позначені | UNKNOWN | Створити data/returns/returns_2025-08-29.parquet (шаблон) |
| 2 | Universe (Weekly PIT Snapshot) | universe/2025-09-01.csv | N∈[500,1500]; weekly churn ≤15% | FAIL | Розширити PIT-універсум ≥500 символів (weekly) |
| 3 | Factors  Compute (price-only) | factors.parquet (raw) | формули/вікна коректні; без leakage | UNKNOWN | Обчислити factors.parquet (3 базові фактори) за 1 дату |
| 4 | Factors  Post (Clean & Standardize) | factors.parquet | 0 NaN; середня |ρ|<0.90; 0 ERROR | UNKNOWN | Додати std-колонки (_z) і перезаписати factors.parquet |
| 5 | Alpha  Composite & Rank | alpha.parquet | SPEC-агрегація; IS-пороги досягнуті; без leakage | UNKNOWN | Зібрати alpha.parquet (ранги/ваги) за 1 дату |
| 6 | Risk  Beta (252d) | risk_model/beta.parquet | |β| у межах; індекси узгоджені | UNKNOWN | Обчислити risk_model/beta.parquet (252д OLS) |
| 7 | Risk  Covariance (Σ) & SPD | risk_model/cov_YYYY-MM-DD.npz; risk_model/scales.json | Σ PSD; стабільні скейли | UNKNOWN | Порахувати risk_model/cov_2025-08-29.npz (LedoitWolf) |
| 8 | Vol-Targeting Scales | risk_model/scales.json; targets.parquet | σ_ex-ante в 10% до σ_target | UNKNOWN | Записати scales.json і додати σ_target у targets.parquet (1 тиждень) |
| 9 | Portfolio Construction (Q5/Q1 + Caps) | targets.parquet | капи/ліміти виконані; β_net0.05 | UNKNOWN | Згенерувати targets.parquet за 1 тиждень з β_net0.05 |
| 10 | Turnover & Liquidity Controls | targets.parquet (post-caps) | Turnover 2030%; ADV-ліміти ок | UNKNOWN | Звести churn/ADV звіт за тиждень на основі targets.parquet |
| 11 | Execution (Simulator) | orders/2025-09-01.csv; execution/fills_2025-09-01.csv | 0 NaN/Inf; ADV-ліміти; 0 ERROR | PASS | Логувати fills щодня (cron) |
| 12 | Trading Costs (TC)  Ex-ante / Ex-post | orders_{date}.parquet | TC 1030% gross; fill 95% | UNKNOWN | Додати TC-оцінку до orders_* (ex-ante) |
| 13 | Monitoring & Reporting | performance.json | валідний JSON; дашборди згенеровані | UNKNOWN | Згенерувати performance.json (SR, IC, Vol, MDD) |
| 14 | Testing & Runbook | тести; логи; чек-листи | 0 ERROR; наскрізний прогін 60 роб.днів | UNKNOWN | Запустити sanity E2E на 60 роб.днів і зберегти логи |
| 15 | Governance & PR (SPEC/AC) | SPEC/AC/RUNBOOK/REPORT | PASS за AC; повний пакет; чейнджлог | UNKNOWN | Створити SPEC/AC за шаблоном docs/MODULE_CONTRACT_TEMPLATE.md |

**Легенда:** PASS = усі AC виконані; FAIL = поріг порушено; UNKNOWN = немає артефакту/верифікації.  
Орієнтири: |β_portfolio|0.05; σ_ex-ante в 10% до σ_target=10% ann.; Turnover 2030%; TC 1030% gross; fill-rate 95%; 0 ERROR.





