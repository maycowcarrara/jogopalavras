param(
  [string]$SourceDir = "assets/audio",
  [string]$OutputDir = "assets/audio-compressed",
  [string]$Bitrate = "96k",
  [int]$Channels = 2,
  [switch]$InPlace
)

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourcePath = Resolve-Path (Join-Path $projectRoot $SourceDir)
$outputPath = Join-Path $projectRoot $OutputDir
$backupPath = Join-Path $projectRoot "assets/audio-original"
$localFfmpeg = Join-Path $projectRoot "node_modules/ffmpeg-static/ffmpeg.exe"

$ErrorActionPreference = "Stop"

$ffmpeg = if (Test-Path $localFfmpeg) {
  $localFfmpeg
} else {
  $command = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($command) {
    $command.Source
  } else {
    throw "ffmpeg was not found. Run npm install first or install ffmpeg in PATH."
  }
}

if ($InPlace) {
  New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
} else {
  New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
}

$files = Get-ChildItem -Path $sourcePath -Filter "*.mp3" -File

if ($files.Count -eq 0) {
  Write-Host "No MP3 files found in $sourcePath."
  exit 0
}

$totalBefore = 0
$totalAfter = 0

foreach ($file in $files) {
  $target = if ($InPlace) {
    Join-Path $env:TEMP ("jogopalavras-" + $file.BaseName + "-compressed.mp3")
  } else {
    Join-Path $outputPath $file.Name
  }

  & $ffmpeg -y -hide_banner -loglevel error -i $file.FullName -vn -map_metadata 0 -ac $Channels -ar 44100 -b:a $Bitrate $target

  if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg failed while compressing $($file.Name)."
  }

  $compressed = Get-Item $target

  if ($InPlace) {
    $backupFile = Join-Path $backupPath $file.Name
    if (-not (Test-Path $backupFile)) {
      Copy-Item -LiteralPath $file.FullName -Destination $backupFile
    }

    Move-Item -Force -LiteralPath $compressed.FullName -Destination $file.FullName
    $compressed = Get-Item $file.FullName
  }

  $totalBefore += $file.Length
  $totalAfter += $compressed.Length

  $beforeMb = [math]::Round($file.Length / 1MB, 2)
  $afterMb = [math]::Round($compressed.Length / 1MB, 2)
  Write-Host "$($file.Name): $beforeMb MB -> $afterMb MB"
}

$beforeTotalMb = [math]::Round($totalBefore / 1MB, 2)
$afterTotalMb = [math]::Round($totalAfter / 1MB, 2)
$savedPercent = [math]::Round((1 - ($totalAfter / $totalBefore)) * 100, 1)

Write-Host "Total: $beforeTotalMb MB -> $afterTotalMb MB ($savedPercent% smaller)"

if ($InPlace) {
  Write-Host "Original files were backed up to $backupPath."
} else {
  Write-Host "Compressed files were written to $outputPath."
}
