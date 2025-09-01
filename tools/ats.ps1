param([Parameter(ValueFromRemainingArguments=$true)][string[]]$ArgsList)
function Fail($m){ Write-Error $m; exit 2 }

if(-not $ArgsList -or $ArgsList[0] -ne 'run'){ Fail "Usage: ats run --date YYYY-MM-DD" }
$idx = [Array]::IndexOf($ArgsList,'--date')
if($idx -lt 0 -or ($idx+1) -ge $ArgsList.Count){ Fail "Missing --date YYYY-MM-DD" }
$Date = $ArgsList[$idx+1]

try{ [void][datetime]::ParseExact($Date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture) } catch { Fail "Invalid date: $Date (expected YYYY-MM-DD)" }

$runner = Join-Path $PSScriptRoot 'ats_run.ps1'
if(-not (Test-Path $runner)){ Write-Error "Runner not found: $runner"; exit 3 }

& $runner -Date $Date
exit $LASTEXITCODE
