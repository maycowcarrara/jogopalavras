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
$syncPublicFilesScript = Join-Path $PSScriptRoot 'sync-web-public-files.ps1'

function Get-WranglerCommand {
  if (Test-Path -LiteralPath $wranglerCmd) {
    return $wranglerCmd
  }

  return 'npx'
}

function Get-WranglerBaseArgs {
  if (Test-Path -LiteralPath $wranglerCmd) {
    return @()
  }

  return @('wrangler')
}

function Assert-WranglerAuthenticated {
  $command = Get-WranglerCommand
  $baseArgs = Get-WranglerBaseArgs
  $output = & $command @baseArgs whoami 2>&1 | Out-String
  if ($output -match 'not authenticated') {
    throw "Cloudflare Wrangler nao autenticado neste ambiente. Rode 'workers\\ranking-api\\node_modules\\.bin\\wrangler.cmd login' e tente novamente."
  }
}

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

& $syncPublicFilesScript -Destination $buildDir
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Assert-WranglerAuthenticated

$command = Get-WranglerCommand
$baseArgs = Get-WranglerBaseArgs
& $command @baseArgs pages deploy $buildDir --project-name $ProjectName --branch $Branch

exit $LASTEXITCODE
