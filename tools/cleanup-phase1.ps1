param(
  [switch]$DryRun,
  [int]$LargeFileMB = 25,
  [int]$StaleMonths = 12
)
$ErrorActionPreference = "Stop"

# --- Setup
$root = (git rev-parse --show-toplevel) 2>$null; if(-not $root){ throw "Not a git repo" }
$root = $root.Trim()
function Rel([string]$p){ return ($p.Replace($root,"").TrimStart('\','/')).Replace('\','/') }
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$runId = Get-Date -UFormat "%Y%m%d-%H%M%S"
$logDir = Join-Path $root ("logs/cleanup/run-" + $runId)
New-Item -ItemType Directory -Force -Path $logDir, (Join-Path $root "docs") | Out-Null

$deny = @("*.log","*.tmp","*.bak","*.old","~*","Thumbs.db",".DS_Store","__pycache__/","*.pyc",".ipynb_checkpoints/","dist/","build/",".pytest_cache/",".mypy_cache/",".idea/")
$protected = @(".git/","docs/ledger.md","docs/manifest.json","LICENSE","LICENSE*","README","README*","quarantine/","logs/","tools/cleanup-phase1.ps1")
$textExt = @(".py",".ts",".js",".json",".yml",".yaml",".md",".toml",".ini",".cfg",".txt",".css",".html",".xml",".sh",".ps1",".psm1",".bat",".cmd",".csv",".sql")

# --- Helper
function IsDenied($rel){
  foreach($p in $deny){
    if($p.EndsWith("/")){
      # папки з deny_patterns
      if($rel -match [regex]::Escape($p.TrimEnd('/'))){ return $true }
    }else{
      # файли з deny_patterns
      $leaf = [System.IO.Path]::GetFileName($rel)
      if($leaf -like $p){ return $true }
    }
  }
  return $false
}

function IsProtected($rel){
  foreach($p in $protected){
    if($p.EndsWith("/")){
      if($rel.StartsWith($p)) { return $true }
    }else{
      if($rel -like $p){ return $true }
    }
  }
  return $false
}

function Write-Row(
  $sw,
  [string]$path,
  [string]$action,
  [string]$reason,
  [string]$refs,
  [int]$size,
  [string]$mtime,
  [double]$conf,
  [string]$evid
){
  # будуємо Markdown-рядок без форматних індексів
  $confTxt = "{0:N2}" -f $conf
  $cols = @($path,$action,$reason,$refs,$size,$mtime,$confTxt,$evid)
  $sw.WriteLine('|' + ' ' + ($cols -join ' | ') + ' |')
}

# --- Baseline test command (best-effort)
function Invoke-BuildTests([string]$phase){
  $log = Join-Path $logDir ("{0}.log" -f $phase)
  $exit = 0
  Push-Location $root
  try{
    if ( (Test-Path -Path "pyproject.toml") -or (Test-Path -Path "requirements.txt") ) {
      if(Get-Command pytest -ErrorAction SilentlyContinue){ & pytest -q *>&1 | Tee-Object -FilePath $log; $exit = $LASTEXITCODE }
      else { "pytest not found" | Tee-Object -FilePath $log }
    }elseif(Test-Path "package.json"){
      & npm test --silent *>&1 | Tee-Object -FilePath $log; $exit = $LASTEXITCODE
    }elseif(Test-Path "Makefile"){
      & make test *>&1 | Tee-Object -FilePath $log; $exit = $LASTEXITCODE
    }else{
      "no tests detected" | Tee-Object -FilePath $log
    }
  } finally { Pop-Location }
  return @{ ExitCode=$exit; Log=Rel $log }
}

# --- Discovery: index
$files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
  $_.FullName -notmatch '\\.git\\' -and $_.FullName -notmatch '\\quarantine\\' -and $_.FullName -notmatch '\\logs\\'
}
$index = @()
$hashMap = @{}
foreach($f in $files){
  $rel = Rel $f.FullName
  $ext = $f.Extension.ToLower()
  $sizeKB = [math]::Round($f.Length/1KB)
  $mtime = $f.LastWriteTimeUtc.ToString("yyyy-MM-dd")
  $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
  $item = [ordered]@{ path=$rel; size_kb=$sizeKB; mtime=$mtime; ext=$ext; hash=$hash }
  $index += $item
  if(-not $hashMap.ContainsKey($hash)){ $hashMap[$hash] = @() }
  $hashMap[$hash] += $rel
}
$index | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $logDir "index.json") -Encoding UTF8

# --- Simple refs (bounded)
$textFiles = $files | Where-Object { $textExt -contains $_.Extension.ToLower() }
$limit = 2000
if($textFiles.Count -gt $limit){ $textFiles = $textFiles[0..($limit-1)] }
$refCounts = @{}
foreach($it in $index){
  $leaf = [IO.Path]::GetFileName($it.path)
  $refCounts[$it.path] = (Select-String -Path ($textFiles.FullName) -SimpleMatch -Pattern $leaf -List -ErrorAction SilentlyContinue | Measure-Object).Count
}

# --- Heuristics
$cutoff = (Get-Date).AddMonths(-$StaleMonths)
$decisions = New-Object System.Collections.ArrayList
$reportPath = Join-Path $root "docs/cleanup_report.md"
$manPath = Join-Path $root "docs/cleanup_manifest.json"
$sw = New-Object System.IO.StreamWriter($reportPath,$false,[Text.UTF8Encoding]::new($true))
$sw.WriteLine("# Cleanup Report (Phase-1)")
$sw.WriteLine("| path | action | reason | refs | size_kb | last_modified | confidence | evidence |")
$sw.WriteLine("|---|---|---|---|---:|---|---:|---|")

$quarantineList = @()
$summary = @{ keep=0; quarantine=0; remove=0; fix=0 }
foreach($it in $index){
  $rel = $it.path
  $refs = $refCounts[$rel]; if($null -eq $refs){ $refs = 0 }
  $reason = ""; $action = "KEEP"; $conf = 0.6
  if(IsProtected $rel){ $action="KEEP"; $reason="protected"; $conf=1.0 }
  elseif(IsDenied $rel){ $action="QUARANTINE"; $reason="deny_pattern"; $conf=0.95 }
  elseif($it.size_kb -gt ($LargeFileMB*1024)){ $action="QUARANTINE"; $reason="large_file"; $conf=0.9 }
  elseif($hashMap[$it.hash].Count -gt 1 -and $hashMap[$it.hash][0] -ne $rel){ $action="QUARANTINE"; $reason="duplicate(hash="+$it.hash.Substring(0,8)+")"; $conf=0.8 }
  elseif([datetime]::Parse($it.mtime+"Z") -lt $cutoff -and $refs -eq 0){ $action="QUARANTINE"; $reason="stale_orphan"; $conf=0.8 }
  # tooling folders hint
  elseif($rel -match '(^|/)(__pycache__|\.ipynb_checkpoints|dist|build|\.pytest_cache|\.mypy_cache|\.idea)(/|$)'){
    $action="QUARANTINE"; $reason="tooling_artifact"; $conf=0.9
  }

  if($action -eq "QUARANTINE"){ $quarantineList += $rel; $summary.quarantine++ }
  else { $summary.keep++ }

  Write-Row $sw $rel $action $reason $refs $it.size_kb $it.mtime $conf ("logs/cleanup/"+("run-"+$runId)+"/index.json")
  [void]$decisions.Add([ordered]@{ path=$rel; action=$action; reason=$reason; confidence=$conf; refs=$refs; evidence=@("logs/cleanup/run-$runId/index.json") })
}
$sw.Close()

# --- Manifest write
$man = [ordered]@{
  updated_at = $now
  policy = @{ large_file_mb=$LargeFileMB; stale_months=$StaleMonths }
  decisions = $decisions
  summary = $summary
}
$man | ConvertTo-Json -Depth 10 | Set-Content $manPath -Encoding UTF8

# --- Baseline tests
$baseline = Invoke-BuildTests "baseline"
$baselineExit = $baseline.ExitCode

# --- Quarantine move
$moveCount = 0
foreach($rel in $quarantineList | Sort-Object -Unique){
  if(IsProtected $rel){ continue }
  $src = Join-Path $root $rel
  if(-not (Test-Path $src)){ continue } # вже переміщено
  $dst = Join-Path $root ("quarantine/" + $rel)
  if($DryRun){ continue }
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($dst)) | Out-Null
  Move-Item -Force $src $dst
  $moveCount++
}

