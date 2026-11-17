# Scans the staged index of a repo. Exits 1 when a commit would contain a
# private key or an API key. Prints paths only.

param(
    [string]$Repo = ""
)

$ErrorActionPreference = "Stop"
if (-not $Repo) {
    $Repo = (Get-Location).Path
}

function Test-StagedText {
    param([string]$Text)
    $googleKey = 'AI' + 'za' + '[0-9A-Za-z_-]{20,}'
    if ($Text -match $googleKey) {
        return $true
    }
    if ($Text -match '-----BEGIN [A-Z ]*PRIVATE KEY-----') {
        return $true
    }
    $assigned = '(?i)(apiKey|api_key|apiSecret|client_secret|current_key)\s*[:=]\s*[''"][^''"]+[''"]'
    if ($Text -match $assigned) {
        return $true
    }
    return $false
}

$names = git -C $Repo diff --cached --name-only --diff-filter=ACMR
if ($LASTEXITCODE -ne 0) {
    Write-Error "git diff --cached failed in $Repo"
    exit 1
}

$blocked = @()
$sensitiveName = '(?i)(^|/)(\.env(\..*)?|credentials\.json|id_rsa|id_ed25519|.+\.(pem|key|p12|pfx|jks|keystore))$'
foreach ($name in $names) {
    if (-not $name) {
        continue
    }
    if ($name -match $sensitiveName) {
        $blocked += $name
        continue
    }
    $content = git -C $Repo show --textconv ":$name"
    if ($LASTEXITCODE -ne 0) {
        continue
    }
    $text = ($content | Out-String)
    if (Test-StagedText $text) {
        $blocked += $name
    }
}

if ($blocked.Count -gt 0) {
    Write-Error ("Refusing to commit. Staged content contains a key or credential:`n" + ($blocked -join "`n"))
    exit 1
}

exit 0
