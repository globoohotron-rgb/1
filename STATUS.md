param([int]$IntervalSec=60,[string]$Message="auto: sync")
git fetch origin | Out-Null
$branch=(git rev-parse --abbrev-ref HEAD).Trim()
if(-not $branch){Write-Error "Not a git repo?"; exit 1}
Write-Host "Auto-sync every $IntervalSec s on '$branch'. Ctrl+C to stop."
while($true){
  Start-Sleep -Seconds $IntervalSec
  git add -A | Out-Null
  if(git diff --cached --quiet){continue}
  $ts=Get-Date -Format "yyyy-MM-dd HH:mm"
  git commit -m "$Message ($ts)" | Out-Null
  git push -u origin $branch | Out-Null
  Write-Host " Auto-synced at $ts"
}
