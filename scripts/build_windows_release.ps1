param(
  [switch]$Offline,
  [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

function Require-Command($Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found in PATH."
  }
}

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$DistDir = Join-Path $ProjectRoot "dist"
$PackageDir = Join-Path $DistDir "vibe_im_windows_release"
$ZipPath = Join-Path $DistDir "vibe_im_windows_release.zip"

Set-Location $ProjectRoot

if (-not $IsWindows) {
  throw "Windows release builds must be created on Windows."
}

Require-Command flutter

if (-not (Test-Path (Join-Path $ProjectRoot "windows"))) {
  Write-Host "Generating Windows platform files..."
  flutter create --platforms=windows .
}

if ($Offline) {
  Write-Host "Resolving packages from local pub cache..."
  flutter pub get --offline
} else {
  Write-Host "Resolving packages..."
  flutter pub get
}

if (-not $SkipTests) {
  Write-Host "Running analyzer and widget tests..."
  flutter analyze
  flutter test
}

Write-Host "Building Windows release..."
flutter build windows --release

if (Test-Path $PackageDir) {
  Remove-Item $PackageDir -Recurse -Force
}
if (Test-Path $ZipPath) {
  Remove-Item $ZipPath -Force
}
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

Copy-Item `
  -Path (Join-Path $ProjectRoot "build\windows\x64\runner\Release") `
  -Destination $PackageDir `
  -Recurse

Compress-Archive -Path (Join-Path $PackageDir "*") -DestinationPath $ZipPath

Write-Host ""
Write-Host "Windows executable package created:"
Write-Host $ZipPath
Write-Host ""
Write-Host "Run the app from:"
Write-Host (Join-Path $PackageDir "feishu_im.exe")
