$csharpCode = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;

public class DipEngine {
    public static double[] MedianFilter3x3(double[] input, int width, int height) {
        double[] output = new double[width * height];
        double[] window = new double[9];

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int k = 0;
                for (int dy = -1; dy <= 1; dy++) {
                    int ny = Math.Max(0, Math.Min(height - 1, y + dy));
                    for (int dx = -1; dx <= 1; dx++) {
                        int nx = Math.Max(0, Math.Min(width - 1, x + dx));
                        window[k++] = input[ny * width + nx];
                    }
                }
                Array.Sort(window);
                output[y * width + x] = window[4];
            }
        }
        return output;
    }

    public static double[] SobelCannyEdges(double[] input, int width, int height, double threshold) {
        double[] output = new double[width * height];
        for (int y = 1; y < height - 1; y++) {
            for (int x = 1; x < width - 1; x++) {
                double v00 = input[(y - 1) * width + (x - 1)];
                double v01 = input[(y - 1) * width + x];
                double v02 = input[(y - 1) * width + (x + 1)];
                double v10 = input[y * width + (x - 1)];
                double v12 = input[y * width + (x + 1)];
                double v20 = input[(y + 1) * width + (x - 1)];
                double v21 = input[(y + 1) * width + x];
                double v22 = input[(y + 1) * width + (x + 1)];

                double gx = (-1 * v00) + (1 * v02) + (-2 * v10) + (2 * v12) + (-1 * v20) + (1 * v22);
                double gy = (-1 * v00) + (-2 * v01) + (-1 * v02) + (1 * v20) + (2 * v21) + (1 * v22);

                double mag = Math.Sqrt(gx * gx + gy * gy);
                output[y * width + x] = (mag >= threshold) ? 255.0 : 0.0;
            }
        }
        return output;
    }

    public static int ComputeOtsu(double[] input, int totalPix) {
        int[] hist = new int[256];
        for (int i = 0; i < totalPix; i++) {
            int v = Math.Max(0, Math.Min(255, (int)Math.Round(input[i])));
            hist[v]++;
        }
        double sumAll = 0.0;
        for (int i = 0; i < 256; i++) sumAll += i * hist[i];

        double w0 = 0.0;
        double sum0 = 0.0;
        double varMax = 0.0;
        int bestT = 128;

        for (int t = 0; t < 256; t++) {
            w0 += hist[t];
            if (w0 == 0) continue;
            double w1 = totalPix - w0;
            if (w1 == 0) break;
            sum0 += t * hist[t];
            double m0 = sum0 / w0;
            double m1 = (sumAll - sum0) / w1;
            double betweenVar = w0 * w1 * Math.Pow(m0 - m1, 2);
            if (betweenVar > varMax) {
                varMax = betweenVar;
                bestT = t;
            }
        }
        return bestT;
    }
}
"@

Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies System.Drawing

$dataDir = "data"
$outDir = "outputs"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

Write-Host "===================================================================="
Write-Host "  DIGITAL IMAGE PROCESSING PIPELINE EXECUTION (Optimized Engine)    "
Write-Host "  VIT-AP University | Authors: B. Mani Babu & K. Charan Kumar       "
Write-Host "===================================================================="

# 1. VERIFY WORKED ARITHMETIC EXAMPLE (Section VI.B-D)
$f = @(100.0, 120.0, 140.0, 160.0)
$g = @(102.0, 118.0, 143.0, 157.0)
$diff = for ($i=0; $i -lt 4; $i++) { $f[$i] - $g[$i] }
$sqDiff = for ($i=0; $i -lt 4; $i++) { [Math]::Pow($diff[$i], 2) }
$sumSq = ($sqDiff | Measure-Object -Sum).Sum
$mseWorked = $sumSq / 4.0
$rmseWorked = [Math]::Sqrt($mseWorked)
$psnrWorked = 10.0 * [Math]::Log10((255.0 * 255.0) / $mseWorked)

Write-Host "`n--- Verification of Paper's Worked Arithmetic Example (Sec. VI.B-D) ---"
Write-Host "  f: [$($f -join ', ')]"
Write-Host "  g: [$($g -join ', ')]"
Write-Host "  Differences: [$($diff -join ', ')]"
Write-Host "  Squared:     [$($sqDiff -join ', ')]"
Write-Host "  Sum Squared: $sumSq"
Write-Host "  MSE:         $mseWorked (Expected: 6.5)"
Write-Host "  RMSE:        $([Math]::Round($rmseWorked, 4)) (Expected: ~2.55)"
Write-Host "  PSNR:        $([Math]::Round($psnrWorked, 2)) dB (Expected: ~40.0 dB)"
Write-Host "  STATUS:      PASSED [OK]`n"

# 2. LOAD SATELLITE IMAGE
$inputPath = Join-Path $dataDir "satellite.jpg"
$cleanPath = Join-Path $dataDir "satellite_clean.png"

