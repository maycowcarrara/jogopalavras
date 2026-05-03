param(
  [string]$ProjectName = 'entreletras',
  [string]$Branch = 'main',
  [string]$RankingApiUrl = 'https://anagrama-oculto-ranking.maycowcarrara.workers.dev',
  [switch]$BuildFirst,
  [switch]$Wasm
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectRoot 'build\web'
$indexFile = Join-Path $buildDir 'index.html'
$wranglerCmd = Join-Path $projectRoot 'workers\ranking-api\node_modules\.bin\wrangler.cmd'

if ($BuildFirst) {
  $flutterArgs = @(
    'build',
    'web',
    '--release',
    "--dart-define=RANKING_API_URL=$RankingApiUrl"
  )

  if ($Wasm) {
    $flutterArgs += '--wasm'
  }

  & (Join-Path $PSScriptRoot 'run-flutter.ps1') @flutterArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

if (-not (Test-Path -LiteralPath $indexFile)) {
  Write-Error "Build web nao encontrado em '$buildDir'. Rode npm run build:web:ranking:prod antes, ou use -BuildFirst."
  exit 1
}

if (Test-Path -LiteralPath $wranglerCmd) {
  & $wranglerCmd pages deploy $buildDir --project-name $ProjectName --branch $Branch
} else {
  & npx wrangler pages deploy $buildDir --project-name $ProjectName --branch $Branch
}

exit $LASTEXITCODE
