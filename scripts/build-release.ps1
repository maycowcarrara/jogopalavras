param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('web', 'aab', 'exe')]
  [string]$Target
)

$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$releaseRoot = Join-Path $projectRoot 'release'
$rankingApiUrl = 'https://anagrama-oculto-ranking.maycowcarrara.workers.dev'
$pagesProjectName = 'entreletras'
$pagesBranch = 'main'
$pagesUrl = "https://$pagesProjectName.pages.dev"
$bannerAdUnitId = 'ca-app-pub-5325559668232561/9738756810'
$interstitialAdUnitId = 'ca-app-pub-5325559668232561/4169586588'
$syncPublicFilesScript = Join-Path $PSScriptRoot 'sync-web-public-files.ps1'
$wranglerCmd = Join-Path $projectRoot 'workers\ranking-api\node_modules\.bin\wrangler.cmd'

function Assert-PathInsideReleaseRoot {
  param([Parameter(Mandatory = $true)][string]$Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullReleaseRoot = [System.IO.Path]::GetFullPath($releaseRoot)
  if (-not $fullPath.StartsWith($fullReleaseRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Caminho de release fora da pasta esperada: $fullPath"
  }
}

function Reset-ReleaseDirectory {
  param([Parameter(Mandatory = $true)][string]$Path)

  Assert-PathInsideReleaseRoot -Path $Path
  if (Test-Path -LiteralPath $Path) {
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
  New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Copy-DirectoryContents {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Pasta de origem nao encontrada: $Source"
  }

  Reset-ReleaseDirectory -Path $Destination
  Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
}

function Invoke-CheckedCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$CommandArgs
  )

  & $Command @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

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

function Publish-WebRelease {
  param([Parameter(Mandatory = $true)][string]$Directory)

  Assert-WranglerAuthenticated

  $command = Get-WranglerCommand
  $baseArgs = Get-WranglerBaseArgs
  & $command @baseArgs pages deploy $Directory --project-name $pagesProjectName --branch $pagesBranch

  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  Write-Host "Web publicada em: $pagesUrl"
}

switch ($Target) {
  'web' {
    Invoke-CheckedCommand (Join-Path $PSScriptRoot 'run-flutter.ps1') `
      build web --release "--dart-define=RANKING_API_URL=$rankingApiUrl"

    $source = Join-Path $projectRoot 'build\web'
    & $syncPublicFilesScript -Destination $source
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }

    $destination = Join-Path $releaseRoot 'web'
    Copy-DirectoryContents -Source $source -Destination $destination
    Write-Host "Web copiada para: $destination"
    Publish-WebRelease -Directory $destination
  }
  'aab' {
    $aabFlutterArgs = @(
      '--target-platform=android-arm64,android-x64',
      "--dart-define=RANKING_API_URL=$rankingApiUrl",
      '--dart-define=ADS_ENABLED=true',
      "--dart-define=ADMOB_ANDROID_BANNER_ID=$bannerAdUnitId",
      "--dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=$interstitialAdUnitId"
    )

    & (Join-Path $PSScriptRoot 'build-aab.ps1') -FlutterArgs $aabFlutterArgs
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }

    $source = Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab'
    if (-not (Test-Path -LiteralPath $source)) {
      throw "AAB nao encontrado: $source"
    }

    $destinationDir = Join-Path $releaseRoot 'android'
    Reset-ReleaseDirectory -Path $destinationDir
    $destination = Join-Path $destinationDir 'entreletras-playstore-pc.aab'
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Host "AAB copiado para: $destination"
  }
  'exe' {
    Invoke-CheckedCommand (Join-Path $PSScriptRoot 'run-flutter.ps1') `
      build windows --release "--dart-define=RANKING_API_URL=$rankingApiUrl"

    $source = Join-Path $projectRoot 'build\windows\x64\runner\Release'
    $destination = Join-Path $releaseRoot 'windows\Entreletras-Windows'
    Copy-DirectoryContents -Source $source -Destination $destination
    Write-Host "Windows copiado para: $destination"
  }
}
