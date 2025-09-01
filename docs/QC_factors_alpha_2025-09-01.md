# QC  Factors & Alpha 2025-09-01

Sources: actors/2025-09-01.csv, lpha/2025-09-01.csv

Checks:
- NaN check → factors NaN = **0**, alpha NaN = **0**  **PASS**
- size_z moments  mean = **0,000000**, std = **999 999,910610** (tolerance 1e-3) → **FAIL**
- leakage (alpha == size_z on t)  **PASS**
