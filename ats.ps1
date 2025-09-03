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
# === universe filter hook (auto-injected) ===
if ($args -contains "run") {
    $date = $null
    $i = [Array]::IndexOf($args, "--date")
    if ($i -ge 0 -and $i + 1 -lt $args.Length) { $date = $args[$i + 1] }
    if (-not $date) { $date = Get-Date -Format "yyyy-MM-dd" }
    python tools\apply_universe.py --date $date
}
# === post-run: guaranteed universe filter log ===
function Invoke-PrintUniverseLine {
    param([string]$Date)
    if (-not $Date -or $Date -eq '') {
        $t = Get-ChildItem targets\*.csv -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($t) { $Date = [IO.Path]::GetFileNameWithoutExtension($t.Name) }
        if (-not $Date) { $Date = (Get-Date -Format "yyyy-MM-dd") }
    }
    $alpha = Join-Path alpha    ("$Date.csv")
    $tgt   = Join-Path targets  ("$Date.csv")
    python - <<'PY' $alpha $tgt
import sys, csv, os
alpha_path, tgt_path = sys.argv[1], sys.argv[2]
def count_rows(path):
    try:
        with open(path, encoding='utf-8', newline='') as f:
            return sum(1 for _ in csv.DictReader(f))
    except Exception:
        return 0
N = count_rows(alpha_path)
M = count_rows(tgt_path)
print(f'universe filter: {N}{M}')
PY
}
# викликаємо після run
$__date = $null
$__i = [Array]::IndexOf($args, "--date")
if ($__i -ge 0 -and $__i + 1 -lt $args.Length) { $__date = $args[$__i + 1] }
if ($args -contains "run" -or ($args.Length -ge 1 -and $args[0] -eq "run")) {
    Invoke-PrintUniverseLine -Date $__date
}
