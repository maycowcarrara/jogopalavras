param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Add-Type -AssemblyName System.Drawing

$brandingDir = Join-Path $Root 'assets\branding'
$playstoreDir = Join-Path $Root 'assets\playstore'
New-Item -ItemType Directory -Force -Path $brandingDir, $playstoreDir | Out-Null

function New-Canvas([int]$w, [int]$h, [bool]$transparent = $false) {
  $bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  if ($transparent) {
    $g.Clear([System.Drawing.Color]::Transparent)
  } else {
    $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#F3EFE5'))
  }
  return @{ Bitmap = $bmp; Graphics = $g }
}

function New-RoundRectPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Fill-RoundRect($g, [string]$color, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($color))
  $path = New-RoundRectPath $x $y $w $h $r
  $g.FillPath($brush, $path)
  $path.Dispose()
  $brush.Dispose()
}

function Stroke-RoundRect($g, [string]$color, [float]$width, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($color), $width)
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $path = New-RoundRectPath $x $y $w $h $r
  $g.DrawPath($pen, $path)
  $path.Dispose()
  $pen.Dispose()
}

function Draw-CenteredText($g, [string]$text, [string]$fontName, [float]$size, [int]$style, [string]$color, [float]$x, [float]$y, [float]$w, [float]$h) {
  $font = [System.Drawing.Font]::new($fontName, $size, [System.Drawing.FontStyle]$style, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($color))
  $fmt = [System.Drawing.StringFormat]::new()
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $fmt)
  $fmt.Dispose()
  $brush.Dispose()
  $font.Dispose()
}

function Draw-IconMark($g, [float]$scale, [float]$ox, [float]$oy, [bool]$mono = $false) {
  $ink = if ($mono) { '#111111' } else { '#171717' }
  $red = if ($mono) { '#111111' } else { '#B62F31' }
  $blue = if ($mono) { '#111111' } else { '#28546A' }
  $gold = if ($mono) { '#111111' } else { '#D0A245' }
  $paper = if ($mono) { '#111111' } else { '#FFFCF4' }
  $line = if ($mono) { '#111111' } else { '#BFB7A8' }

  Fill-RoundRect $g '#171717' ($ox + 142*$scale) ($oy + 132*$scale) (740*$scale) (760*$scale) (74*$scale)
  Fill-RoundRect $g $paper ($ox + 122*$scale) ($oy + 110*$scale) (740*$scale) (760*$scale) (74*$scale)
  Stroke-RoundRect $g $ink (18*$scale) ($ox + 122*$scale) ($oy + 110*$scale) (740*$scale) (760*$scale) (74*$scale)

  Fill-RoundRect $g $red ($ox + 122*$scale) ($oy + 110*$scale) (740*$scale) (132*$scale) (42*$scale)
  $clip = New-RoundRectPath ($ox + 122*$scale) ($oy + 110*$scale) (740*$scale) (760*$scale) (74*$scale)
  $oldClip = $g.Clip
  $g.SetClip($clip)
  $topBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($red))
  $g.FillRectangle($topBrush, ($ox + 122*$scale), ($oy + 110*$scale), (740*$scale), (132*$scale))
  $topBrush.Dispose()
  $g.Clip = $oldClip
  $oldClip.Dispose()
  $clip.Dispose()

  if (-not $mono) {
    Draw-CenteredText $g 'ENTRELETRAS' 'Georgia' (54*$scale) 1 '#FFFFFF' ($ox + 164*$scale) ($oy + 125*$scale) (656*$scale) (86*$scale)
  }

  $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($line), (9*$scale))
  for ($i = 0; $i -lt 4; $i++) {
    $y = $oy + (322 + $i*68)*$scale
    $g.DrawLine($pen, ($ox + 184*$scale), $y, ($ox + 452*$scale), $y)
    $g.DrawLine($pen, ($ox + 566*$scale), $y, ($ox + 798*$scale), $y)
  }
  for ($i = 0; $i -lt 3; $i++) {
    $y = $oy + (690 + $i*62)*$scale
    $g.DrawLine($pen, ($ox + 202*$scale), $y, ($ox + 418*$scale), $y)
    $g.DrawLine($pen, ($ox + 606*$scale), $y, ($ox + 790*$scale), $y)
  }
  $pen.Dispose()

  $divider = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($line), (10*$scale))
  $g.DrawLine($divider, ($ox + 510*$scale), ($oy + 300*$scale), ($ox + 510*$scale), ($oy + 610*$scale))
  $divider.Dispose()

  Draw-CenteredText $g 'E' 'Georgia' (206*$scale) 1 $ink ($ox + 208*$scale) ($oy + 324*$scale) (260*$scale) (198*$scale)
  Draw-CenteredText $g 'L' 'Georgia' (206*$scale) 1 $red ($ox + 560*$scale) ($oy + 324*$scale) (240*$scale) (198*$scale)

  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddLine(($ox + 294*$scale), ($oy + 648*$scale), ($ox + 294*$scale), ($oy + 610*$scale))
  $path.AddLine(($ox + 294*$scale), ($oy + 610*$scale), ($ox + 730*$scale), ($oy + 610*$scale))
  $path.AddLine(($ox + 730*$scale), ($oy + 610*$scale), ($ox + 730*$scale), ($oy + 648*$scale))
  $route = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($red), (18*$scale))
  $route.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $route.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $route.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawPath($route, $path)
  $route.Dispose()
  $path.Dispose()

  foreach ($dot in @(@($gold, 294, 676), @($blue, 730, 676))) {
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($dot[0]))
    $g.FillEllipse($brush, ($ox + ([float]$dot[1]-25)*$scale), ($oy + ([float]$dot[2]-25)*$scale), (50*$scale), (50*$scale))
    $brush.Dispose()
  }
}

