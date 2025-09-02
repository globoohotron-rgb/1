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
