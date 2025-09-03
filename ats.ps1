Param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
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
    if (-not $Date -or $Date -eq '') {
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



