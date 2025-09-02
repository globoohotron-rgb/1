# SPEC_ATS.md  ATS CLI Contract

Цей документ фіксує публічний контракт CLI **ats**: перелік підкоманд, їхній I/O (які файли читають/пишуть) та очікуваний консольний вивід. Будь-які зміни мають залишатися в межах цього інтерфейсу.

## Команди та I/O

| Command | Призначення | Читає (input) | Пише/оновлює (output) | Консольний вивід (шаблон) |
|---|---|---|---|---|
| `ats run --date D` | Зібрати артефакти дня (MVP) | (опц.) `targets/D.csv` | `targets/D.csv` *(створює, якщо немає)*; `orders/D.csv`; `execution/D.csv` | ` Run D: targets/orders/execution ready` |
| `ats perf --date D` | Порахувати денний gross return | `targets/D.csv`; `returns/(D+1).csv` | `performance/D.json` з `{date,gross_return}` | ` Perf D: r=...` |
| `ats daily --date D` | Один щоденний прохід: run  perf  equity | як вище + (опц.) `performance/equity.csv` | `targets/`; `orders/`; `execution/`; `performance/D.json`; `performance/equity.csv`; `docs/equity.png` | ` Run D: ...` і ` Daily D: weights OK; r=...` |
| `ats backfill --from F --to T` | Запустити `daily` для кожного дня з `[F..T]` | відповідні `returns/(d+1).csv` | `performance/<d>.json`; кумулятивний `performance/equity.csv`; оновлений `docs/equity.png` | по дню: ` Run d: ...` та ` Daily d: ...` |
| `ats stats` | Обчислити метрики Cum/Vol/MDD | `performance/equity.csv` | `performance/stats.json` з `{days,cum,vol,mdd}` | `Stats: N days; Cum=...; Vol=...; MDD=...` |
| `ats summary` | Однорядковий знімок стану | `performance/equity.csv`; `performance/stats.json` |  | `Summary: N days; Cum=...; Vol=...; MDD=...; last=YYYY-MM-DD r=... equity=...` |
| `ats report --date D` | Звіт-сторінка (markdown) | `performance/equity.csv`; `performance/stats.json`; `docs/equity.png` | `docs/report_D.md` | ` Report D written` |

**Примітки:**
- `performance/equity.csv` має шапку `date,r,equity`; `equity_D = equity_(D-1) * (1 + r_D)`, стартове значення `1.0`.
- Якщо бракує вхідних CSV, інструмент може створити прозорі *placeholder*-файли та виводить `NOTE:` у stderr.
- `docs/equity.png` оновлюється під час `daily`/`backfill`.

## Приклад (2025-09-01)

Виклик (PowerShell):
```powershell
.\ats.ps1 daily --date 2025-09-01
```

Очікуваний вивід:
```
 Run 2025-09-01: targets/orders/execution ready
 Daily 2025-09-01: weights OK; r=...
```

Очікувані артефакти:
- `performance/2025-09-01.json` з `{"date":"2025-09-01","gross_return":...}`
- Рядок для `2025-09-01` у `performance/equity.csv`
- Оновлений графік `docs/equity.png`
