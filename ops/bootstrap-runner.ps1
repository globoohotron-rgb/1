$exe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
& $exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ensure-run_ingest_safe.ps1"
