Add-Type -AssemblyName System.Drawing

$width = 512
$height = 512
$cleanBmp = New-Object System.Drawing.Bitmap($width, $height)
$gfx = [System.Drawing.Graphics]::FromImage($cleanBmp)
$gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Background: Ground soil / suburban terrain
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(115, 110, 95))
$gfx.FillRectangle($bgBrush, 0, 0, $width, $height)

$rand = New-Object System.Random(42)

# 1. Subtle terrain texture variations
for ($i = 0; $i -lt 1500; $i++) {
    $tx = $rand.Next(0, $width)
    $ty = $rand.Next(0, $height)
    $tw = $rand.Next(10, 60)
    $th = $rand.Next(10, 60)
    $shade = $rand.Next(100, 130)
    $tBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(25, $shade, $shade - 10, $shade - 25))
    $gfx.FillEllipse($tBrush, $tx, $ty, $tw, $th)
    $tBrush.Dispose()
}

# 2. Water Body (Meandering River along left and bottom left edge)
$waterPoints = @(
    (New-Object System.Drawing.Point(0, 0)),
    (New-Object System.Drawing.Point(60, 0)),
    (New-Object System.Drawing.Point(75, 80)),
    (New-Object System.Drawing.Point(50, 160)),
    (New-Object System.Drawing.Point(85, 260)),
    (New-Object System.Drawing.Point(110, 340)),
    (New-Object System.Drawing.Point(90, 420)),
    (New-Object System.Drawing.Point(140, 512)),
    (New-Object System.Drawing.Point(0, 512))
)
$waterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28, 48, 72))
$gfx.FillPolygon($waterBrush, $waterPoints)

# Second small lake / reservoir near top right
$lakeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(24, 42, 65))
$gfx.FillEllipse($lakeBrush, 390, 40, 90, 65)
$lakeBrush.Dispose()

# 3. Dense Urban Street Grid
$roadPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 92, 95), 5)
$subRoadPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(105, 107, 110), 3)

# Horizontal avenues
for ($y = 60; $y -lt $height; $y += 50) {
    $gfx.DrawLine($roadPen, 60, $y, $width, $y)
}
# Vertical boulevards
for ($x = 120; $x -lt $width; $x += 55) {
    $gfx.DrawLine($roadPen, $x, 0, $x, $height)
}
# Diagonal highway
$hwPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(75, 78, 82), 7)
$gfx.DrawLine($hwPen, 80, 450, 480, 70)
$hwPen.Dispose()

# Minor streets
for ($y = 85; $y -lt $height - 40; $y += 50) {
    $gfx.DrawLine($subRoadPen, 100, $y, $width - 20, $y)
}
for ($x = 145; $x -lt $width - 20; $x += 55) {
    $gfx.DrawLine($subRoadPen, $x, 30, $x, $height - 30)
}

# 4. Vegetated Parks & Green Zones
$parkBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(38, 105, 42))
$parkBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 125, 48))
$parkBrush3 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 140, 55))

# City park 1 (Central-West)
$gfx.FillRectangle($parkBrush1, 130, 170, 95, 70)
# City park 2 (North-East)
$gfx.FillEllipse($parkBrush2, 330, 70, 70, 60)
# Riverside green belt
$gfx.FillRectangle($parkBrush3, 75, 270, 35, 130)
# South park
$gfx.FillRectangle($parkBrush2, 290, 370, 100, 70)

# Scattered tree clusters in urban blocks
for ($i = 0; $i -lt 120; $i++) {
    $gx = $rand.Next(120, $width - 20)
    $gy = $rand.Next(30, $height - 30)
    $gw = $rand.Next(6, 16)
    $gh = $rand.Next(6, 16)
    $gShade = $rand.Next(80, 140)
    $gBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, $gShade, 35))
    $gfx.FillEllipse($gBrush, $gx, $gy, $gw, $gh)
    $gBrush.Dispose()
}

# 5. Dense Urban Core & High-Rise Buildings
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 36, 40))

