# Сборка APK Dharana (Android) с Google Web Client ID для google_sign_in,
# Client ID Яндекс/VK для редирект-входа и ПРОД-API (обязательно: без dart-define
# приложение ходит на http://localhost:8000 и на реальном телефоне не работает —
# ловушка 2026-09-26, опубликован был такой APK).
# Без YandexClientId/VkClientId кнопок входа через провайдеров не будет.
# Использование:
#   .\build_apk.ps1                      # release-APK, API = https://api.dharana.ru
#   .\build_apk.ps1 -Debug               # debug-APK (быстрая отладка на устройстве)
#   .\build_apk.ps1 -InstallUsb          # release-APK + установка на телефон по USB
#   .\build_apk.ps1 -ApiBaseUrl http://10.0.2.2:8000   # сборка против локального API
# Артефакт: build\app\outputs\flutter-apk\app-release.apk (или app-debug.apk)
param(
  [switch]$Debug,
  [switch]$InstallUsb,
  [string]$ApiBaseUrl = "https://api.dharana.ru",
  [string]$GoogleWebClientId = "914006620256-t7uqhvlqqlikgesrl59cghv3d1l93gft.apps.googleusercontent.com",
  # Client ID Яндекс/VK — публичные, но БЕЗ них кнопок входа не будет (проверяем
  # результат сборки). Android-клиент Яндекса выдан на платформу Android.
  [string]$YandexClientId = "514c76e5335f44d0b9aa9fd5335b3fbd",
  [string]$VkClientId = "54803294",
  [string]$SiteBaseUrl = "https://dharana.ru"
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

# Проверка, что ключи OAuth реально попали в сборку. Без них экран входа
# показывает меньше кнопок (ломали кнопки VK/Яндекс, 2026-10-05: собрали debug-APK
# без --dart-define и установили его по USB вместо release).
function Assert-ApkDefines([string]$Path, [string[]]$Required) {
  if (-not $Required -or $Required.Count -eq 0) { return }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
  try {
    $entry = $zip.Entries | Where-Object { $_.FullName -eq 'lib/arm64-v8a/libapp.so' } | Select-Object -First 1
    if (-not $entry) { throw "В APK нет lib/arm64-v8a/libapp.so — проверка ключей невозможна." }
    $ms = New-Object System.IO.MemoryStream
    $stream = $entry.Open()
    $stream.CopyTo($ms)
    $stream.Dispose()
    $latin = [System.Text.Encoding]::GetEncoding(28591).GetString($ms.ToArray())
    foreach ($value in $Required) {
      if ($latin.Contains($value)) {
        Write-Host "Проверка ключей: найден $value — OK" -ForegroundColor Green
      } else {
        throw ("Проверка ключей провалена: '$value' НЕ найден в APK.`n" +
               "Такой APK нельзя ставить: кнопки входа через провайдера не появятся.`n" +
               "Пересоберите с -YandexClientId/-VkClientId (в build_apk.ps1 уже есть значения по умолчанию).")
      }
    }
  } finally { $zip.Dispose() }
}

$defines = @(
  "--dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId",
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=SITE_BASE_URL=$SiteBaseUrl"
)
if ($YandexClientId) { $defines += "--dart-define=YANDEX_CLIENT_ID=$YandexClientId" }
if ($VkClientId) { $defines += "--dart-define=VK_CLIENT_ID=$VkClientId" }

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
$requiredDefines = @($YandexClientId, $VkClientId) | Where-Object { $_ }
Assert-ApkDefines -Path $apk -Required @($requiredDefines)

Write-Host "`nAPK готов: $apk`n" -ForegroundColor Green

if ($InstallUsb) {
  $adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
  if (-not (Test-Path $adb)) { throw "adb не найден: $adb" }
  & $adb devices
  & $adb install -r $apk
  if ($LASTEXITCODE -ne 0) { throw "adb install завершился с ошибкой (код $LASTEXITCODE)" }
  Write-Host "Установлено на устройство по USB: $apk" -ForegroundColor Green
}

Write-Host "Залить на сайт (замена dharana.apk):"
Write-Host "  scp `"$apk`" dharana_ai:/tmp/dharana.apk"
Write-Host '  ssh dharana_ai "sudo cp /tmp/dharana.apk /opt/dharana/downloads/apk/dharana.apk"'