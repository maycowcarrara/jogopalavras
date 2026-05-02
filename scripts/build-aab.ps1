param(
  [ValidateSet('build', 'patch', 'minor', 'major')]
  [string]$VersionPart = 'build',
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'bump-version.ps1') -Part $VersionPart

$argsForFlutter = @('build', 'appbundle', '--release')
if ($FlutterArgs) {
  $argsForFlutter += $FlutterArgs
}

& (Join-Path $PSScriptRoot 'run-flutter.ps1') @argsForFlutter
exit $LASTEXITCODE