# Rooftop colors
$bldgColors = @(
    [System.Drawing.Color]::FromArgb(215, 218, 222), # bright concrete
    [System.Drawing.Color]::FromArgb(195, 198, 202), # gray roof
    [System.Drawing.Color]::FromArgb(175, 180, 188), # weathered flat roof
    [System.Drawing.Color]::FromArgb(168, 115, 98),  # clay tile roof
    [System.Drawing.Color]::FromArgb(145, 175, 195), # commercial glass/metal
    [System.Drawing.Color]::FromArgb(225, 225, 230), # white commercial rooftop
    [System.Drawing.Color]::FromArgb(135, 138, 142)  # dark gravel roof
)

# Populate blocks with buildings
for ($bx = 125; $bx -lt $width - 40; $bx += 55) {
    for ($by = 65; $by -lt $height - 40; $by += 50) {
        # Skip main park areas
        if (($bx -ge 125 -and $bx -le 210 -and $by -ge 160 -and $by -le 230) -or
            ($bx -ge 280 -and $bx -le 380 -and $by -ge 360 -and $by -le 430)) {
            continue
        }

        # Sub-divide block into 2-4 buildings
        $numB = $rand.Next(2, 5)
        for ($k = 0; $k -lt $numB; $k++) {
            $bw = $rand.Next(14, 24)
            $bh = $rand.Next(12, 20)
            $offX = $rand.Next(2, 26)
            $offY = $rand.Next(2, 24)
            $posX = $bx + $offX
            $posY = $by + $offY

            if ($posX + $bw -lt $bx + 50 -and $posY + $bh -lt $by + 45) {
                # Building shadow (offset by 4, 4 pixels to simulate sun angle)
                $gfx.FillRectangle($shadowBrush, $posX + 4, $posY + 4, $bw, $bh)
                # Building roof
                $c = $bldgColors[$rand.Next(0, $bldgColors.Length)]
                $bBrush = New-Object System.Drawing.SolidBrush($c)
                $gfx.FillRectangle($bBrush, $posX, $posY, $bw, $bh)
                $bBrush.Dispose()

                # Roof detail (HVAC / small structure)
                if ($bw -gt 18) {
                    $hvacBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 240, 245))
                    $gfx.FillRectangle($hvacBrush, $posX + 3, $posY + 3, 5, 4)
                    $hvacBrush.Dispose()
                }
            }
        }
    }
}

# Dispose Graphics objects
$gfx.Dispose()
$bgBrush.Dispose()
$waterBrush.Dispose()
$roadPen.Dispose()
$subRoadPen.Dispose()
$parkBrush1.Dispose()
$parkBrush2.Dispose()
$parkBrush3.Dispose()
$shadowBrush.Dispose()

# Save Clean Reference Image
$cleanPath = "data\satellite_clean.png"
$cleanBmp.Save($cleanPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Create Noisy / Realistic Satellite Image (satellite.jpg)
# Adds slight sensor impulse & Gaussian atmospheric noise
$noisyBmp = New-Object System.Drawing.Bitmap($cleanBmp)
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $p = $cleanBmp.GetPixel($x, $y)
        $r = $p.R
        $g = $p.G
        $b = $p.B

        # 0.6% salt & pepper impulse noise
        $noiseRoll = $rand.NextDouble()
        if ($noiseRoll -lt 0.003) {
            # Salt
            $r = 255; $g = 255; $b = 255
        } elseif ($noiseRoll -lt 0.006) {
            # Pepper
            $r = 0; $g = 0; $b = 0
        } else {
            # Gaussian sensor noise +/- 4
            $gn = $rand.Next(-5, 6)
            $r = [Math]::Max(0, [Math]::Min(255, $r + $gn))
            $g = [Math]::Max(0, [Math]::Min(255, $g + $gn))
            $b = [Math]::Max(0, [Math]::Min(255, $b + $gn))
        }

        $noisyBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($r, $g, $b))
    }
}

$satJpgPath = "data\satellite.jpg"
$noisyBmp.Save($satJpgPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Also duplicate to workspace root and matlab/ directory so imread('satellite.jpg') works directly
$noisyBmp.Save("satellite.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
$noisyBmp.Save("matlab\satellite.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
$cleanBmp.Save("matlab\satellite_clean.png", [System.Drawing.Imaging.ImageFormat]::Png)

$cleanBmp.Dispose()
$noisyBmp.Dispose()

Write-Host "Successfully generated satellite.jpg and satellite_clean.png"

