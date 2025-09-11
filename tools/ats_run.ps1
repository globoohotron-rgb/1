param([Parameter(Mandatory=$true)][string]$Date)
function Fail($m){ Write-Error $m; exit 1 }
try{ [void][datetime]::ParseExact($Date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture) }catch{ Fail "Invalid -Date '$Date'" }

$alphaPath = Join-Path 'alpha' ("{0}.csv" -f $Date)
if(-not (Test-Path $alphaPath)){ Fail "Not found: $alphaPath" }
$alpha = Import-Csv $alphaPath
if(-not $alpha -or $alpha.Count -lt 1){ Fail "Alpha file empty" }
if( -not ( ($alpha[0].PSObject.Properties.Name -contains 'symbol') -and ($alpha[0].PSObject.Properties.Name -contains 'alpha') )){ Fail "Alpha must have columns: symbol,alpha" }

$N = [int]$alpha.Count; if($N -lt 1){ Fail "No symbols" }
$w = 1.0 / [double]$N

New-Item -ItemType Directory -Force targets | Out-Null
New-Item -ItemType Directory -Force orders  | Out-Null
New-Item -ItemType Directory -Force execution | Out-Null

$targets = New-Object System.Collections.Generic.List[pscustomobject]
$acc = 0.0
for($i=0; $i -lt $N; $i++){
  if($i -lt ($N-1)){ $wi = $w; $acc += $wi } else { $wi = 1.0 - $acc }
  $targets.Add([pscustomobject]@{ symbol = $alpha[$i].symbol; weight = [double]$wi })
}
$targets | Export-Csv (Join-Path 'targets' ("{0}.csv" -f $Date)) -NoTypeInformation -Encoding UTF8

$orders = $targets | ForEach-Object { [pscustomobject]@{ symbol=$_.symbol; action='BUY'; weight=$_.weight } }
$orders | Export-Csv (Join-Path 'orders' ("{0}.csv" -f $Date)) -NoTypeInformation -Encoding UTF8

$fills  = $targets | ForEach-Object { [pscustomobject]@{ symbol=$_.symbol; weight_filled=$_.weight } }
$fills  | Export-Csv (Join-Path 'execution' ("fills_{0}.csv" -f $Date)) -NoTypeInformation -Encoding UTF8

$sum=0.0; $targets | ForEach-Object { $sum += [double]$_.weight }
if([math]::Abs($sum-1.0) -gt 1e-9){ Fail ("Weights sum != 1 (sum={0})" -f $sum) }

Write-Host ("`u{2713} ATS run {0} PASS" -f $Date)
exit 0
