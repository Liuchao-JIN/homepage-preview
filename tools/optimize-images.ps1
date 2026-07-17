<#
.SYNOPSIS
  Generate compressed WebP copies of the site's JP/PNG images (P2: image optimization).

.DESCRIPTION
  WebP is typically 25-35% smaller than JPEG/PNG at equivalent quality, which
  meaningfully improves Lighthouse "Performance" and load time — especially for the
  publications page (30+ cover thumbnails).

  This script does NOT overwrite your originals. It writes a `.webp` next to each
  source image. To actually serve them, reference the .webp files (or use a
  <picture> element with a JPG/PNG fallback), e.g.:

      <picture>
        <source srcset="/files/my_essay/jin2024big_cover.webp" type="image/webp">
        <img src="/files/my_essay/jin2024big_cover.jpg" loading="lazy" alt="...">
      </picture>

.PREREQUISITES
  Install ONE of the following and make sure it's on your PATH:
    * ImageMagick   -> https://imagemagick.org/script/download.php  (provides `magick`)
    * libwebp/cwebp -> https://developers.google.com/speed/webp/download  (provides `cwebp`)

.EXAMPLE
  pwsh -File tools/optimize-images.ps1                # process files/ and images/
  pwsh -File tools/optimize-images.ps1 -Quality 80    # custom quality (default 82)
#>

param(
  [string[]]$Folders = @("files", "images"),
  [int]$Quality = 82
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot   # repo root (tools/..)

$magick = Get-Command magick -ErrorAction SilentlyContinue
$cwebp  = Get-Command cwebp  -ErrorAction SilentlyContinue

if (-not $magick -and -not $cwebp) {
  Write-Error "Neither 'magick' (ImageMagick) nor 'cwebp' (libwebp) found on PATH. Install one first — see the header of this script."
  return
}

$converter = if ($magick) { "magick" } else { "cwebp" }
Write-Host "Using converter: $converter  (quality $Quality)" -ForegroundColor Cyan

$count = 0; $savedBytes = 0
foreach ($folder in $Folders) {
  $path = Join-Path $root $folder
  if (-not (Test-Path $path)) { continue }

  Get-ChildItem -Path $path -Recurse -File -Include *.jpg, *.jpeg, *.png | ForEach-Object {
    $src = $_.FullName
    $dst = [System.IO.Path]::ChangeExtension($src, ".webp")

    # Skip if an up-to-date webp already exists
    if ((Test-Path $dst) -and ((Get-Item $dst).LastWriteTime -ge $_.LastWriteTime)) { return }

    if ($converter -eq "magick") {
      & magick $src -quality $Quality $dst
    } else {
      & cwebp -quiet -q $Quality $src -o $dst
    }

    if (Test-Path $dst) {
      $count++
      $savedBytes += ($_.Length - (Get-Item $dst).Length)
      Write-Host ("  {0} -> {1}" -f $_.Name, (Split-Path $dst -Leaf))
    }
  }
}

$savedMB = [math]::Round($savedBytes / 1MB, 2)
Write-Host "Done. Generated $count WebP files, saving ~$savedMB MB." -ForegroundColor Green
