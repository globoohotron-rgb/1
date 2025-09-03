Param([Parameter(ValueFromRemainingArguments=$true)
# === diag: universe path & filter summary ===
if ($args -and ($args[0] -eq 'run' -or $args -contains 'run')) {
  try {
    $d = $null; $i = [Array]::IndexOf($args,'--date')
    if ($i -ge 0 -and $i + 1 -lt $args.Length) { $d = $args[$i+1] }
    if (-not $d -or $d -eq '') { $d = Get-Date -Format 'yyyy-MM-dd' }

    $alphaPath    = Join-Path 'alpha'    ("$d.csv")
    $universePath = Join-Path 'universe' ("$d.csv")

    $uExists = Test-Path $universePath
    $uFull   = if ($uExists) { (Resolve-Path $universePath).Path } else { [IO.Path]::GetFullPath($universePath) }
    Write-Output ("universe path={0} exists={1}" -f $uFull, $uExists)

    $N = 0; if (Test-Path $alphaPath) { try { $N = (Import-Csv -Path $alphaPath | Measure-Object).Count } catch {} }

    $skip = $null; $M = $N
    if (-not (Test-Path $alphaPath)) { $skip = 'alpha not found' }
    elseif (-not $uExists) { $skip = 'universe not found' }
    else {
      try {
        $alpha = Import-Csv -Path $alphaPath
        $uni   = Import-Csv -Path $universePath

        function Find-Col([string[]]$names, [string[]]$cands) {
          foreach ($c in $cands) { if ($names -contains $c) { return $c } }
          $lower = @{}; foreach ($n in $names) { $lower[$n.ToLower()] = $n }
          foreach ($c in $cands) { if ($lower.ContainsKey($c.ToLower())) { return $lower[$c.ToLower()] } }
          return $null
        }

        $aNames = if ($alpha.Count -gt 0) { $alpha[0].PsObject.Properties.Name } else { @() }
        $uNames = if ($uni.Count   -gt 0) { $uni[0].PsObject.Properties.Name }   else { @() }

        $symA = Find-Col $aNames @('symbol','ticker','secid','asset')
        $symU = Find-Col $uNames @('symbol','ticker','secid','asset')
        $actU = Find-Col $uNames @('is_active','active')
        $capU = Find-Col $uNames @('cap_usd','market_cap_usd','mkt_cap','cap')

        if (-not $symA -or -not $symU -or -not $actU -or -not $capU) {
          $skip = 'missing required columns'
        } else {
          # min_cap_usd із config/ats.yaml (best-effort)
          $minCap = 0.0
          if (Test-Path 'config/ats.yaml') {
            $m = Select-String -Path 'config/ats.yaml' -Pattern '^\s*min_cap_usd\s*:\s*([^\s#]+)' | Select-Object -First 1
            if ($m) { [double]::TryParse($m.Matches[0].Groups[1].Value, [ref]$minCap) | Out-Null }
          }

          $alphaSyms = @{}
          foreach ($r in $alpha) {
            $s = [string]$r.$symA
            if (-not [string]::IsNullOrWhiteSpace($s)) { $alphaSyms[$s.Trim().ToUpper()] = $true }
          }

          $cnt = 0
          foreach ($r in $uni) {
            $s = [string]$r.$symU
            if ([string]::IsNullOrWhiteSpace($s)) { continue }
            $s = $s.Trim().ToUpper()
            $active = [string]$r.$actU
            $isActive = @('1','true','y','yes','t').Contains($active.ToLower())
            $capVal = 0.0; [double]::TryParse(([string]$r.$capU -replace ',',''), [ref]$capVal) | Out-Null
            if ($isActive -and $capVal -ge $minCap -and $alphaSyms.ContainsKey($s)) { $cnt++ }
          }
          $M = $cnt
        }
      } catch { $skip = 'diagnostic error' }
    }

    if ($skip) {
      Write-Output ("universe filter: {0}{1} (SKIP: {2})" -f $N, $N, $skip)
    } else {
      Write-Output ("universe filter: {0}{1}" -f $N, $M)
    }
  } catch {
    Write-Output ("universe path=<diag failed> exists=False")
    Write-Output ("universe filter: 00 (SKIP: diag failed)")
  }
}
# === end diag ===][string[]]$Args)
$HERE = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Get-Command py -ErrorAction SilentlyContinue) {
  & py -3 "$HERE/bin/ats" @Args
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
  & python3 "$HERE/bin/ats" @Args
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
  & python "$HERE/bin/ats" @Args
} else {
  Write-Error "Python 3 не знайдено у PATH."
  exit 127
}
exit $LASTEXITCODE

if ($args -contains "run") {
    $date = $null
    $i = [Array]::IndexOf($args, "--date")
    if ($i -ge 0 -and $i + 1 -lt $args.Length) { $date = $args[$i + 1] }
    if (-not $date) { $date = Get-Date -Format "yyyy-MM-dd" }
    python tools\apply_universe.py --date $date
}


function Invoke-PrintUniverseLine {
    param([string]$Date)
# === diag: universe path & filter summary ===
if ($args -and ($args[0] -eq 'run' -or $args -contains 'run')) {
  try {
    $d = $null; $ix = [Array]::IndexOf($args,'--date')
    if ($ix -ge 0 -and $ix + 1 -lt $args.Length) { $d = $args[$ix+1] }
    if (-not $d -or $d -eq '') { $d = Get-Date -Format 'yyyy-MM-dd' }
    & .\tools\diag_universe.ps1 -Date $d
  } catch {}
}
# === end diag ===    if (-not $Date -or $Date -eq '') {
        $t = Get-ChildItem -Path 'targets' -Filter '*.csv' -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($t) { $Date = [IO.Path]::GetFileNameWithoutExtension($t.Name) } else { $Date = (Get-Date -Format 'yyyy-MM-dd') }
    }
    $alpha = Join-Path 'alpha'   ("$Date.csv")
    $tgt   = Join-Path 'targets' ("$Date.csv")
    $N = 0; if (Test-Path $alpha) { try { $N = (Import-Csv -Path $alpha | Measure-Object).Count } catch {} }
    $M = 0; if (Test-Path $tgt)   { try { $M = (Import-Csv -Path $tgt   | Measure-Object).Count } catch {} }
    Write-Output ("universe filter: {0}{1}" -f $N,$M)
}
# авто-виклик після 'run'
$__date = $null
$__i = [Array]::IndexOf($args, "--date")
if ($__i -ge 0 -and $__i + 1 -lt $args.Length) { $__date = $args[$__i + 1] }
if ( ($args -and $args[0] -eq 'run') -or ($args -contains 'run') ) {
    Invoke-PrintUniverseLine -Date $__date
}