# --- Post tests
$post = Invoke-BuildTests "post-quarantine"
$postExit = $post.ExitCode

# --- If tests failed after move => revert all moved files back (safe)
$reverted = 0
if(-not $DryRun -and $baselineExit -eq 0 -and $postExit -ne 0){
  foreach($rel in $quarantineList | Sort-Object -Unique){
    $src = Join-Path $root ("quarantine/" + $rel)
    $dst = Join-Path $root $rel
    if(Test-Path $src){
      New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($dst)) | Out-Null
      Move-Item -Force $src $dst
      $reverted++
    }
  }
}

# --- Git add/commit on branch
git add -- docs/cleanup_report.md docs/cleanup_manifest.json logs/cleanup/ quarantine/ | Out-Null
$branch = "cleanup/phase-1-quarantine"
$cur = (git rev-parse --abbrev-ref HEAD).Trim()
if($cur -ne $branch){
  git switch -c $branch 2>$null | Out-Null
  if($LASTEXITCODE -ne 0){ git switch $branch | Out-Null }
}
git commit -m ("chore(cleanup): phase-1 quarantine (moved={0}, reverted={1})" -f $moveCount,$reverted) 2>$null | Out-Null

# --- Ledger line(s)
$ledger = Join-Path $root "docs/ledger.md"
if(-not (Test-Path $ledger)){
  @('# Engineering Ledger','','| date(ISO) | type | section | summary | evidence | commit |','|---|---|---|---|---|---|') | Set-Content $ledger -Encoding UTF8
}
$sha = (git rev-parse --short HEAD).Trim()
$line1 = "| $now | AUDIT | repo | Phase-1 cleanup: classification ($($summary.quarantine) quarantine) | $(Rel (Join-Path $logDir 'index.json')) | $sha |"
if(-not (Select-String $ledger -Pattern [regex]::Escape($line1) -Quiet)){ Add-Content $ledger $line1 }
$line2 = "| $now | QUARANTINE | repo | Moved $moveCount items → quarantine/ (reverted=$reverted) | docs/cleanup_report.md | $sha |"
if(-not (Select-String $ledger -Pattern [regex]::Escape($line2) -Quiet)){ Add-Content $ledger $line2 }
git add -- docs/ledger.md | Out-Null
git commit -m "chore(ledger): audit & quarantine logged" 2>$null | Out-Null

# --- PR (best-effort, requires GitHub CLI)
$defaultBase = "main"
try{
  & gh pr create -t "chore(cleanup): phase-1 quarantine" -b "Phase-1 quarantine. See docs/cleanup_report.md" -B $defaultBase -H $branch | Out-Null
} catch { }

# --- Console summary
[pscustomobject]@{
  run_id = $runId
  dry_run = $DryRun
  baseline_exit = $baselineExit
  post_exit = $postExit
  moved = $moveCount
  reverted = $reverted
  quarantine = $summary.quarantine
  report = Rel $reportPath
  manifest = Rel $manPath
}

function Write-Row($sw,[string]$path,[string]$action,[string]$reason,[string]$refs,[int]$size,[string]$mtime,[double]$conf,[string]$evid){
  $cols = @($path,$action,$reason,$refs,$size,$mtime,("{0:N2}" -f $conf),$evid)
  $sw.WriteLine('|' + ' ' + ($cols -join ' | ') + ' |')
}
