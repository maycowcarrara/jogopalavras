param(
  [int]$Limit = 20,
  [string]$Date = "",
  [string]$Cursor = "",
  [ValidateSet("Json", "Summary", "Raw")]
  [string]$Format = "Json",
  [string]$ApiUrl = "https://anagrama-oculto-ranking.maycowcarrara.workers.dev"
)

$ErrorActionPreference = "Stop"

$tokenPath = Join-Path $PSScriptRoot "..\workers\ranking-api\.wrangler\admin-logs-token.txt"
$token = $env:ADMIN_LOGS_TOKEN
if ([string]::IsNullOrWhiteSpace($token) -and (Test-Path $tokenPath)) {
  $token = Get-Content -Path $tokenPath -Raw
}

if ([string]::IsNullOrWhiteSpace($token)) {
  throw "Defina ADMIN_LOGS_TOKEN ou crie $tokenPath."
}

$queryParts = @("limit=$Limit")
if (-not [string]::IsNullOrWhiteSpace($Date)) {
  $queryParts += "date=$([System.Uri]::EscapeDataString($Date))"
}
if (-not [string]::IsNullOrWhiteSpace($Cursor)) {
  $queryParts += "cursor=$([System.Uri]::EscapeDataString($Cursor))"
}
$uri = "$ApiUrl/admin/logs?$($queryParts -join '&')"

$response = Invoke-RestMethod `
  -Uri $uri `
  -Headers @{ Authorization = "Bearer $token" }

switch ($Format) {
  "Raw" {
    $response
  }
  "Summary" {
    $response.entries | ForEach-Object {
      [PSCustomObject]@{
        receivedAt = $_.receivedAt
        source     = $_.source
        route      = $_.route
        errorType  = $_.errorType
        message    = $_.message
        key        = $_.key
      }
    } | Format-List

    if (-not $response.listComplete) {
      Write-Host "Cursor: $($response.cursor)"
    }
  }
  default {
    $response | ConvertTo-Json -Depth 12
  }
}
