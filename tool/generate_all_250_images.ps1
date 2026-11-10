Add-Type -AssemblyName System.Drawing

$manifestJson = Get-Content -Raw -Path "assets/puzzles_manifest.json" | ConvertFrom-Json
$targetWidth = 750
$targetHeight = 500

# Color palette generators per category
$palettes = @{
    "animals" = @(
        @([System.Drawing.Color]::FromArgb(255, 255, 182, 193), [System.Drawing.Color]::FromArgb(255, 255, 240, 245), [System.Drawing.Color]::FromArgb(255, 255, 105, 180)),
        @([System.Drawing.Color]::FromArgb(255, 255, 228, 196), [System.Drawing.Color]::FromArgb(255, 255, 250, 205), [System.Drawing.Color]::FromArgb(255, 244, 164, 96)),
        @([System.Drawing.Color]::FromArgb(255, 176, 224, 230), [System.Drawing.Color]::FromArgb(255, 240, 248, 255), [System.Drawing.Color]::FromArgb(255, 70, 130, 180)),
        @([System.Drawing.Color]::FromArgb(255, 221, 160, 221), [System.Drawing.Color]::FromArgb(255, 255, 245, 238), [System.Drawing.Color]::FromArgb(255, 186, 85, 211)),
        @([System.Drawing.Color]::FromArgb(255, 152, 251, 152), [System.Drawing.Color]::FromArgb(255, 245, 255, 250), [System.Drawing.Color]::FromArgb(255, 60, 179, 113))
    )
    "nature" = @(
        @([System.Drawing.Color]::FromArgb(255, 34, 139, 34), [System.Drawing.Color]::FromArgb(255, 144, 238, 144), [System.Drawing.Color]::FromArgb(255, 0, 100, 0)),
        @([System.Drawing.Color]::FromArgb(255, 255, 140, 0), [System.Drawing.Color]::FromArgb(255, 255, 215, 0), [System.Drawing.Color]::FromArgb(255, 205, 92, 92)),
        @([System.Drawing.Color]::FromArgb(255, 25, 25, 112), [System.Drawing.Color]::FromArgb(255, 72, 61, 139), [System.Drawing.Color]::FromArgb(255, 138, 43, 226)),
        @([System.Drawing.Color]::FromArgb(255, 0, 139, 139), [System.Drawing.Color]::FromArgb(255, 175, 238, 238), [System.Drawing.Color]::FromArgb(255, 47, 79, 79)),
        @([System.Drawing.Color]::FromArgb(255, 218, 112, 214), [System.Drawing.Color]::FromArgb(255, 230, 230, 250), [System.Drawing.Color]::FromArgb(255, 128, 0, 128))
    )
    "flowers" = @(
        @([System.Drawing.Color]::FromArgb(255, 255, 105, 180), [System.Drawing.Color]::FromArgb(255, 255, 192, 203), [System.Drawing.Color]::FromArgb(255, 219, 112, 147)),
        @([System.Drawing.Color]::FromArgb(255, 255, 69, 0), [System.Drawing.Color]::FromArgb(255, 255, 165, 0), [System.Drawing.Color]::FromArgb(255, 255, 215, 0)),
        @([System.Drawing.Color]::FromArgb(255, 106, 90, 205), [System.Drawing.Color]::FromArgb(255, 216, 191, 216), [System.Drawing.Color]::FromArgb(255, 75, 0, 130)),
        @([System.Drawing.Color]::FromArgb(255, 255, 20, 147), [System.Drawing.Color]::FromArgb(255, 255, 228, 225), [System.Drawing.Color]::FromArgb(255, 199, 21, 133)),
        @([System.Drawing.Color]::FromArgb(255, 65, 105, 225), [System.Drawing.Color]::FromArgb(255, 176, 196, 222), [System.Drawing.Color]::FromArgb(255, 0, 0, 128))
    )
    "landmarks" = @(
        @([System.Drawing.Color]::FromArgb(255, 205, 133, 63), [System.Drawing.Color]::FromArgb(255, 245, 222, 179), [System.Drawing.Color]::FromArgb(255, 139, 69, 19)),
        @([System.Drawing.Color]::FromArgb(255, 70, 130, 180), [System.Drawing.Color]::FromArgb(255, 240, 248, 255), [System.Drawing.Color]::FromArgb(255, 25, 25, 112)),
        @([System.Drawing.Color]::FromArgb(255, 188, 143, 143), [System.Drawing.Color]::FromArgb(255, 255, 228, 196), [System.Drawing.Color]::FromArgb(255, 139, 0, 0)),
        @([System.Drawing.Color]::FromArgb(255, 32, 178, 170), [System.Drawing.Color]::FromArgb(255, 224, 255, 255), [System.Drawing.Color]::FromArgb(255, 0, 128, 128)),
        @([System.Drawing.Color]::FromArgb(255, 218, 165, 32), [System.Drawing.Color]::FromArgb(255, 255, 250, 205), [System.Drawing.Color]::FromArgb(255, 184, 134, 11))
    )
    "art" = @(
        @([System.Drawing.Color]::FromArgb(255, 220, 20, 60), [System.Drawing.Color]::FromArgb(255, 255, 248, 220), [System.Drawing.Color]::FromArgb(255, 25, 25, 112)),
        @([System.Drawing.Color]::FromArgb(255, 0, 139, 139), [System.Drawing.Color]::FromArgb(255, 255, 215, 0), [System.Drawing.Color]::FromArgb(255, 128, 0, 0)),
        @([System.Drawing.Color]::FromArgb(255, 75, 0, 130), [System.Drawing.Color]::FromArgb(255, 238, 130, 238), [System.Drawing.Color]::FromArgb(255, 255, 20, 147)),
        @([System.Drawing.Color]::FromArgb(255, 46, 139, 87), [System.Drawing.Color]::FromArgb(255, 240, 230, 140), [System.Drawing.Color]::FromArgb(255, 0, 100, 0)),
        @([System.Drawing.Color]::FromArgb(255, 255, 127, 80), [System.Drawing.Color]::FromArgb(255, 173, 216, 230), [System.Drawing.Color]::FromArgb(255, 25, 25, 112))
    )
}

