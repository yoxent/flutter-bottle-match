# Builds or runs Flutter with the local Firebase keys, then restores the
# tracked stubs. The stubs stay empty in git.
#
# tool/flutter_with_firebase.ps1 build appbundle
# tool/flutter_with_firebase.ps1 run

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if (-not $FlutterArgs -or $FlutterArgs.Count -eq 0) {
    Write-Error "Usage: tool/flutter_with_firebase.ps1 <flutter args>"
    exit 1
}

$defines = Join-Path $root "firebase_defines.json"
$jsonStub = Join-Path $root "android\app\google-services.json"
$jsonLocal = Join-Path $root "android\app\google-services.local.json"
$plistStub = Join-Path $root "ios\Runner\GoogleService-Info.plist"
$plistLocal = Join-Path $root "ios\Runner\GoogleService-Info.local.plist"
$dartFile = Join-Path $root "lib\firebase_options.dart"

foreach ($required in @($defines, $jsonLocal, $plistLocal, $jsonStub, $plistStub)) {
    if (-not (Test-Path $required)) {
        Write-Error "Missing $required"
        exit 1
    }
}

$backup = Join-Path $env:TEMP "flutter-bottle-match-firebase-stubs"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item $jsonStub (Join-Path $backup "google-services.json") -Force
Copy-Item $plistStub (Join-Path $backup "GoogleService-Info.plist") -Force

$exitCode = 1
try {
    Copy-Item $jsonLocal $jsonStub -Force
    Copy-Item $plistLocal $plistStub -Force

    $argsForFlutter = @($FlutterArgs)
    $hasDefineFile = $false
    foreach ($arg in $argsForFlutter) {
        if ($arg -like "--dart-define-from-file=*") {
            $hasDefineFile = $true
        }
    }
    if (-not $hasDefineFile) {
        $argsForFlutter += "--dart-define-from-file=firebase_defines.json"
    }

    & flutter @argsForFlutter
    if ($null -ne $LASTEXITCODE) {
        $exitCode = $LASTEXITCODE
    }
}
finally {
    Copy-Item (Join-Path $backup "google-services.json") $jsonStub -Force
    Copy-Item (Join-Path $backup "GoogleService-Info.plist") $plistStub -Force
    Remove-Item $backup -Recurse -Force
}

$leaked = $false
foreach ($path in @($jsonStub, $plistStub, $dartFile)) {
    if (Select-String -Path $path -Pattern "AIza" -Quiet) {
        $leaked = $true
    }
}
if ($leaked) {
    Write-Error "Tracked Firebase files still contain an API key. Do not commit them."
    exit 1
}

exit $exitCode