function Save-Png($bmp, [string]$path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-Png([string]$src, [string]$dest, [int]$w, [int]$h) {
  $img = [System.Drawing.Image]::FromFile($src)
  $bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, 0, 0, $w, $h)
  Save-Png $bmp $dest
  $g.Dispose()
  $bmp.Dispose()
  $img.Dispose()
}

$icon = New-Canvas 1024 1024
Draw-IconMark $icon.Graphics 1 0 0 $false
Save-Png $icon.Bitmap (Join-Path $brandingDir 'app_icon.png')
$icon.Graphics.Dispose()
$icon.Bitmap.Dispose()

$foreground = New-Canvas 1024 1024 $true
Draw-IconMark $foreground.Graphics 0.93 35 45 $false
Save-Png $foreground.Bitmap (Join-Path $brandingDir 'app_icon_foreground.png')
$foreground.Graphics.Dispose()
$foreground.Bitmap.Dispose()

$mono = New-Canvas 1024 1024 $true
Draw-IconMark $mono.Graphics 0.93 35 45 $true
Save-Png $mono.Bitmap (Join-Path $brandingDir 'app_icon_monochrome.png')
$mono.Graphics.Dispose()
$mono.Bitmap.Dispose()

Resize-Png (Join-Path $brandingDir 'app_icon.png') (Join-Path $playstoreDir 'entreletras-icon-512.png') 512 512

$feature = New-Canvas 1024 500
$fg = $feature.Graphics
Draw-IconMark $fg 0.42 42 36 $false
Draw-CenteredText $fg 'ENTRELETRAS' 'Georgia' 56 1 '#171717' 410 118 570 100
Draw-CenteredText $fg 'PALAVRAS OCULTAS' 'Arial' 36 1 '#B62F31' 410 232 570 54
$rule = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#D0A245'), 8)
$fg.DrawLine($rule, 456, 322, 918, 322)
$rule.Dispose()
Draw-CenteredText $fg 'desvende letras, forme caminhos' 'Arial' 30 0 '#28546A' 410 342 570 48
Save-Png $feature.Bitmap (Join-Path $playstoreDir 'entreletras-feature-graphic-1024x500.png')
$fg.Dispose()
$feature.Bitmap.Dispose()

Write-Host "Branding assets generated in $brandingDir and $playstoreDir"
