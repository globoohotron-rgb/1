param([string]$Date)

if (-not $Date -or $Date -eq '') { $Date = Get-Date -Format 'yyyy-MM-dd' }

$alphaPath = Join-Path 'alpha'    ("$Date.csv")
$uPath     = Join-Path 'universe' ("$Date.csv")

$uExists = Test-Path $uPath
$uFull   = if ($uExists) { (Resolve-Path $uPath).Path } else { [IO.Path]::GetFullPath($uPath) }
Write-Output ("universe path={0} exists={1}" -f $uFull, $uExists)

$N = 0
if (Test-Path $alphaPath) { try { $N = (Import-Csv -Path $alphaPath | Measure-Object).Count } catch {} }

$skip = $null; $M = $N
if (-not (Test-Path $alphaPath))       { $skip = 'alpha not found' }
elseif (-not $uExists)                  { $skip = 'universe not found' }
else {
  try {
    $alpha = Import-Csv -Path $alphaPath
    $uni   = Import-Csv -Path $uPath

    $aCols = if ($alpha.Count -gt 0) { $alpha[0].PSObject.Properties.Name } else { @() }
    $uCols = if ($uni.Count   -gt 0) { $uni[0].PSObject.Properties.Name }   else { @() }

    # Пошук потрібних колонок (insensitive)
    $mapLower = @{}
    foreach ($n in $aCols) { $mapLower[$n.ToLower()] = $n }
    foreach ($n in $uCols) { if (-not $mapLower.ContainsKey($n.ToLower())) { $mapLower[$n.ToLower()] = $n } }

    $symA = $mapLower['symbol']; if (-not $symA) { $symA = $mapLower['ticker']; if (-not $symA) { $symA = $mapLower['secid']; if (-not $symA) { $symA = $mapLower['asset'] } } }
    $symU = $mapLower['symbol']; if (-not $symU) { $symU = $mapLower['ticker']; if (-not $symU) { $symU = $mapLower['secid']; if (-not $symU) { $symU = $mapLower['asset'] } } }
    $actU = $mapLower['is_active']; if (-not $actU) { $actU = $mapLower['active'] }
    $capU = $mapLower['cap_usd'];  if (-not $capU){ $capU=$mapLower['market_cap_usd']; if (-not $capU){ $capU=$mapLower['mkt_cap']; if (-not $capU){ $capU=$mapLower['cap'] } } }

    if (-not $symA -or -not $symU -or -not $actU -or -not $capU) {
      $skip = 'missing required columns'
    } else {
      # читаємо поріг (best-effort)
      $minCap = 0.0
      if (Test-Path 'config/ats.yaml') {
        $m = Select-String -Path 'config/ats.yaml' -Pattern '^\s*min_cap_usd\s*:\s*([^\s#]+)' | Select-Object -First 1
        if ($m) { [double]::TryParse($m.Matches[0].Groups[1].Value, [ref]$minCap) | Out-Null }
      }

      $alphaSet = @{}
      foreach ($r in $alpha) {
        $s = [string]$r.$symA
        if (-not [string]::IsNullOrWhiteSpace($s)) { $alphaSet[$s.Trim().ToUpper()] = $true }
      }

      $cnt = 0
      foreach ($r in $uni) {
        $s = [string]$r.$symU
        if ([string]::IsNullOrWhiteSpace($s)) { continue }
        $s = $s.Trim().ToUpper()
        $activeText = [string]$r.$actU
        $isActive = @('1','true','y','yes','t').Contains(($activeText ?? '').ToLower())
        $capVal = 0.0; [double]::TryParse(([string]$r.$capU -replace ',',''), [ref]$capVal) | Out-Null
        if ($isActive -and $capVal -ge $minCap -and $alphaSet.ContainsKey($s)) { $cnt++ }
      }
      $M = $cnt
    }
  } catch { $skip = 'diagnostic error' }
}

if ($skip) { Write-Output ("universe filter: {0}{1} (SKIP: {2})" -f $N, $N, $skip) }
else       { Write-Output ("universe filter: {0}{1}"           -f $N, $M) }
