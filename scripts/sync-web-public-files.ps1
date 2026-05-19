param(
  [Parameter(Mandatory = $true)]
  [string]$Destination
)

$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$fullDestination = [System.IO.Path]::GetFullPath($Destination)

if (-not (Test-Path -LiteralPath $fullDestination)) {
  throw "Pasta de destino nao encontrada: $fullDestination"
}

$publicFiles = @(
  @{
    Source = Join-Path $projectRoot 'docs\app-ads.txt'
    Destination = 'app-ads.txt'
  },
  @{
    Source = Join-Path $projectRoot 'docs\privacy-policy.html'
    Destination = 'privacy-policy.html'
  },
  @{
    Source = Join-Path $projectRoot 'docs\play-store-listing.md'
    Destination = 'play-store-listing.md'
  },
  @{
    Source = Join-Path $projectRoot 'docs\release-checklist.md'
    Destination = 'release-checklist.md'
  }
)

foreach ($file in $publicFiles) {
  if (-not (Test-Path -LiteralPath $file.Source)) {
    throw "Arquivo publico nao encontrado: $($file.Source)"
  }

  $targetPath = Join-Path $fullDestination $file.Destination
  Copy-Item -LiteralPath $file.Source -Destination $targetPath -Force
}

Write-Host "Arquivos publicos sincronizados em: $fullDestination"
