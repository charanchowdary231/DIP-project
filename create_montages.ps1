Add-Type -AssemblyName System.Drawing

$outDir = "outputs"
$fontTitle = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$fontSub = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
$brushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$brushBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(18, 22, 28))

# 1. Fig 4: Channel Separation Montage (3 panels side-by-side: 3 x 380 = 1140, height: 440)
$rImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "channel_red.png"))
$gImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "channel_green.png"))
$bImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "channel_blue.png"))

$fig4Bmp = New-Object System.Drawing.Bitmap(1180, 460)
$gfx4 = [System.Drawing.Graphics]::FromImage($fig4Bmp)
$gfx4.FillRectangle($brushBg, 0, 0, 1180, 460)

$gfx4.DrawImage($rImg, 20, 50, 360, 360)
$gfx4.DrawString("Red Channel (Grayscale)", $fontTitle, $brushWhite, 100, 20)

$gfx4.DrawImage($gImg, 410, 50, 360, 360)
$gfx4.DrawString("Green Channel (Grayscale)", $fontTitle, $brushWhite, 480, 20)

$gfx4.DrawImage($bImg, 800, 50, 360, 360)
$gfx4.DrawString("Blue Channel (Grayscale)", $fontTitle, $brushWhite, 880, 20)

$gfx4.Dispose()
$rImg.Dispose(); $gImg.Dispose(); $bImg.Dispose()
$fig4Bmp.Save((Join-Path $outDir "fig4_channel_separation.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# 2. Fig 5: Binary Threshold-Based Maps Montage (3 panels: Veg, Water, Built-Up)
$vImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "mask_vegetation.png"))
$wImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "mask_water.png"))
$bldImg = [System.Drawing.Image]::FromFile((Join-Path $outDir "mask_builtup.png"))

$fig5Bmp = New-Object System.Drawing.Bitmap(1180, 470)
$gfx5 = [System.Drawing.Graphics]::FromImage($fig5Bmp)
$gfx5.FillRectangle($brushBg, 0, 0, 1180, 470)

$gfx5.DrawImage($vImg, 20, 50, 360, 360)
$gfx5.DrawString("Vegetation Binary Map (Fig. 5 Left)", $fontTitle, $brushWhite, 70, 18)
$gfx5.DrawString("Coverage: 11.88% (31,143 px)", $fontSub, $brushWhite, 120, 420)

$gfx5.DrawImage($wImg, 410, 50, 360, 360)
$gfx5.DrawString("Water Regions Map (Fig. 5 Centre)", $fontTitle, $brushWhite, 460, 18)
$gfx5.DrawString("Coverage: 18.54% (48,612 px)", $fontSub, $brushWhite, 510, 420)

$gfx5.DrawImage($bldImg, 800, 50, 360, 360)
$gfx5.DrawString("Built-Up Regions Map (Fig. 5 Right)", $fontTitle, $brushWhite, 840, 18)
$gfx5.DrawString("Coverage: 28.99% (75,988 px)", $fontSub, $brushWhite, 890, 420)

$gfx5.Dispose()
$vImg.Dispose(); $wImg.Dispose(); $bldImg.Dispose()
$fig5Bmp.Save((Join-Path $outDir "fig5_binary_maps.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# 3. Pipeline Overview (2 rows x 3 cols)
$p1 = [System.Drawing.Image]::FromFile((Join-Path $outDir "fig3_original.png"))
$p2 = [System.Drawing.Image]::FromFile((Join-Path $outDir "grayscale.png"))
$p3 = [System.Drawing.Image]::FromFile((Join-Path $outDir "enhanced.png"))
$p4 = [System.Drawing.Image]::FromFile((Join-Path $outDir "filtered.png"))
$p5 = [System.Drawing.Image]::FromFile((Join-Path $outDir "edges.png"))
$p6 = [System.Drawing.Image]::FromFile((Join-Path $outDir "binary.png"))

$ovBmp = New-Object System.Drawing.Bitmap(1240, 840)
$gfxOv = [System.Drawing.Graphics]::FromImage($ovBmp)
$gfxOv.FillRectangle($brushBg, 0, 0, 1240, 840)

$wPanel = 370; $hPanel = 340

# Row 1
$gfxOv.DrawImage($p1, 25, 45, $wPanel, $hPanel)
$gfxOv.DrawString("1. Original RGB Input Scene", $fontTitle, $brushWhite, 80, 18)

$gfxOv.DrawImage($p2, 435, 45, $wPanel, $hPanel)
$gfxOv.DrawString("2. Grayscale Preprocessed", $fontTitle, $brushWhite, 500, 18)

$gfxOv.DrawImage($p3, 845, 45, $wPanel, $hPanel)
$gfxOv.DrawString("3. CLAHE Contrast Enhanced", $fontTitle, $brushWhite, 900, 18)

# Row 2
$gfxOv.DrawImage($p4, 25, 445, $wPanel, $hPanel)
$gfxOv.DrawString("4. 2D Median Filtered (medfilt2 [3 3])", $fontTitle, $brushWhite, 50, 415)

$gfxOv.DrawImage($p5, 435, 445, $wPanel, $hPanel)
$gfxOv.DrawString("5. Canny Boundary Edge Map", $fontTitle, $brushWhite, 490, 415)

$gfxOv.DrawImage($p6, 845, 445, $wPanel, $hPanel)
$gfxOv.DrawString("6. Otsu Binary Segmentation", $fontTitle, $brushWhite, 910, 415)

$gfxOv.Dispose()
$p1.Dispose(); $p2.Dispose(); $p3.Dispose(); $p4.Dispose(); $p5.Dispose(); $p6.Dispose()
$ovBmp.Save((Join-Path $outDir "pipeline_overview.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$fontTitle.Dispose()
$fontSub.Dispose()
$brushWhite.Dispose()
$brushBg.Dispose()

Write-Host "Created composite figures: fig4_channel_separation.png, fig5_binary_maps.png, pipeline_overview.png"

