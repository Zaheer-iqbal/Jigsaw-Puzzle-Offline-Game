Add-Type -AssemblyName System.Drawing

$brainDir = "C:\Users\Dell\.gemini\antigravity\brain\67231608-7af5-4222-9be6-563748b880c1"
$targetWidth = 750
$targetHeight = 500

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encoderParams = [System.Drawing.Imaging.EncoderParameters]::new(1)
$encoderParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]85)

$catMap = @{
    'a' = 'animals'
    'n' = 'nature'
    'f' = 'flowers'
    'l' = 'landmarks'
    'r' = 'art'
}

$files = Get-ChildItem -Path $brainDir -Filter "*.jpg" | Where-Object {
    $_.Name -match '^([anflr]\d{3})'
}

$syncedCount = 0

foreach ($file in $files) {
    if ($file.Name -match '^([anflr])(\d{3})') {
        $prefix = $Matches[1]
        $id = "$($prefix)$($Matches[2])"
        $category = $catMap[$prefix]
        $destPath = "assets\puzzles\$category\$id.jpg"
        
        $destFull = Join-Path (Get-Location).Path $destPath
        $destDir = Split-Path -Parent $destFull
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        # Check if already synced from this exact brain image
        $marker = "$destFull.src"
        if ((Test-Path $destFull) -and (Test-Path $marker)) {
            $prevSrc = Get-Content -Path $marker -Raw
            if ($prevSrc.Trim() -eq $file.FullName) {
                continue
            }
        }

        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            $bmp = [System.Drawing.Bitmap]::new($targetWidth, $targetHeight)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.DrawImage($img, 0, 0, $targetWidth, $targetHeight)
            $img.Dispose()
            $g.Dispose()

            $tmp = "$destFull.tmp"
            $bmp.Save($tmp, $codec, $encoderParams)
            $bmp.Dispose()
            Move-Item -Path $tmp -Destination $destFull -Force

            Set-Content -Path $marker -Value $file.FullName -Force
            $sizeKB = [math]::Round((Get-Item $destFull).Length / 1KB, 1)
            Write-Host "SYNCED: $destPath ($sizeKB KB from $($file.Name))"
            $syncedCount++
        } catch {
            Write-Warning "Failed to sync $($file.Name): $_"
        }
    }
}

Write-Host "Sync complete. Total newly synced: $syncedCount"
