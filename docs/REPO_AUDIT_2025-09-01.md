# REPO_AUDIT — 2025-09-01

Rule: **KEEP** = canonical flat paths або прямі посилання в STATUS/MILESTONE/PLAN; у секціях 01–15 — лише README.md/.gitkeep. **DELETE** = дублікати/невикористане. _Жодних видалень не виконано._

Summary: total items = 67; KEEP = 64; DELETE = 3.

## Objects
| Path | Type | Decision | Reason |
|---|---|---|---|
| 01_data | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 01_data/.gitkeep | file | KEEP | navigation only |
| 02_universe | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 02_universe/.gitkeep | file | KEEP | navigation only |
| 03_factors_raw | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 03_factors_raw/.gitkeep | file | KEEP | navigation only |
| 04_factors_std | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 04_factors_std/.gitkeep | file | KEEP | navigation only |
| 05_alpha | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 05_alpha/.gitkeep | file | KEEP | navigation only |
| 06_risk_beta | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 06_risk_beta/.gitkeep | file | KEEP | navigation only |
| 07_risk_cov | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 07_risk_cov/.gitkeep | file | KEEP | navigation only |
| 08_vol_targeting | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 08_vol_targeting/.gitkeep | file | KEEP | navigation only |
| 09_portfolio | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 09_portfolio/.gitkeep | file | KEEP | navigation only |
| 10_turnover_liquidity | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 10_turnover_liquidity/.gitkeep | file | KEEP | navigation only |
| 11_execution | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 11_execution/.gitkeep | file | KEEP | navigation only |
| 12_trading_costs | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 12_trading_costs/.gitkeep | file | KEEP | navigation only |
| 13_monitoring | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 13_monitoring/.gitkeep | file | KEEP | navigation only |
| 14_testing_runbook | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 14_testing_runbook/.gitkeep | file | KEEP | navigation only |
| 15_governance_pr | dir | KEEP | navigation section (README.md, .gitkeep only) |
| 15_governance_pr/.gitkeep | file | KEEP | navigation only |
| alpha | dir | KEEP | canonical root |
| alpha/2025-09-01.csv | file | KEEP | canonical artifact |
| docs | dir | KEEP | canonical root |
| docs/AI_ACCESS_CHECK.md | file | KEEP | canonical artifact |
| docs/CODEMAP.md | file | KEEP | canonical artifact |
| docs/docs | dir | KEEP | canonical root |
| docs/PLAN_SUMMARY.md | file | KEEP | canonical artifact |
| docs/px.parquet | file | KEEP | canonical artifact |
| docs/QC_factors_alpha_2025-09-01.md | file | KEEP | canonical artifact |
| docs/QC_universe_2025-09-01.md | file | KEEP | canonical artifact |
| docs/REPO_AUDIT_2025-09-01.md | file | KEEP | canonical artifact |
| docs/REPO_STRUCTURE.md | file | KEEP | canonical artifact |
| docs/SYNC_MISSING.md | file | KEEP | canonical artifact |
| execution | dir | KEEP | canonical root |
| execution/fills_2025-09-01.csv | file | KEEP | canonical artifact |
| factors | dir | KEEP | canonical root |
| factors/2025-08-29.parquet | file | KEEP | canonical artifact |
| factors/2025-09-01.csv | file | KEEP | canonical artifact |
| github | dir | DELETE | non-canonical & no references |
| github/workflows | dir | DELETE | non-canonical & no references |
| github/workflows/ci.yml | file | DELETE | non-canonical & no references |
| MILESTONE_2025-09-01.md | file | KEEP | repo meta |
| orders | dir | KEEP | canonical root |
| orders/2025-09-01.csv | file | KEEP | canonical artifact |
| pyproject.toml | file | KEEP | repo meta |
| README.md | file | KEEP | repo meta |
| requirements.txt | file | KEEP | repo meta |
| risk_model | dir | KEEP | canonical root |
| STATUS.md | file | KEEP | repo meta |
| targets | dir | KEEP | canonical root |
| targets/2025-09-01.csv | file | KEEP | canonical artifact |
| tools | dir | KEEP | dev tooling/CI |
| tools/git_autosync.ps1 | file | KEEP | dev tooling/CI |
| universe | dir | KEEP | canonical root |
| universe/2025-08-22.parquet | file | KEEP | canonical artifact |
| universe/2025-08-29.parquet | file | KEEP | canonical artifact |
| universe/2025-09-01.csv | file | KEEP | canonical artifact |
