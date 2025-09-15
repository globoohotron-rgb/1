# E2E ATS — Repo Skeleton (INF-01)

This repository hosts an end-to-end ATS pipeline: **data → signals → Telegram → gate to paper/live**. The skeleton keeps layers decoupled and traceable so that configuration (INF-02), tooling/CLI (INF-05), secrets/onboarding (INF-06) and DATA-* can be plugged in quickly.

## Architecture map
- **src/connectors** — IO adapters (exchanges/brokers/storage/Telegram) behind clean interfaces.
- **src/data** — ingestion & raw/processed datasets management.
- **src/universe** — universe selection, membership rules, churn/coverage controls.
- **src/factors** — feature engineering: momentum/reversal/vol etc.
- **src/alpha** — alpha aggregation, weighting, thresholds and dead-zones.
- **src/risk_model** — betas, covariances, scaling/vol targeting.
- **src/portfolio** — position sizing with limits (w_max, sectors, net, turnover).
- **src/execution** — order generation/routing, ADV limits, TC stubs.
- **src/signals** — packaging & dispatch of trade ideas to Telegram.
- **src/monitoring** — metrics, health checks, performance reports.
- **config & live** — configuration files; live runspace & operational artifacts.
- **docs/adr, eval, notebooks, tests** — architecture decisions, evaluation, research, and unit/smoke tests.

