# Сборка APK Dharana (Android) с Google Web Client ID для google_sign_in
# и ПРОД-API (обязательно: без dart-define приложение ходит на http://localhost:8000
# и на реальном телефоне не работает — ловушка 2026-09-26, опубликован был такой APK).
# Использование:
#   .\build_apk.ps1                      # release-APK, API = https://api.dharana.ru
#   .\build_apk.ps1 -Debug               # debug-APK (быстрая отладка на устройстве)
#   .\build_apk.ps1 -ApiBaseUrl http://10.0.2.2:8000   # сборка против локального API
# Артефакт: build\app\outputs\flutter-apk\app-release.apk (или app-debug.apk)
param(
  [switch]$Debug,
  [string]$ApiBaseUrl = "https://api.dharana.ru",
  [string]$GoogleWebClientId = "914006620256-t7uqhvlqqlikgesrl59cghv3d1l93gft.apps.googleusercontent.com"
)

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

$flutter = $null
foreach ($candidate in @(
    "C:\Users\rrshidev\develop\flutter\bin\flutter.bat",
    (Join-Path $env:LOCALAPPDATA "flutter\bin\flutter.bat"),
    (Join-Path $env:USERPROFILE "flutter\bin\flutter.bat"))) {
  if ($candidate -and (Test-Path $candidate)) { $flutter = $candidate; break }
}
if (-not $flutter) {
  $flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
  if (-not $flutter) { throw "Flutter не найден. Укажите путь к flutter.bat в переменной `$flutter в начале скрипта." }
}

# Проверка, что в собранном APK действительно продовый API, а не localhost.
# Ищет хост API в libapp.so (Dart AOT хранит строки констант в пуле объектов).
function Assert-ApkApiHost([string]$Path, [string]$ExpectedHost) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
  try {
    $entry = $zip.Entries | Where-Object { $_.FullName -eq 'lib/arm64-v8a/libapp.so' } | Select-Object -First 1
    if (-not $entry) { throw "В APK нет lib/arm64-v8a/libapp.so — проверка API невозможна." }
    $ms = New-Object System.IO.MemoryStream
    $stream = $entry.Open()
    $stream.CopyTo($ms)
    $stream.Dispose()
    $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($ms.ToArray())
    if ($latin.Contains($ExpectedHost)) {
      Write-Host "Проверка API: '$ExpectedHost' найден в libapp.so — OK" -ForegroundColor Green
    } else {
      $found = ([regex]::Matches($latin, 'https?://[A-Za-z0-9._\-]+(:\d+)?')).Value | Select-Object -Unique
      throw ("Проверка API провалена: '$ExpectedHost' НЕ найден в APK.`n" +
             "Найденные хосты: $($found -join ', ')`n" +
             "Такой APK публиковать нельзя — приложение не достучится до бэкенда.")
    }
  } finally { $zip.Dispose() }
}

$defines = @(
  "--dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId",
  "--dart-define=API_BASE_URL=$ApiBaseUrl"
)

# Gradle пишет в stderr обычные предупреждения — при ErrorActionPreference=Stop
# PowerShell 5.1 превращает их в NativeCommandError. На время сборки снижаем строгость.
$ErrorActionPreference = "Continue"
if ($Debug) {
  & $flutter build apk --debug @defines
  $apk = "$PSScriptRoot\build\app\outputs\flutter-apk\app-debug.apk"
} else {
  & $flutter build apk --release @defines
  $apk = "$PSScriptRoot\build\app\outputs\flutter-apk\app-release.apk"
}
$exitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($exitCode -ne 0) { Write-Error "Сборка завершилась с ошибкой (код $exitCode)"; exit $exitCode }

$expectedHost = ([System.Uri]$ApiBaseUrl).Host
Assert-ApkApiHost -Path $apk -ExpectedHost $expectedHost

Write-Host "`nAPK готов: $apk`n" -ForegroundColor Green
Write-Host "Залить на сайт (замена dharana.apk):"
Write-Host "  scp `"$apk`" dharana_ai:/tmp/dharana.apk"
Write-Host '  ssh dharana_ai "sudo cp /tmp/dharana.apk /opt/dharana/downloads/apk/dharana.apk"'