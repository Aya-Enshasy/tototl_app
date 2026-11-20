$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host 'TOTOTL Stripe verification — Flutter project root' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'Flutter is not available in PATH. Open Android Studio terminal with Flutter installed.'
  exit 1
}
flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test test/stripe_checkout_url_test.dart test/stripe_fund_redirect_test.dart test/stripe_payment_reconciliation_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Static checks and targeted payment tests passed on this machine.' -ForegroundColor Green
Write-Host 'Next: flutter run on an emulator/device with a real browser, then complete a Stripe TEST payment and confirm server contract status.' -ForegroundColor Yellow
