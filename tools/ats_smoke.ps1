# tools/ats_smoke.ps1
$ErrorActionPreference = "Stop"

# repo root
$P    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT = Split-Path -Parent $P
$date = "2025-09-01"

# 1) run ATS
& "$ROOT\ats.cmd" run --date $date

# 2) expected artifacts
$tgt = Join-Path $ROOT ("targets\{0}.csv" -f $date)
$ord = Join-Path $ROOT ("orders\{0}.csv" -f $date)
$fil = Join-Path $ROOT ("execution\{0}.csv" -f $date)
foreach ($p in @($tgt,$ord,$fil)) { if (-not (Test-Path $p)) { throw ("missing artifact: {0}" -f $p) } }

# helpers
function Get-ColName($rows, [string[]]$cands) {
  if (-not $rows -or $rows.Count -eq 0) { throw "empty CSV" }
  $cols = $rows[0].PSObject.Properties.Name
  foreach ($c in $cands) { if ($cols -contains $c) { return $c } }
  throw ("columns not found; tried: {0}" -f ($cands -join ", "))
}

function Convert-Weight([string]$s) {
  if ($null -eq $s -or $s -eq "") { return [double]::NaN }
  $t = ($s -replace '\s','') -replace '%',''
  # unify decimal separator -> '.'
  $t = $t -replace ',', '.'
  try {
    $x = [double]::Parse($t, [System.Globalization.CultureInfo]::InvariantCulture)
  } catch {
    # last resort: current culture
    $x = [double]::Parse($t)
  }
  if ([double]::IsNaN($x)) { return [double]::NaN }
  # normalize percentages like 25 or 25% -> 0.25 (keep values already in 0..1)
  if ($x -gt 1.0 + 1e-9) {
    if ($x -le 100.0 + 1e-9) { $x = $x / 100.0 } else { throw ("weight too large: {0}" -f $x) }
  }
  return $x
}

function Convert-ToMap($rows, $symCol, $wCol) {
  $m = @{}
  foreach ($r in $rows) {
    $sym = [string]$r.$symCol
    $w = Convert-Weight ([string]$r.$wCol)
    if ([double]::IsNaN($w)) { throw ("NaN weight for {0}" -f $sym) }
    if ($w -lt 0) { throw ("negative weight for {0}: {1}" -f $sym, $w) }
    $m[$sym] = $w
  }
  return $m
}
function Get-WeightsSum($map) { ($map.Values | Measure-Object -Sum).Sum }

# 3) read CSVs
$t = Import-Csv $tgt
$o = Import-Csv $ord
$f = Import-Csv $fil

$tsym = Get-ColName $t @('asset','symbol','ticker','secid','id','isin','bbg')
$ws   = Get-ColName $t @('weight')
$osym = Get-ColName $o @('asset','symbol','ticker','secid','id','isin','bbg')
$fsym = Get-ColName $f @('asset','symbol','ticker','secid','id','isin','bbg')
$ow   = Get-ColName $o @('weight')
$fw   = Get-ColName $f @('weight')

$tm = Convert-ToMap $t $tsym $ws
$om = Convert-ToMap $o $osym $ow
$fm = Convert-ToMap $f $fsym $fw

# 4) checks
$sum = [double](Get-WeightsSum $tm)
if ([math]::Abs($sum - 1.0) -gt 1e-8) { throw ("targets sum != 1 (sum={0})" -f $sum) }

if ($tm.Count -ne $om.Count) { throw ("orders count != targets count ({0} vs {1})" -f $tm.Count, $om.Count) }
foreach ($k in $tm.Keys) {
  if (-not $om.ContainsKey($k)) { throw ("orders missing {0}" -f $k) }
  if ([math]::Abs($tm[$k] - $om[$k]) -gt 1e-8) { throw ("orders weight mismatch {0}: t={1} o={2}" -f $k, $tm[$k], $om[$k]) }
}

if ($om.Count -ne $fm.Count) { throw ("fills count != orders count ({0} vs {1})" -f $om.Count, $fm.Count) }
foreach ($k in $om.Keys) {
  if (-not $fm.ContainsKey($k)) { throw ("fills missing {0}" -f $k) }
  if ([math]::Abs($om[$k] - $fm[$k]) -gt 1e-8) { throw ("fills weight mismatch {0}: o={1} f={2}" -f $k, $om[$k], $fm[$k]) }
}

Write-Host ("TEST PASS: ats {0}" -f $date)
exit 0