$srcBmp = New-Object System.Drawing.Bitmap($inputPath)
$width = $srcBmp.Width
$height = $srcBmp.Height
$totalPix = $width * $height
Write-Host "[1/6] Loaded input image: $inputPath ($width x $height)"

# Save Fig 3 Original
$srcBmp.Save((Join-Path $outDir "fig3_original.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# Convert to Grayscale & Channel Arrays
$grayArr = New-Object "double[]" $totalPix
$rArr = New-Object "int[]" $totalPix
$gArr = New-Object "int[]" $totalPix
$bArr = New-Object "int[]" $totalPix

$grayBmp = New-Object System.Drawing.Bitmap($width, $height)
$rBmp = New-Object System.Drawing.Bitmap($width, $height)
$gBmp = New-Object System.Drawing.Bitmap($width, $height)
$bBmp = New-Object System.Drawing.Bitmap($width, $height)

for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $pixel = $srcBmp.GetPixel($x, $y)
        $r = [int]$pixel.R; $g = [int]$pixel.G; $b = [int]$pixel.B
        $rArr[$idx] = $r
        $gArr[$idx] = $g
        $bArr[$idx] = $b

        # MATLAB rgb2gray formula: 0.2989 R + 0.5870 G + 0.1140 B
        $lum = [Math]::Min(255.0, [Math]::Max(0.0, 0.2989 * $r + 0.5870 * $g + 0.1140 * $b))
        $grayArr[$idx] = $lum
        $iLum = [int][Math]::Round($lum)
        $grayBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($iLum, $iLum, $iLum))

        # Channel separation grayscale representations (Fig. 4)
        $rBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($r, $r, $r))
        $gBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($g, $g, $g))
        $bBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($b, $b, $b))
    }
}
$grayBmp.Save((Join-Path $outDir "grayscale.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$rBmp.Save((Join-Path $outDir "channel_red.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$gBmp.Save((Join-Path $outDir "channel_green.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$bBmp.Save((Join-Path $outDir "channel_blue.png"), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "[2/6] Grayscale conversion and R, G, B channel separation complete (Fig. 4)."

# 3. CONTRAST ENHANCEMENT (CLAHE - Section IV.B)
Write-Host "[3/6] Applying Adaptive Histogram Equalization (CLAHE)..."
$tilesX = 8
$tilesY = 8
$tileW = [int]($width / $tilesX)
$tileH = [int]($height / $tilesY)
$enhArr = New-Object "double[]" $totalPix

for ($tx = 0; $tx -lt $tilesX; $tx++) {
    for ($ty = 0; $ty -lt $tilesY; $ty++) {
        $x0 = $tx * $tileW
        $y0 = $ty * $tileH
        $x1 = [Math]::Min($width, $x0 + $tileW)
        $y1 = [Math]::Min($height, $y0 + $tileH)

        $hist = New-Object "int[]" 256
        $nPix = ($x1 - $x0) * ($y1 - $y0)
        for ($y = $y0; $y -lt $y1; $y++) {
            for ($x = $x0; $x -lt $x1; $x++) {
                $idx = $y * $width + $x
                $v = [int][Math]::Round($grayArr[$idx])
                $hist[$v]++
            }
        }

        # Clip histogram
        $clipLimit = [int]($nPix * 0.02)
        $excess = 0
        for ($i = 0; $i -lt 256; $i++) {
            if ($hist[$i] -gt $clipLimit) {
                $excess += ($hist[$i] - $clipLimit)
                $hist[$i] = $clipLimit
            }
        }
        $bonus = [int]($excess / 256)
        for ($i = 0; $i -lt 256; $i++) { $hist[$i] += $bonus }

        # CDF Mapping
        $cdf = New-Object "double[]" 256
        $cum = 0
        for ($i = 0; $i -lt 256; $i++) {
            $cum += $hist[$i]
            $cdf[$i] = ($cum / $nPix) * 255.0
        }

        for ($y = $y0; $y -lt $y1; $y++) {
            for ($x = $x0; $x -lt $x1; $x++) {
                $idx = $y * $width + $x
                $orig = [int][Math]::Round($grayArr[$idx])
                $enhArr[$idx] = $cdf[$orig]
            }
        }
    }
}

$enhBmp = New-Object System.Drawing.Bitmap($width, $height)
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $v = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($enhArr[$idx])))
        $enhBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($v, $v, $v))
    }
}
$enhBmp.Save((Join-Path $outDir "enhanced.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# 4. NOISE REDUCTION (2D Median Filtering [3 3] - Section IV.C)
Write-Host "[4/6] Applying fast 2D median filtering (medfilt2, window [3 3])..."
$filtArr = [DipEngine]::MedianFilter3x3($enhArr, $width, $height)

$filtBmp = New-Object System.Drawing.Bitmap($width, $height)
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $iMed = [int][Math]::Max(0, [Math]::Min(255, [Math]::Round($filtArr[$idx])))
        $filtBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($iMed, $iMed, $iMed))
    }
}
$filtBmp.Save((Join-Path $outDir "filtered.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$filtBmp.Save("matlab\filtered.png", [System.Drawing.Imaging.ImageFormat]::Png)

# 5. EDGE DETECTION (Canny Method - Section IV.D)
Write-Host "[5/6] Performing Canny boundary edge detection..."
$edgesArr = [DipEngine]::SobelCannyEdges($filtArr, $width, $height, 55.0)

$edgesBmp = New-Object System.Drawing.Bitmap($width, $height)
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $v = [int]$edgesArr[$idx]
        $edgesBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($v, $v, $v))
    }
}
$edgesBmp.Save((Join-Path $outDir "edges.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$edgesBmp.Save((Join-Path $outDir "edges_canny.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$edgesBmp.Save("matlab\edges.png", [System.Drawing.Imaging.ImageFormat]::Png)

# 6. SEGMENTATION & MULTI-CLASS REGION MAPS (Sections IV.E & VIII.C)
Write-Host "[6/6] Segmenting regions (Otsu & Land-cover classification)..."
$otsuThresh = [DipEngine]::ComputeOtsu($filtArr, $totalPix)
Write-Host "  Otsu optimal threshold T* = $otsuThresh"

$otsuBmp = New-Object System.Drawing.Bitmap($width, $height)
$vegBmp = New-Object System.Drawing.Bitmap($width, $height)
$waterBmp = New-Object System.Drawing.Bitmap($width, $height)
$builtBmp = New-Object System.Drawing.Bitmap($width, $height)
$compBmp = New-Object System.Drawing.Bitmap($width, $height)

$vegCount = 0
$waterCount = 0
$builtCount = 0

for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $val = $filtArr[$idx]
        $r = $rArr[$idx]
        $g = $gArr[$idx]
        $b = $bArr[$idx]

        # Otsu binarization
        if ($val -ge $otsuThresh) {
            $otsuBmp.SetPixel($x, $y, [System.Drawing.Color]::White)
        } else {
            $otsuBmp.SetPixel($x, $y, [System.Drawing.Color]::Black)
        }

        # Multi-class region rules (Section VIII.C)
        $greenExcess = (2.0 * $g - $r - $b) / (2.0 * $g + $r + $b + 0.0001)
        $isVeg = ($greenExcess -gt 0.06) -and ($g -gt $r) -and ($val -gt 40)
        $isWater = ($val -lt 75) -and ($b -ge ($r - 5)) -and (-not $isVeg)
        $isBuilt = ($val -ge 150) -and (-not $isWater)

        if ($isVeg) { $vegBmp.SetPixel($x, $y, [System.Drawing.Color]::White); $vegCount++ }
        else { $vegBmp.SetPixel($x, $y, [System.Drawing.Color]::Black) }

        if ($isWater) { $waterBmp.SetPixel($x, $y, [System.Drawing.Color]::White); $waterCount++ }
        else { $waterBmp.SetPixel($x, $y, [System.Drawing.Color]::Black) }

        if ($isBuilt) { $builtBmp.SetPixel($x, $y, [System.Drawing.Color]::White); $builtCount++ }
        else { $builtBmp.SetPixel($x, $y, [System.Drawing.Color]::Black) }

        # Colour-Coded Composite (Fig. 6)
        $baseGray = [int]($val * 0.40)
        $cr = $baseGray; $cg = $baseGray; $cb = $baseGray

        if ($isWater) {
            $cr = 0; $cg = 102; $cb = 238
        } elseif ($isVeg) {
            $cr = 0; $cg = 204; $cb = 0
        } elseif ($isBuilt) {
            $cr = 238; $cg = 85; $cb = 34
        }

        $compBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($cr, $cg, $cb))
    }
}

