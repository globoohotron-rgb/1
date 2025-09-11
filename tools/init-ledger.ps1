param([switch]$DryRun)
$ErrorActionPreference = "Stop"

# 0) Перевірка Git-репо
$root = (git rev-parse --show-toplevel) 2>$null
if (-not $root) { throw "Not a git repository." }
$root = $root.Trim()
function Rel([string]$p){ return ($p.Replace($root, "").TrimStart('\','/')).Replace('\','/') }
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# 1) Шляхи
$docs = Join-Path $root "docs"
$ledgerPath = Join-Path $docs "ledger.md"
$manifestPath = Join-Path $docs "manifest.json"
New-Item -ItemType Directory -Force -Path $docs | Out-Null

# 2) База маніфесту v2.0
$sections = @("Infrastructure","Data","Universe","Factors","Alpha","RiskModel","Portfolio","Execution","Monitoring","PipelinesQA")
$sectionsObj = @{}
foreach($s in $sections){
  $sectionsObj[$s] = [ordered]@{
    state="unverified"; owner=""; artifacts=@(); acceptance_criteria=@(); evidence=@(); notes=""
  }
}
$manifest = [ordered]@{
  version="2.0"
  updated_at=$now
  north_star = [ordered]@{
    persona = "трейдер-користувач системи"
    value = "економить час, виконуючи рутину трейдера замість користувача"
    success_1 = "сигнал у Telegram зі зображенням графіка та рівнями entry/TP/SL"
    success_2 = "біржова інтеграція: авто-відкриття та закриття угоди"
    path = "бек-тест → стабільний профіт на дистанції → щоденні оновлення"
  }
  sections = $sectionsObj
  dod_mvp = @(
    "Е2Е: сигнал → зображення з рівнями → відправка у Telegram",
    "Backtest ≥ 6 місяців з метриками (win rate, PnL, Sharpe, max drawdown)",
    "Конфігурований Universe + ≥3 фактори + alpha-комбінатор",
    "Risk model: розмір позиції, SL/TP, ліміти ризику на угоду/день",
    "Моніторинг: структурні логи та алерт на фейли пайплайну"
  )
}

# 3) Скан артефактів → оновлення sections.* (in-progress/verified) + evidence
$allFiles = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\.git\\' }
$patterns = @{
  Infrastructure = @('(^|/)(Dockerfile|docker-compose\.ya?ml|Makefile)$','(^|/)(terraform|ansible|k8s|helm)/')
  Data           = @('(^|/)(data|datasets?|ingest|etl)/','(^|/)(data\.(py|ts|js)|schema\.(json|ya?ml|sql))$')
  Universe       = @('(^|/)(universe|symbols?|tickers?)\.(json|ya?ml|csv)$','(^|/)(universe|watchlist|universe)/')
  Factors        = @('(^|/)(factors?|features?)/','(^|/)(factor_|feature_)')
  Alpha          = @('(^|/)(alpha|strategy|strategies)/','(^|/)alpha\.(py|ts)$')
  RiskModel      = @('(^|/)risk.*','(^|/)(position.*sizing|risk_model)\.(py|ts)$')
  Portfolio      = @('(^|/)portfolio.*','(^|/)(optimizer|allocat)')
  Execution      = @('(^|/)(broker|exchange|execution|order|ccxt|binance|ib|alpaca).*')
  Monitoring     = @('(^|/)(monitor|logging|log.*\.ya?ml|sentry|alert).*')
  PipelinesQA    = @('(^|/)\.github/workflows/','(^|/)tests?/','(^|/)ci/','(^|/)(pipeline|Makefile)')
}
$verifiedNameHint = '(report|results?|metrics|backtest|junit|coverage|success|passed)'

foreach($section in $patterns.Keys){
  $regexes = $patterns[$section]
  $found = @()
  foreach($f in $allFiles){
    $rel = Rel $f.FullName
    foreach($rx in $regexes){ if ($rel -match $rx) { $found += $rel; break } }
  }
  $found = $found | Select-Object -Unique
  if ($found.Count -gt 0){
    $manifest.sections.$section.artifacts = $found
    $manifest.sections.$section.evidence = $found[0..([Math]::Min($found.Count-1, 4))]
    $hasVerified = ($found | Where-Object { $_ -match $verifiedNameHint }).Count -gt 0
    $manifest.sections.$section.state = if ($hasVerified) { "verified" } else { "in-progress" }
  }
}

# 4) Запис manifest.json (повністю)
$manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $manifestPath -Encoding UTF8

# 5) Ledger (створити якщо нема) + INIT рядок (ідемпотентно)
if (-not (Test-Path $ledgerPath)){
  @(
    '# Engineering Ledger'
    ''
    '| date(ISO) | type | section | summary | evidence | commit |'
    '|---|---|---|---|---|---|'
  ) | Set-Content -Path $ledgerPath -Encoding UTF8
}
$initLine = "| $now | INIT | global | Створено ledger.md і manifest.json | docs/manifest.json#global | <to-fill> |"
$hasInit = Select-String -Path $ledgerPath -Pattern '\|\s*INIT\s*\|\s*global\s*\|\s*Створено ledger\.md і manifest\.json' -Quiet
if (-not $hasInit){ Add-Content -Path $ledgerPath -Value $initLine }

# 6) Логи доказів по секціях (ідемпотентно): один рядок на секцію, evidence=перші 3 шляхи
foreach($section in $patterns.Keys){
  $art = $manifest.sections.$section.artifacts
  if ($art.Count -gt 0){
    $evidenceCell = ($art | Select-Object -First 3) -join ', '
    $exists = Select-String -Path $ledgerPath -Pattern "\|\s*EVIDENCE\s*\|\s*$section\s*\|.*\Q$evidenceCell\E" -Quiet
    if (-not $exists){
      $sum = "Виявлено артефакти ($($art.Count)), state=$($manifest.sections.$section.state)"
      Add-Content -Path $ledgerPath -Value ("| $now | EVIDENCE | $section | $sum | $evidenceCell | <to-fill> |")
    }
  }
}

# 7) Коміт (тільки якщо є staged відмінності)
git add -- docs/manifest.json docs/ledger.md | Out-Null
git diff --staged --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -m "chore(ledger): init accounting + north_star" | Out-Null
}

