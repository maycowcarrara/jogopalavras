param(
  [string]$ApiUrl = "https://anagrama-oculto-ranking.maycowcarrara.workers.dev",
  [string]$Route = "/manual/simulation"
)

$ErrorActionPreference = "Stop"

$event = @{
  timestamp  = (Get-Date).ToUniversalTime().ToString("o")
  source     = "manual_simulation"
  fatal      = $false
  route      = $Route
  errorType  = "SyntheticError"
  message    = "Evento sintetico para testar o pipeline de logs do Anagrama Oculto."
  stackTrace = "SyntheticError: teste manual`n    at scripts/simulate-error-log.ps1"
  platform   = "powershell"
  appVersion = "manual"
  buildMode  = "test"
  context    = @{
    script = "scripts/simulate-error-log.ps1"
    safe   = $true
  }
}

$response = Invoke-RestMethod `
  -Uri "$ApiUrl/logs" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{ events = @($event) } | ConvertTo-Json -Depth 6)

$response
