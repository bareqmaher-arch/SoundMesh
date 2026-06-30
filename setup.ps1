# =====================================================================
#  TakiWaki — سكربت إعداد المشروع
#  يولّد منصة أندرويد، يطبّق الـ Manifest، ويجلب الحزم.
#  شغّله مرة واحدة بعد تثبيت Flutter:  ./setup.ps1
# =====================================================================

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

Write-Host "==> التحقق من Flutter..." -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter غير مثبّت أو غير موجود في PATH." -ForegroundColor Red
    Write-Host "ثبّته من https://docs.flutter.dev/get-started/install/windows ثم أعد التشغيل." -ForegroundColor Yellow
    exit 1
}

Write-Host "==> توليد منصة أندرويد (flutter create)..." -ForegroundColor Cyan
# يولّد مجلد android/ دون المساس بـ lib/ و pubspec.yaml الموجودين.
flutter create --org com.takiwaki --platforms=android .

Write-Host "==> تطبيق AndroidManifest المخصّص..." -ForegroundColor Cyan
$manifestSrc = Join-Path $root "android_setup\AndroidManifest.xml"
$manifestDst = Join-Path $root "android\app\src\main\AndroidManifest.xml"
Copy-Item $manifestSrc $manifestDst -Force
Write-Host "    تم نسخ الـ Manifest." -ForegroundColor Green

Write-Host "==> ضبط minSdkVersion = 24 ..." -ForegroundColor Cyan
$gradle = Join-Path $root "android\app\build.gradle"
if (Test-Path $gradle) {
    $content = Get-Content $gradle -Raw
    $content = $content -replace "minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24"
    $content = $content -replace "minSdk\s+flutter\.minSdkVersion", "minSdk 24"
    Set-Content $gradle $content -Encoding UTF8
    Write-Host "    تم الضبط." -ForegroundColor Green
} else {
    Write-Host "    لم يُعثر على build.gradle — اضبط minSdk يدوياً إلى 24." -ForegroundColor Yellow
}

Write-Host "==> إنشاء مجلدات الأصول..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path (Join-Path $root "assets\images") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root "assets\avatars") | Out-Null

Write-Host "==> جلب الحزم (flutter pub get)..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "تم الإعداد بنجاح! ✅" -ForegroundColor Green
Write-Host "وصّل جهازي أندرويد على نفس شبكة WiFi ثم شغّل:" -ForegroundColor Cyan
Write-Host "    flutter run" -ForegroundColor White
