# STATUS  2025-09-01

Canonical paths = flat, див. docs/REPO_STRUCTURE.md


## Gates (Roadmap)
1) Gate 1: Data & Universe  Ready, якщо: PIT, WEEKLY snapshot, TZ/дати вирівняні, 0 дублікатів, 0 ERROR. → **VERDICT:** PASS. Evidence: docs/QC_universe_2025-09-01.md
2) Gate 2: Factors & Alpha  Ready, якщо: 0 NaN; |ρ|<0.90; alpha IS-пороги SPEC; без leakage. → **VERDICT:** PASS. Evidence: docs/QC_factors_alpha_2025-09-01.md
3) Gate 3: Risk & Portfolio  Ready, якщо: risk_model валідний; |β|, σ в межах; targets узгоджені; OOS стабільний. → **VERDICT:** PASS. Evidence: docs/QC_risk_portfolio_2025-09-01.md

## 15 блоків (світлофор)
| # | Блок | Артефакт(и) | Ready, якщо | Status | Next step |
|---|------|-------------|--------------|--------|-----------|
| 1 | Data Ingest & Returns | data/ohlcv/*; data/returns/* | 0 дублікатів/NaN; інваріанти OHLC; outliers позначені | UNKNOWN | Створити data/returns/returns_2025-08-29.parquet (шаблон) |
| 2 | Universe (Weekly PIT Snapshot) | universe/2025-09-01.csv; docs/QC_universe_2025-09-01.md | N[500,1500]; weekly churn 15% | PASS | Розширити PIT-універсум 500 символів (weekly) |
| 3 | Factors — Compute | factors/2025-09-01.csv | формули/вікна коректні; без leakage | PASS | Додати unit-тести формул |
| 4 | Factors — Post (Std/Neutralize) | factors/2025-09-01.csv | 0 NaN; середня |ρ|<0.90; 0 ERROR | PASS | Додати звіт кореляцій ρ |
| 5 | Alpha Aggregation | alpha/2025-09-01.csv | SPEC-метод; IS-пороги досягнуті; без leakage | PASS | Додати IS-тест порогів |
| 6 | Risk  Beta (252d) | risk_model/beta.parquet | |β| у межах; індекси узгоджені | UNKNOWN | Обчислити risk_model/beta.parquet (252д OLS) |
| 7 | Risk  Covariance (Σ) & SPD | risk_model/cov_YYYY-MM-DD.npz; risk_model/scales.json | Σ PSD; стабільні скейли | UNKNOWN | Порахувати risk_model/cov_2025-08-29.npz (LedoitWolf) |
| 8 | Vol Targeting | targets/2025-09-01.csv; tools/ats_run.ps1 | σ_ex-ante в ±10% до σ_target | PASS | Підтягнути σ-оцінку до targets |
| 9 | Portfolio Construction (Q5/Q1 + Caps) | targets.parquet | капи/ліміти виконані; β_net0.05 | UNKNOWN | Згенерувати targets.parquet за 1 тиждень з β_net0.05 |
| 10 | Turnover & Liquidity Controls | targets.parquet (post-caps) | Turnover 2030%; ADV-ліміти ок | UNKNOWN | Звести churn/ADV звіт за тиждень на основі targets.parquet |
| 11 | Execution (Simulator) | orders/2025-09-01.csv; execution/fills_2025-09-01.csv; tools/ats_run.ps1 | 0 NaN/Inf; ADV-ліміти; 0 ERROR | PASS | Логувати fills щодня (cron) |
| 12 | Trading Costs (TC)  Ex-ante / Ex-post | orders_{date}.parquet | TC 1030% gross; fill 95% | UNKNOWN | Додати TC-оцінку до orders_* (ex-ante) |
| 13 | Monitoring & Reporting | performance.json | валідний JSON; дашборди згенеровані | UNKNOWN | Згенерувати performance.json (SR, IC, Vol, MDD) |
| 14 | Testing & Runbook | tools/ats_run.ps1 | наскрізний прогін 1 день без ERROR | PASS | Запустити 7-денний прогін |
| 15 | Governance & PR (SPEC/AC) | SPEC/AC/RUNBOOK/REPORT | PASS за AC; повний пакет; чейнджлог | UNKNOWN | Створити SPEC/AC за шаблоном docs/MODULE_CONTRACT_TEMPLATE.md |

**Легенда:** PASS = усі AC виконані; FAIL = поріг порушено; UNKNOWN = немає артефакту/верифікації.  
Орієнтири: |β_portfolio|0.05; σ_ex-ante в 10% до σ_target=10% ann.; Turnover 2030%; TC 1030% gross; fill-rate 95%; 0 ERROR.














