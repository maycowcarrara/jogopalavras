param(
  [ValidateSet('build', 'patch', 'minor', 'major')]
  [string]$Part = 'build',
  [string]$PubspecPath = (Join-Path $PSScriptRoot '..\pubspec.yaml')
)

$ErrorActionPreference = 'Stop'

$resolvedPubspec = Resolve-Path -LiteralPath $PubspecPath
$content = Get-Content -LiteralPath $resolvedPubspec -Raw
$versionPattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$match = [regex]::Match($content, $versionPattern)

if (-not $match.Success) {
  Write-Error "Nao encontrei uma linha 'version: x.y.z+n' em '$resolvedPubspec'."
  exit 1
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value
$build = [int]$match.Groups[4].Value

switch ($Part) {
  'major' {
    $major += 1
    $minor = 0
    $patch = 0
  }
  'minor' {
    $minor += 1
    $patch = 0
  }
  'patch' {
    $patch += 1
  }
}

$build += 1
$newVersion = "$major.$minor.$patch+$build"

$updatedContent = [regex]::Replace(
  $content,
  $versionPattern,
  "version: $newVersion",
  1
)

Set-Content -LiteralPath $resolvedPubspec -Value $updatedContent -NoNewline
Write-Host "Versao do app atualizada: $newVersion"
Write-Host "Android versionCode incrementado para $build; e isso que a Play Store usa para liberar in-app update."
