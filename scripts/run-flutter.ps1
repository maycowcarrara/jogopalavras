param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'

$flutterRoot = if ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { 'C:\Flutter\flutter' }
$flutterBat = Join-Path $flutterRoot 'bin\flutter.bat'
$cacheDir = Join-Path $flutterRoot 'bin\cache'

if (-not (Test-Path -LiteralPath $flutterBat)) {
  Write-Error "Flutter nao encontrado em '$flutterBat'. Ajuste FLUTTER_ROOT ou instale o SDK esperado."
  exit 1
}

if (-not (Test-Path -LiteralPath $cacheDir)) {
  Write-Error "Cache do Flutter nao encontrado em '$cacheDir'."
  exit 1
}

$probe = Join-Path $cacheDir "codex-write-probe-$PID.tmp"
try {
  Set-Content -LiteralPath $probe -Value 'ok' -NoNewline
  Remove-Item -LiteralPath $probe -Force
} catch {
  [Console]::Error.WriteLine(@"
O Flutter precisa escrever em '$cacheDir' antes de iniciar.
Neste ambiente, comandos dart/flutter chamados sem permissao elevada podem ficar presos no lock interno do Flutter.
Execute este comando com permissao elevada no Codex, ou mova o SDK Flutter para uma pasta gravavel pelo workspace.
Erro original: $($_.Exception.Message)
"@
  )
  exit 97
}

& $flutterBat @FlutterArgs
exit $LASTEXITCODE
