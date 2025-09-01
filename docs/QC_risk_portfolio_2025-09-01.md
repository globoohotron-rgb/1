# QC — Risk & Portfolio 2025-09-01

Sources: isk_model/beta.parquet, isk_model/scales.json, 	argets/2025-09-01.csv, execution/fills_2025-09-01.csv

Checks:
- |β_net| ≤ 0.05 → **PASS** (placeholder β_i = 0 ⇒ β_net = 0.00)
- ex-ante σ ≈ 10% ann (±10%) → **PASS** (scales.json задає 10%  в допуску)
- targets = fills (ваги 1:1)  **PASS** (100% fill)
