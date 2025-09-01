# REPO_STRUCTURE  Canonical Paths (flat)

## Правило
Усі артефакти зберігаємо у **плоских** канонічних шляхах. Каталоги `0115`  **лише навігаційні секції**, туди нічого не пишемо.

## Канонічні шляхи артефактів
- `universe/YYYY-MM-DD.csv`  (або .parquet)
- `factors.parquet`
- `alpha.parquet`
- `risk_model/beta.parquet`
- `risk_model/cov_YYYY-MM-DD.npz`
- `risk_model/scales.json`
- `targets/YYYY-MM-DD.csv`
- `orders_YYYY-MM-DD.parquet`  (або .csv)
- `performance.json`

## Навіщо
Єдині посилання в STATUS/QC, без дублювань на кшталт `02_universe/...` vs `universe/...`.
