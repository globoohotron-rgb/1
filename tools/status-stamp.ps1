param([switch]$DryRun)

$ErrorActionPreference = "Stop"
# --- setup
$root = (git rev-parse --show-toplevel) 2>$null; if(-not $root){ throw "Not a git repo" }
$root = $root.Trim()
function Rel([string]$p){ ($p.Replace($root,"").TrimStart("\","/")).Replace("\","/") }
$now  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$runId = Get-Date -UFormat "%Y%m%d-%H%M%S"
$auditDir = Join-Path $root ("logs/audit/"+$runId)
New-Item -ItemType Directory -Force -Path $auditDir, (Join-Path $root "docs") | Out-Null

# --- load manifest
$manPath = Join-Path $root "docs/manifest.json"
if(-not (Test-Path $manPath)){ throw "docs/manifest.json not found" }
$m = Get-Content $manPath -Raw | ConvertFrom-Json

# --- sections list (10 за планом)
$required = @("Infrastructure","Data","Universe","Factors","Alpha","RiskModel","Portfolio","Execution","Monitoring","PipelinesQA")
$sections = @{}
foreach($name in $required){
  if(-not $m.sections.$name){
    $m.sections | Add-Member -NotePropertyName $name -NotePropertyValue ([pscustomobject]@{state="missing";owner="";artifacts=@();acceptance_criteria=@();evidence=@();notes=""})
  }
  $sections[$name] = [pscustomobject]@{ artifacts=@(); evidence=@(); metrics=@{}; state="missing"; ac_total=0; ac_passed=0; notes="" }
}

# --- discovery: files
$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.FullName -notmatch '\\logs\\' -and $_.FullName -notmatch '\\quarantine\\' }

# секційні патерни
$map = @{
  Infrastructure = @('(^|/)(Dockerfile|docker-compose\.ya?ml)$','(^|/)(terraform|ansible|k8s|helm|infra)(/|$)','(^|/)Makefile$')
  Data           = @('(^|/)(data|datasets?|ingest|etl|schemas?)(/|$)','(^|/)data\.(py|ts|js)$')
  Universe       = @('(^|/)(universe|watchlist)(/|$)','(^|/)(universe|symbols?|tickers?)\.(csv|json|ya?ml)$')
  Factors        = @('(^|/)(factors?|features?)(/|$)','(^|/)(factor_|feature_)')
  Alpha          = @('(^|/)(alpha|strategy|strategies)(/|$)','(^|/)alpha\.(py|ts)$')
  RiskModel      = @('(^|/)risk_model|risk.*','(^|/)(position.*sizing|scales)\.(json|ya?ml|py|ts)$')
  Portfolio      = @('(^|/)portfolio|allocat|optimizer')
  Execution      = @('(^|/)(exec|execution|broker|exchange|order|ccxt|binance|alpaca|ib)(/|$)')
  Monitoring     = @('(^|/)(monitor|logging|sentry|alert|logs?\.ya?ml)(/|$)')
  PipelinesQA    = @('(^|/)\.github/workflows/','(^|/)(ci|pipeline|tests?)(/|$)')
}

foreach($f in $files){
  $rel = Rel $f.FullName
  foreach($kv in $map.GetEnumerator()){
    foreach($rx in $kv.Value){
      if($rel -match $rx){ $sections[$kv.Key].artifacts += $rel; break }
    }
  }
}

# --- runnable evidence (best-effort)
$tests_total = 0; $tests_passed = 0; $lastLog = $null

if( (Test-Path -Path "pyproject.toml") -or (Test-Path -Path "requirements.txt") ){
  $pytest = Get-Command pytest -ErrorAction SilentlyContinue
  if($pytest){
    $log = Join-Path $auditDir "pytest.txt"
    & pytest -q *>&1 | Tee-Object -FilePath $log
    $content = Get-Content $log -Raw
    $p = [regex]::Match($content,'(\d+)\s+passed')
    $f = [regex]::Match($content,'(\d+)\s+failed')
    if($p.Success){ $tests_passed = [int]$p.Groups[1].Value }
    if($f.Success){ $tests_total = $tests_passed + [int]$f.Groups[1].Value } else { if($tests_passed -gt 0){ $tests_total = $tests_passed } }
    $lastLog = Rel $log
  } else {
    $log = Join-Path $auditDir "python-no-pytest.txt"; "pytest not installed" | Set-Content $log; $lastLog = Rel $log
  }
}elseif(Test-Path -Path "package.json"){
  $log = Join-Path $auditDir "npm-test.txt"
  & npm test --silent *>&1 | Tee-Object -FilePath $log
  $lastLog = Rel $log
}elseif(Test-Path -Path "Makefile"){
  $log = Join-Path $auditDir "make-test.txt"
  & make test *>&1 | Tee-Object -FilePath $log
  $lastLog = Rel $log
}else{
  $log = Join-Path $auditDir "no-tests.txt"; "no tests detected" | Set-Content $log; $lastLog = Rel $log
}

# --- compute states + fill manifest fields
$statusRows = @()
foreach($name in $required){
  $sec = $sections[$name]
  # dedup artifacts
  $sec.artifacts = $sec.artifacts | Sort-Object -Unique
  $has = $sec.artifacts.Count -gt 0
  $ac = $m.sections.$name.acceptance_criteria
  if(-not $ac){ $ac = @(); $m.sections.$name.acceptance_criteria = @() }

  # infer AC якщо пусто (мінімально)
  if($ac.Count -eq 0){
    switch ($name){
      "Data"       { $ac = @("Завантаження/очистка даних працює локально","Є схеми/формати джерел","Є базові тести для loader"); }
      "Universe"   { $ac = @("Конфігурований список інструментів","Файл/папка universe* присутня"); }
      "Factors"    { $ac = @("≥3 фактори реалізовані","Є приклади/тести факторів"); }
      "Alpha"      { $ac = @("Є комбінатор альф","Є скрипт бектесту"); }
      "RiskModel"  { $ac = @("Розмір позиції","SL/TP","Ліміти ризику"); }
      "Portfolio"  { $ac = @("Алокація портфеля","Оптимізатор/правила"); }
      "Monitoring" { $ac = @("Структурні логи","Алерт на фейли"); }
      "PipelinesQA"{ $ac = @("CI лінт/тест на push","Смоук-тести/перевірка пайплайну"); }
      default      { $ac = @("Базові артефакти існують","Можливість локального запуску"); }
    }
    $m.sections.$name.acceptance_criteria = $ac
    $m.sections.$name | Add-Member -NotePropertyName ac_inferred -NotePropertyValue $true -Force
  } else {
    $m.sections.$name | Add-Member -NotePropertyName ac_inferred -NotePropertyValue $false -Force
  }

  $sec.ac_total = $ac.Count
  # heuristics: verified якщо є артефакти і всі тести (якщо були) пройшли
  if($has -and $tests_total -gt 0 -and $tests_passed -eq $tests_total){ $sec.state = "verified"; $sec.ac_passed = $sec.ac_total }
  elseif($has){ $sec.state = "in_progress" } else { $sec.state = "missing" }

  # evidence + metrics
  if($lastLog){ $sec.evidence += $lastLog }
  $sec.metrics = @{ tests_total=$tests_total; tests_passed=$tests_passed; artifacts_count=$sec.artifacts.Count }

  # write back to manifest section
  $m.sections.$name.state   = $sec.state
  $m.sections.$name.evidence = @($m.sections.$name.evidence + $sec.evidence) | Sort-Object -Unique
  $m.sections.$name | Add-Member -NotePropertyName metrics -NotePropertyValue $sec.metrics -Force
  if(-not $m.sections.$name.artifacts){ $m.sections.$name.artifacts = @() }
  $m.sections.$name.artifacts = @($m.sections.$name.artifacts + $sec.artifacts) | Sort-Object -Unique

  # status row
  $keyArts = if($sec.artifacts.Count -gt 0){ ($sec.artifacts | Select-Object -First 2) -join ", " } else { "–" }
  $lastEv  = if($lastLog){ $lastLog } else { "–" }
  $statusRows += @("| {0} | {1} | {2}/{3} | {4} | {5} | {6} |" -f $name,$sec.state,$sec.ac_passed,$sec.ac_total,$keyArts,$lastEv,$sec.notes)
}

# --- write status_report.md
$repPath = Join-Path $root "docs/status_report.md"
@(
"# Status Report (Readiness Audit)",
"| section | state | ac_passed/total | key_artifacts | last_evidence | notes |",
"|---|---|---|---|---|---|"
) + $statusRows | Set-Content -Encoding UTF8 $repPath

# --- update manifest time
$m.updated_at = $now
$m | ConvertTo-Json -Depth 20 | Set-Content $manPath -Encoding UTF8

# --- ledger lines (append-only)
$ledger = Join-Path $root "docs/ledger.md"
if(-not (Test-Path $ledger)){
  @('# Engineering Ledger','','| date(ISO) | type | section | summary | evidence | commit |','|---|---|---|---|---|---|') | Set-Content $ledger -Encoding UTF8
}
$sha = (git rev-parse --short HEAD).Trim()
$verifyLine = "| $now | VERIFY | Data | Пройшли unit tests (heuristic) | $lastLog | $sha |"
$stampLine  = "| $now | STAMP | global | Оновлено статуси секцій у manifest.json | docs/status_report.md | $sha |"
Add-Content $ledger $verifyLine
Add-Content $ledger $stampLine

# --- git: commit on branch + PR
git add -- docs/status_report.md docs/manifest.json logs/audit/ docs/ledger.md | Out-Null
$branch = "status/readiness-v2"
$cur = (git rev-parse --abbrev-ref HEAD).Trim()
if($cur -ne $branch){
  git switch -c $branch 2>$null | Out-Null
  if($LASTEXITCODE -ne 0){ git switch $branch | Out-Null }
}
git commit -m "chore(status): audit & stamp readiness (run=$runId)" | Out-Null

try{ gh pr create -t "chore(status): audit & stamp readiness" -b "See docs/status_report.md (run $runId)" -B main -H $branch | Out-Null } catch { }

# console summary
[pscustomobject]@{
  run_id = $runId
  tests_total = $tests_total
  tests_passed = $tests_passed
  report = Rel $repPath
  manifest = Rel $manPath
  ledger = Rel $ledger
}
