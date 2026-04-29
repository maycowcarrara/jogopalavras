param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'bump-version.ps1')

$argsForFlutter = @('build', 'appbundle', '--release')
if ($FlutterArgs) {
  $argsForFlutter += $FlutterArgs
}

& (Join-Path $PSScriptRoot 'run-flutter.ps1') @argsForFlutter
exit $LASTEXITCODE