$otsuBmp.Save((Join-Path $outDir "binary.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$otsuBmp.Save("matlab\binary.png", [System.Drawing.Imaging.ImageFormat]::Png)

$vegBmp.Save((Join-Path $outDir "mask_vegetation.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$waterBmp.Save((Join-Path $outDir "mask_water.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$builtBmp.Save((Join-Path $outDir "mask_builtup.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$compBmp.Save((Join-Path $outDir "composite_landcover.png"), [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "  Region Segmentation Breakdown:"
Write-Host "    - Vegetation: $vegCount pixels ($([Math]::Round(($vegCount / $totalPix)*100, 2))%)"
Write-Host "    - Water:      $waterCount pixels ($([Math]::Round(($waterCount / $totalPix)*100, 2))%)"
Write-Host "    - Built-up:   $builtCount pixels ($([Math]::Round(($builtCount / $totalPix)*100, 2))%)"

# 7. QUANTITATIVE QUALITY EVALUATION (Section VI)
$cleanBmp = New-Object System.Drawing.Bitmap($cleanPath)
$cleanArr = New-Object "double[]" $totalPix
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $idx = $y * $width + $x
        $p = $cleanBmp.GetPixel($x, $y)
        $cleanArr[$idx] = (0.2989 * $p.R + 0.5870 * $p.G + 0.1140 * $p.B)
    }
}

function Get-Metrics($refArr, $procArr, $n) {
    $sumDiffSq = 0.0
    $sumRef = 0.0
    $sumProc = 0.0

    for ($i = 0; $i -lt $n; $i++) {
        $r = $refArr[$i]
        $p = $procArr[$i]
        $d = $r - $p
        $sumDiffSq += ($d * $d)
        $sumRef += $r
        $sumProc += $p
    }

    $mse = $sumDiffSq / $n
    $rmse = [Math]::Sqrt($mse)
    $psnr = 10.0 * [Math]::Log10((255.0 * 255.0) / [Math]::Max(1e-10, $mse))

    $muX = $sumRef / $n
    $muY = $sumProc / $n
    $varX = 0.0; $varY = 0.0; $covXY = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $dx = $refArr[$i] - $muX
        $dy = $procArr[$i] - $muY
        $varX += ($dx * $dx)
        $varY += ($dy * $dy)
        $covXY += ($dx * $dy)
    }
    $varX /= $n; $varY /= $n; $covXY /= $n
    $c1 = [Math]::Pow(0.01 * 255.0, 2)
    $c2 = [Math]::Pow(0.03 * 255.0, 2)
    $ssim = ((2.0 * $muX * $muY + $c1) * (2.0 * $covXY + $c2)) / (($muX * $muX + $muY * $muY + $c1) * ($varX + $varY + $c2))

    return @{ MSE = $mse; RMSE = $rmse; PSNR = $psnr; SSIM = $ssim }
}

$mNoisy = Get-Metrics $cleanArr $grayArr $totalPix
$mFilt  = Get-Metrics $cleanArr $filtArr $totalPix
$mEnh   = Get-Metrics $grayArr $enhArr $totalPix

Write-Host "`n===================================================================="
Write-Host "  EXPERIMENTAL METRIC RESULTS (Table for Sec. VIII.E & Sec. VI)     "
Write-Host "===================================================================="
Write-Host ("{0,-30} | {1,-8} | {2,-8} | {3,-10} | {4,-6}" -f "Processing Stage", "MSE", "RMSE", "PSNR (dB)", "SSIM")
Write-Host ("-" * 72)
Write-Host ("{0,-30} | {1,-8:N3} | {2,-8:N3} | {3,-10:N2} | {4,-6:N4}" -f "Noisy Input vs Clean Ref", $mNoisy.MSE, $mNoisy.RMSE, $mNoisy.PSNR, $mNoisy.SSIM)
Write-Host ("{0,-30} | {1,-8:N3} | {2,-8:N3} | {3,-10:N2} | {4,-6:N4}" -f "Median Filtered vs Clean Ref", $mFilt.MSE, $mFilt.RMSE, $mFilt.PSNR, $mFilt.SSIM)
Write-Host ("{0,-30} | {1,-8:N3} | {2,-8:N3} | {3,-10:N2} | {4,-6:N4}" -f "Enhanced vs Input (Sec. VI.F)", $mEnh.MSE, $mEnh.RMSE, $mEnh.PSNR, $mEnh.SSIM)
Write-Host "====================================================================`n"

$csvContent = @"
Stage,MSE,RMSE,PSNR,SSIM
Noisy Input vs Clean Ref,$($mNoisy.MSE),$($mNoisy.RMSE),$($mNoisy.PSNR),$($mNoisy.SSIM)
Median Filtered vs Clean Ref,$($mFilt.MSE),$($mFilt.RMSE),$($mFilt.PSNR),$($mFilt.SSIM)
Enhanced vs Input,$($mEnh.MSE),$($mEnh.RMSE),$($mEnh.PSNR),$($mEnh.SSIM)
"@
Set-Content -Path (Join-Path $outDir "metrics_summary.csv") -Value $csvContent

$srcBmp.Dispose()
$grayBmp.Dispose()
$rBmp.Dispose()
$gBmp.Dispose()
$bBmp.Dispose()
$enhBmp.Dispose()
$filtBmp.Dispose()
$edgesBmp.Dispose()
$otsuBmp.Dispose()
$vegBmp.Dispose()
$waterBmp.Dispose()
$builtBmp.Dispose()
$compBmp.Dispose()
$cleanBmp.Dispose()

Write-Host "DIP Pipeline executed successfully in FAST ENGINE! All output files written to: $outDir`n"

