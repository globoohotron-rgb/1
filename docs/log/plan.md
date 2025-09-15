# План v3.0 — Engineering Ledger (final)

| date(ISO) | type | section | id | summary | depends_on | artifacts | acceptance_keypoints | status | evidence | commit |
|---|---|---|---|---|---|---|---|---|---|---|
|  | MILESTONE | Global | MS1 | Skeleton ready | INF-05, INF-06 |  | CI/Make/Secrets готові | todo |  |  |
|  | MILESTONE | Global | MS2 | Data ingested + QC | DATA-05 |  | ingest+QC 60d OK | todo |  |  |
|  | MILESTONE | Global | MS3 | Research E2E smoke 60d | UNI-04, FAC-06, ALP-04, RSK-06, PRF-05 |  | 0 ERROR | todo |  |  |
|  | MILESTONE | Global | MS4 | Backtest 3–5y reproducible | PIPE-08 |  | доки+скрипти відтворні | todo |  |  |
|  | MILESTONE | Global | MS5 | MVP + Telegram signals | SIG-04, MON-05, PIPE-10 |  | сигнали доставляються | todo |  |  |
|  | MILESTONE | Global | MS6 | Paper/live readiness | LIVE-05 |  | пройдені go-live гейти | todo |  |  |
|  | TASK | INF | INF-01 | Каркас репозиторію | — | src/*, notebooks, docs/adr, eval | структура + README-мапа | done |  |  |
|  | TASK | INF | INF-02 | Єдиний конфіг defaults | INF-01 | config/defaults | усі модулі читають один loader | todo |  |  |
|  | TASK | INF | INF-03 | pre-commit (lint/format/type) | INF-01 | .pre-commit, конфіги | pre-commit ok; CI блокує без формату | todo |  |  |
|  | TASK | INF | INF-04 | CI/CD (lint, tests, smoke) | INF-03 | .github/workflows/ci.yml | jobs зелені; smoke артефакти | in_progress |  |  |
|  | TASK | INF | INF-05 | Make/CLI таргети | INF-02 | Makefile | `make help` повний; таргети проходять | todo |  |  |
|  | TASK | INF | INF-06 | Секрети і доступи | INF-01 | .env.template, ADR | секретів у git немає; onboarding <15 хв | todo |  |  |
| 2025-09-13T12:40:00Z | TASK | DATA | DATA-01 | Інгест OHLCV/AdjClose (UTC) | INF-05 | data/ohlcv.parquet | фільтри ок; TZ=UTC | done | data/ohlcv.parquet |  |
| 2025-09-13T12:40:00Z | TASK | DATA | DATA-02 | QC-звіт даних | DATA-01 | data/qc_report.json, plots | пороги спрацювань задані | done | data/qc_report.json |  |
| 2025-09-13T12:40:00Z | TASK | DATA | DATA-03 | Acceptance даних | DATA-02 | data/acceptance.json | ≥95% валідних; дублікати=0 | done | data/acceptance.json |  |
|  | TASK | DATA | DATA-04 | Маніфест сетів | DATA-01 | data/manifest.json | датовані джерела/хеші | todo |  |  |
| 2025-09-13T12:40:00Z | TASK | DATA | DATA-05 | Smoke ingest 60d | DATA-03, DATA-04 | eval/smoke_data_60d.log | 0 ERROR; пороги не порушені | done | eval/smoke_data_60d.log |  |
|  | TASK | UNI | UNI-01 | Логіка universe + фільтри | DATA-05 | src/universe/build.py | параметри з конфіга; детермінований | todo |  |  |
|  | TASK | UNI | UNI-02 | Збереження universe по датах | UNI-01 | universe/DATE.parquet | будується для будь-якої дати | todo |  |  |
|  | TASK | UNI | UNI-03 | Контролі N і churn | UNI-02 | universe/qc_universe.json | N∈[500,1500], churn≤15% d/d | todo |  |  |
|  | TASK | UNI | UNI-04 | Smoke universe 60d | UNI-03 | eval/smoke_universe_60d.log | 0 ERROR | todo |  |  |
|  | TASK | FAC | FAC-01 | Momentum | UNI-02 | factors/momentum.parquet | winsorize→zscore; non-null≥99% | todo |  |  |
|  | TASK | FAC | FAC-02 | Reversal | UNI-02 | factors/reversal.parquet | winsorize→zscore; \|z\|≤5 | todo |  |  |
|  | TASK | FAC | FAC-03 | LowVol | UNI-02 | factors/lowvol.parquet | heatmap ρ; non-null≥99% | todo |  |  |
|  | TASK | FAC | FAC-04 | Зведення факторів | FAC-01..03 | factors/factors.parquet | єдині індекси (date,ticker) | todo |  |  |
|  | TASK | FAC | FAC-05 | QC-пакет факторів | FAC-04 | factors/qc_factors.json | fail при порушеннях | todo |  |  |
|  | TASK | FAC | FAC-06 | Smoke factors 60d | FAC-05 | eval/smoke_factors_60d.log | 0 ERROR | todo |  |  |
|  | TASK | ALP | ALP-01 | Комбінація факторів у алфу | FAC-04 | alpha/alpha.parquet | кореляції в (0,0.99); стабільні ранги | todo |  |  |
|  | TASK | ALP | ALP-02 | Ваги через конфіг + ADR | INF-02, ALP-01 | ADR рішення | зафіксовано; відтворювано | todo |  |  |
|  | TASK | ALP | ALP-03 | QC алфи | ALP-01 | alpha/qc_alpha.json | авто-fail аномалій | todo |  |  |
|  | TASK | ALP | ALP-04 | Smoke alpha 60d | ALP-03 | eval/smoke_alpha_60d.log | 0 ERROR | todo |  |  |
|  | TASK | RSK | RSK-01 | Бета (252d OLS) | UNI-02, DATA-01 | risk_model/beta.parquet | щоденне оновлення; NaN≤1% | todo |  |  |
|  | TASK | RSK | RSK-02 | Коваріації Σ (LW) | DATA-01 | risk_model/cov_lw.npz | Σ PD; стійкість до шуму | todo |  |  |
|  | TASK | RSK | RSK-03 | Vol-targeting/масштаби | RSK-01, RSK-02 | risk_model/scales.json | цільова σ у бектесті ±10% | todo |  |  |
|  | TASK | RSK | RSK-04 | QC ризику | RSK-01, RSK-02 | risk_model/qc_risk.json | fail на аномаліях; спектр Σ | todo |  |  |
|  | TASK | RSK | RSK-05 | Маніфест RM | RSK-03 | risk_model/manifest.json | версія+дата релізу | todo |  |  |
|  | TASK | RSK | RSK-06 | Smoke risk 60d | RSK-04 | eval/smoke_risk_60d.log | 0 ERROR | todo |  |  |
|  | TASK | PRF | PRF-01 | Цільові ваги + обмеження | ALP-01, RSK-03 | portfolio/targets.parquet | валідація обмежень; відтворюваність | todo |  |  |
|  | TASK | PRF | PRF-02 | Контроль оборотності | PRF-01 | portfolio/qc_turnover.json | оборотність ≤ порога | todo |  |  |
|  | TASK | PRF | PRF-03 | Backtest 3–5 років | PRF-01, RSK-03 | eval/backtest_summary.json | відтворний на іншій машині | todo |  |  |
|  | TASK | PRF | PRF-04 | Маніфест портфеля | PRF-01 | portfolio/manifest.json | зафіксовані дати/хеші | todo |  |  |
|  | TASK | PRF | PRF-05 | Smoke portfolio 60d | PRF-02 | eval/smoke_portfolio_60d.log | 0 ERROR | todo |  |  |
|  | TASK | EXE | EXE-01 | Ордери з лімітами ADV | PRF-01 | execution/orders_DATE.parquet | сумісний формат; ADV дотримані | todo |  |  |
|  | TASK | EXE | EXE-02 | Stub TC-модель | EXE-01 | execution/tc_stub.json | TC враховано в PnL | todo |  |  |
|  | TASK | EXE | EXE-03 | Емулятор виконання | EXE-02 | eval/execution_sim.json | стабільний при повторі | todo |  |  |
|  | TASK | EXE | EXE-04 | Smoke execution 60d | EXE-01 | eval/smoke_execution_60d.log | 0 ERROR | todo |  |  |
|  | TASK | SIG | SIG-01 | Схема сигналу | PRF-01 | spec полів сигналу | non-null≥99%; RR≥1.5 | todo |  |  |
|  | TASK | SIG | SIG-02 | Генератор рівнів (entry/SL/TP) | PRF-01, RSK-03 | signals/DATE.(parquet\|json) | детермінованість; ATR/vol правила | todo |  |  |
|  | TASK | SIG | SIG-03 | Рендер карток/тексту | SIG-02 | текст/PNG картки | 50 тикерів <2 c | todo |  |  |
|  | TASK | SIG | SIG-04 | Telegram-бот (доставка) | INF-06, SIG-03 | повідомлення у чаті | <2 c; ретраї 429; лог відправок | todo |  |  |
|  | TASK | SIG | SIG-05 | QC повідомлень | SIG-04 | monitoring/alerts.json | 0 втрат; алерт на фейл | todo |  |  |
|  | TASK | MON | MON-01 | Стандартизоване логування | INF-04 | logs/*.log | рівні узгоджені; WARNING рахуються | todo |  |  |
|  | TASK | MON | MON-02 | performance.json | PRF-03, EXE-03 | monitoring/performance.json | ключові метрики валідні | todo |  |  |
|  | TASK | MON | MON-03 | HTML/PNG звіт | MON-02 | report.html, plots | одна команда генерує | todo |  |  |
|  | TASK | MON | MON-04 | Алерти QC/порогів | DATA-03, UNI-03, FAC-05, RSK-04, PRF-02 | alerts.json/Slack/TG | тригер при порушеннях | todo |  |  |
|  | TASK | MON | MON-05 | Smoke моніторингу 60d | MON-03 | eval/smoke_monitoring_60d.log | 0 ERROR | todo |  |  |
|  | TASK | LIVE | LIVE-01 | Абстракція брокера | EXE-01 | інтерфейс send/cancel/positions | ідемпотентність; dry-run | todo |  |  |
|  | TASK | LIVE | LIVE-02 | Paper-trading bridge | LIVE-01 | execution/fills.parquet | розбіжність з EOD ≤ X% | todo |  |  |
|  | TASK | LIVE | LIVE-03 | Pre-trade guardrails | LIVE-01 | правила/календарі/kill-switch | блок з журналом причин | todo |  |  |
|  | TASK | LIVE | LIVE-04 | Планувальник і SLA | INF-02 | добовий EOD графік | SLA/алерти просрочок | todo |  |  |
|  | TASK | LIVE | LIVE-05 | Go-live гейти | PRF-03, MON-02, SIG-04, LIVE-02 | політика переходу | BT: Sharpe≥1.0; Calmar≥0.5; DD≤15%; Paper 4–6w | todo |  |  |
|  | TASK | LIVE | LIVE-06 | Secrets/Compliance | INF-06 | політика ротації | секретів у git немає; ротація ок | todo |  |  |
|  | TASK | PIPE | PIPE-01 | Acceptance Matrix | INF-02 | docs/acceptance_matrix.yaml | QC-скрипти читають матрицю | todo |  |  |
|  | TASK | PIPE | PIPE-02 | Юніт-тести (критичне) | INF-04 | tests/* | coverage ≥60% на криті | todo |  |  |
|  | TASK | PIPE | PIPE-03 | E2E smoke 60d | DATA-05, UNI-04, FAC-06, ALP-04, RSK-06, PRF-05, EXE-04, MON-05, SIG-05 | eval/smoke_e2e_60d.log | 0 ERROR; час ≤ конфіг | todo |  |  |
|  | TASK | PIPE | PIPE-04 | Версіонування артефактів | DATA-04, RSK-05, PRF-04 | */manifest.json | writer-и оновлюють автоматично | todo |  |  |
|  | TASK | PIPE | PIPE-05 | Shadow-режим v2 | INF-02 | config flags, v2/* | паралельний запуск v1/v2 | todo |  |  |
|  | TASK | PIPE | PIPE-06 | PR чек-лист | INF-04 | docs/pr_checklist.md | кожен PR має чек-лист | todo |  |  |
|  | TASK | PIPE | PIPE-07 | Backtest 3–5y (make backtest) | PRF-03, EXE-03 | eval/backtest_3to5y.json | відтворний на чистому оточенні | todo |  |  |
|  | TASK | PIPE | PIPE-08 | Документація користувача | PIPE-07 | README, quickstart, pipeline.svg | онбординг <30 хв | todo |  |  |
|  | TASK | PIPE | PIPE-09 | Реліз MVP | PIPE-08 | tag v0.1.0, release notes | DoD досягнуто | todo |  |  |
|  | TASK | PIPE | PIPE-10 | Операційний плейбук | PIPE-09 | docs/runbook.md | ролі, відновлення, щоденний чек-лист | todo |  |  |
