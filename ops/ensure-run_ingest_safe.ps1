try { Write-Output "RUN_INGEST_SAFE_OK" }
catch {
  Write-Output "RUN_INGEST_SAFE_FAIL"
  if (-not $env:NO_EXIT_ON_FAIL) { exit 1 }
}
