param([switch]$StartGame)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buildRef = '66f21df028214732a530a63787326821e545330b'
$root = [IO.Path]::GetFullPath($PSScriptRoot)
$gameRoot = Join-Path $root 'Windows'
$manifestPath = Join-Path $root 'build_manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/aarongameboy/package/main/build_manifest.json' -OutFile $manifestPath
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
$index = 0
foreach ($file in $manifest.files) {
    $index++
    if (-not $file.path.StartsWith('Windows/') -or $file.sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Invalid build manifest entry' }
    $target = [IO.Path]::GetFullPath((Join-Path $root $file.path))
    if (-not $target.StartsWith($gameRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid build path' }
    $valid = $false
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        if ((Get-Item -LiteralPath $target).Length -eq [long]$file.bytes) {
            $valid = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $file.sha256
        }
    }
    if ($valid) { Write-Host "[$index/$($manifest.files.Count)] OK $($file.path)"; continue }
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
    $partial = $target + '.download'
    if ((Test-Path -LiteralPath $partial) -and (Get-Item -LiteralPath $partial).Length -gt [long]$file.bytes) {
        throw "Oversized partial download: $partial. Move it aside and retry."
    }
    $urlPath = ($file.path.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
    $isLfs = $file.path -match '\.(exe|dll|pak|ucas|utoc)$'
    $hostName = if ($isLfs) { 'media.githubusercontent.com/media' } else { 'raw.githubusercontent.com' }
    $urlRef = if ($file.path -match '^Windows/[^/]+\.bat$') { 'main' } else { $buildRef }
    $url = "https://$hostName/aarongameboy/package/$urlRef/$urlPath"
    Write-Host "[$index/$($manifest.files.Count)] Download $($file.path) ($($file.bytes) bytes)"
    if ($curl) {
        & $curl.Source --location --fail --retry 4 --retry-delay 3 --connect-timeout 30 --continue-at - --output $partial $url
        if ($LASTEXITCODE -ne 0) { throw "Download interrupted: $($file.path). Run again to resume." }
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $partial
    }
    if ((Get-Item -LiteralPath $partial).Length -ne [long]$file.bytes -or
        (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash -ne $file.sha256) {
        throw "Download checksum failed: $partial. Move it aside and retry."
    }
    Move-Item -LiteralPath $partial -Destination $target -Force
}
Write-Host 'All game files verified.' -ForegroundColor Green
if ($StartGame) {
    Start-Process -FilePath (Join-Path $gameRoot 'Project2026.exe') -WorkingDirectory $gameRoot -ArgumentList '-windowed -ResX=1600 -ResY=900'
}
