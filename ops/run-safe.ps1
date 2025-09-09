param(
  [Parameter(Mandatory=$true)][string]$Script,
  [string[]]$Args = @()
)
$ErrorActionPreference = "Stop"
$exe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$target = (Resolve-Path $Script).Path

# зберемо аргументи без null-ів
$argList = @("-NoLogo","-NoProfile","-ExecutionPolicy","Bypass","-File",$target)
if ($Args -and $Args.Count -gt 0) { $argList += $Args }

$psi = @{
  FilePath    = $exe
  ArgumentList= $argList
  NoNewWindow = $true
  Wait        = $true
  PassThru    = $true
}
$p  = Start-Process @psi
$ec = $p.ExitCode
Write-Host "[SUBPROCESS EXITCODE=$ec]"
if ($ec -eq 0) { Write-Output "RUN_SAFE_OK" } else { Write-Output "RUN_SAFE_FAIL" }