# Setup JPEG encoder with quality 80 for small file size (~30-35KB per image)
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encoderParams = [System.Drawing.Imaging.EncoderParameters]::new(1)
$encoderParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]80)

$processedCount = 0

foreach ($p in $manifestJson) {
    $filePath = $p.path
    $cat = $p.category
    $id = $p.id
    $title = $p.title
    
    $fullPath = Join-Path (Get-Location).Path $filePath
    $dir = Split-Path -Parent $fullPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $existingValid = $false
    # If the file already exists and is non-empty, check if it's an existing real photo/art
    if (Test-Path $fullPath) {
        $len = (Get-Item $fullPath).Length
        if ($len -gt 1000) {
            try {
                $srcImg = [System.Drawing.Image]::FromFile($fullPath)
                $srcW = $srcImg.Width
                $srcH = $srcImg.Height
                
                # If already exact 750x500 and small (< 60KB), keep it
                if ($srcW -eq $targetWidth -and $srcH -eq $targetHeight -and $len -lt 65000) {
                    $srcImg.Dispose()
                    $existingValid = $true
                } else {
                    # Center crop and compress
                    $newBmp = [System.Drawing.Bitmap]::new($targetWidth, $targetHeight)
                    $g = [System.Drawing.Graphics]::FromImage($newBmp)
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

                    $srcAspect = [double]$srcW / [double]$srcH
                    $targetAspect = 3.0 / 2.0

                    if ($srcAspect -gt $targetAspect) {
                        $cropW = [int]($srcH * $targetAspect)
                        $cropH = $srcH
                        $cropX = [int](($srcW - $cropW) / 2)
                        $cropY = 0
                    } else {
                        $cropW = $srcW
                        $cropH = [int]($srcW / $targetAspect)
                        $cropX = 0
                        $cropY = [int](($srcH - $cropH) / 2)
                    }

                    $srcRect = [System.Drawing.Rectangle]::new($cropX, $cropY, $cropW, $cropH)
                    $destRect = [System.Drawing.Rectangle]::new(0, 0, $targetWidth, $targetHeight)
                    $g.DrawImage($srcImg, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

                    $srcImg.Dispose()
                    $g.Dispose()

                    $tempPath = "$fullPath.tmp"
                    $newBmp.Save($tempPath, $jpegCodec, $encoderParams)
                    $newBmp.Dispose()

                    Move-Item -Path $tempPath -Destination $fullPath -Force
                    $existingValid = $true
                }
            } catch {
                $existingValid = $false
            }
        }
    }

    if (-not $existingValid) {
        # Generate a high-end 3:2 landscape aesthetic wallpaper
        $num = [int]($id -replace '[^0-9]', '')
        $palList = $palettes[$cat]
        $palIndex = ($num - 1) % $palList.Count
        $c1 = $palList[$palIndex][0]
        $c2 = $palList[$palIndex][1]
        $c3 = $palList[$palIndex][2]

        $bmp = [System.Drawing.Bitmap]::new($targetWidth, $targetHeight)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

        # 1. Base Gradient Background (Diagonal)
        $rect = [System.Drawing.Rectangle]::new(0, 0, $targetWidth, $targetHeight)
        $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, $c1, $c2, 35.0)
        $g.FillRectangle($brush, $rect)
        $brush.Dispose()

        # 2. Ambient Glowing Orbs
        $orbBrush1 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(45, $c3.R, $c3.G, $c3.B))
        $g.FillEllipse($orbBrush1, -60, -60, 420, 320)
        $g.FillEllipse($orbBrush1, 460, 240, 420, 320)
        $orbBrush1.Dispose()

        # 3. Soft Horizontal Horizon Bars for landscape depth
        $horizonBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(40, [System.Drawing.Color]::White))
        $g.FillRectangle($horizonBrush, 0, 260, $targetWidth, 120)
        $horizonBrush.Dispose()

        $groundBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 15, 30, 50))
        $g.FillRectangle($groundBrush, 0, 360, $targetWidth, 140)
        $groundBrush.Dispose()

        # 4. Sun/Moon Glow
        $sunBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(160, 255, 255, 240))
        $g.FillEllipse($sunBrush, 530, 60, 100, 100)
        $sunBrush.Dispose()

        # 5. Center Card Badge (Frosted glass diorama aesthetic)
        $cardW = 440
        $cardH = 130
        $cardX = [int](($targetWidth - $cardW) / 2)
        $cardY = [int](($targetHeight - $cardH) / 2 - 20)
        $cardRect = [System.Drawing.Rectangle]::new($cardX, $cardY, $cardW, $cardH)

        $glassBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(165, 12, 22, 38))
        $g.FillRectangle($glassBrush, $cardRect)
        $glassBrush.Dispose()

        $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.5)
        $g.DrawRectangle($borderPen, $cardRect)
        $borderPen.Dispose()

        # 6. Category Tag and Title Typography
        $catFont = [System.Drawing.Font]::new("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $catBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 193, 7))
        $g.DrawString($cat.ToUpper(), $catFont, $catBrush, ($cardX + 22), ($cardY + 16))
        $catFont.Dispose()
        $catBrush.Dispose()

        $titleFont = [System.Drawing.Font]::new("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
        $titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $strFormat = [System.Drawing.StringFormat]::new()
        $strFormat.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
        $titleRect = [System.Drawing.RectangleF]::new(($cardX + 22), ($cardY + 46), ($cardW - 44), 65)
        $g.DrawString($title, $titleFont, $titleBrush, $titleRect, $strFormat)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        $strFormat.Dispose()

        # 7. Subtle Corner Vignette & Border
        $outerBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 2)
        $g.DrawRectangle($outerBorder, 1, 1, ($targetWidth - 3), ($targetHeight - 3))
        $outerBorder.Dispose()

        $g.Dispose()

        $bmp.Save($fullPath, $jpegCodec, $encoderParams)
        $bmp.Dispose()
    }

    $processedCount++
}

Write-Host "SUCCESS: Processed all $processedCount images in 3:2 aspect ratio!"
