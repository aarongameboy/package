param([switch]$StartGame, [string]$ManifestPath, [ValidateRange(1,8)][int]$Connections = 4)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root = [IO.Path]::GetFullPath($PSScriptRoot)
$gameRoot = Join-Path $root 'Windows'
$curl = (Get-Command curl.exe -ErrorAction Stop).Source
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $root 'download_manifest.json'
    $fresh = $ManifestPath + '.new'
    & $curl --silent --show-error --location --fail --connect-timeout 10 --max-time 30 --retry 1 --output $fresh 'https://raw.githubusercontent.com/aarongameboy/package/main/download_manifest.json'
    if ($LASTEXITCODE -eq 0) { Move-Item -LiteralPath $fresh -Destination $ManifestPath -Force }
    elseif (-not (Test-Path -LiteralPath $ManifestPath)) { throw 'Cannot load download list. Check network and run again.' }
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$pending = @()
$reused = 0
foreach ($file in $manifest.files) {
    if (-not $file.path.StartsWith('Windows/') -or $file.sha256 -notmatch '^[0-9a-f]{64}$' -or $file.url -notmatch '^https://github\.com/aarongameboy/package/releases/download/playtest-20261001/[^/]+$') { throw 'Invalid download entry' }
    $target = [IO.Path]::GetFullPath((Join-Path $root $file.path))
    if (-not $target.StartsWith($gameRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid build path' }
    if ((Test-Path -LiteralPath $target -PathType Leaf) -and (Get-Item -LiteralPath $target).Length -eq [long]$file.bytes -and (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $file.sha256) { $reused++; continue }
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
    if ($file.chunks) {
        if (($file.chunks | Measure-Object bytes -Sum).Sum -ne [long]$file.bytes) { throw 'Invalid chunk size' }
        foreach ($chunk in $file.chunks) {
            if ($chunk.sha256 -notmatch '^[0-9a-f]{64}$' -or $chunk.url -notmatch '^https://github\.com/aarongameboy/package/releases/download/playtest-20261001/[^/]+$') { throw 'Invalid chunk entry' }
        }
    }
    $pending += [pscustomobject]@{ path=$file.path; target=$target; bytes=[long]$file.bytes; sha256=$file.sha256; url=$file.url; chunks=$file.chunks }
}
Write-Host "Verified existing files: $reused. Files to download: $($pending.Count). Parallel downloads: $Connections."
$worker = {
    param($file, $curl)
    $ErrorActionPreference='Stop'
    function Get-DownloadHash([string]$path) {
        $hashStream=[IO.File]::OpenRead($path)
        $algorithm=[Security.Cryptography.SHA256]::Create()
        try { return [BitConverter]::ToString($algorithm.ComputeHash($hashStream)).Replace('-','').ToLowerInvariant() }
        finally { $algorithm.Dispose(); $hashStream.Dispose() }
    }
    $partial=$file.target+'.download'
    if ((Test-Path -LiteralPath $partial) -and (Get-Item -LiteralPath $partial).Length -gt $file.bytes) { throw "Oversized download: $partial" }
    $urlPath=($file.path.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
    $hostName=if ($file.path -match '\.(exe|dll|pak|ucas|utoc)$') {'media.githubusercontent.com/media'} else {'raw.githubusercontent.com'}
    $fallback="https://$hostName/aarongameboy/package/66f21df028214732a530a63787326821e545330b/$urlPath"
    $complete=$false
    if ($file.chunks) {
        try {
            $offset=[long]0
            foreach ($chunk in $file.chunks) {
                $length=if (Test-Path -LiteralPath $partial) { (Get-Item -LiteralPath $partial).Length } else { [long]0 }
                if ($length -ge ($offset+[long]$chunk.bytes)) { $offset += [long]$chunk.bytes; continue }
                $segment=$partial+'.segment'
                $prefix=$length-$offset
                if ($prefix -gt 0) {
                    if (-not (Test-Path -LiteralPath $segment) -or (Get-Item -LiteralPath $segment).Length -lt $prefix) {
                        $chunkInput=[IO.File]::OpenRead($partial)
                        $chunkOutput=[IO.File]::Create($segment)
                        try { [void]$chunkInput.Seek($offset,[IO.SeekOrigin]::Begin); $chunkInput.CopyTo($chunkOutput) }
                        finally { $chunkOutput.Dispose(); $chunkInput.Dispose() }
                    }
                    $stream=[IO.File]::OpenWrite($partial)
                    try { $stream.SetLength($offset) } finally { $stream.Dispose() }
                }
                if (-not (Test-Path -LiteralPath $segment) -or (Get-Item -LiteralPath $segment).Length -ne [long]$chunk.bytes) {
                    & $curl --silent --show-error --location --fail --retry 2 --retry-delay 2 --connect-timeout 10 --speed-limit 1024 --speed-time 30 --continue-at - --stderr ($partial+'.log') --output $segment $chunk.url
                    if ($LASTEXITCODE -ne 0) { throw 'Chunk interrupted' }
                }
                if ((Get-Item -LiteralPath $segment).Length -ne [long]$chunk.bytes -or (Get-DownloadHash $segment) -ne $chunk.sha256) {
                    Move-Item -LiteralPath $segment -Destination ($segment+'.invalid-'+[DateTime]::UtcNow.Ticks)
                    throw 'Chunk checksum failed'
                }
                $chunkInput=[IO.File]::OpenRead($segment)
                $chunkOutput=[IO.File]::Open($partial,[IO.FileMode]::Append,[IO.FileAccess]::Write)
                try { $chunkInput.CopyTo($chunkOutput) } finally { $chunkOutput.Dispose(); $chunkInput.Dispose() }
                Remove-Item -LiteralPath $segment
                $offset += [long]$chunk.bytes
            }
            $complete=$true
        } catch { $complete=$false }
    }
    $urls=if ($file.chunks) { @($fallback) } else { @($file.url,$fallback) }
    foreach ($url in $urls) {
        if ($complete) { break }
        if ((Test-Path -LiteralPath $partial) -and (Get-Item -LiteralPath $partial).Length -eq $file.bytes) { $complete=$true; break }
        $output = & $curl --silent --show-error --location --fail --retry 2 --retry-delay 2 --connect-timeout 10 --speed-limit 1024 --speed-time 30 --continue-at - --stderr ($partial+'.log') --output $partial $url
        if ($LASTEXITCODE -eq 0) { $complete=$true; break }
    }
    if (-not $complete) { throw "Interrupted: $($file.path). Run again to resume." }
    if ((Get-Item -LiteralPath $partial).Length -ne $file.bytes -or (Get-DownloadHash $partial) -ne $file.sha256) {
        Move-Item -LiteralPath $partial -Destination ($partial+'.invalid-'+[DateTime]::UtcNow.Ticks)
        throw "Checksum failed: $($file.path). Run again to download a clean copy."
    }
    Move-Item -LiteralPath $partial -Destination $file.target -Force
    return $file.path
}
$pool=[RunspaceFactory]::CreateRunspacePool(1,$Connections)
$pool.Open()
$jobs=@()
$failures=@()
try {
    foreach ($file in $pending) {
        $ps=[PowerShell]::Create()
        $ps.RunspacePool=$pool
        [void]$ps.AddScript($worker.ToString()).AddArgument($file).AddArgument($curl)
        $jobs += [pscustomobject]@{ ps=$ps; handle=$ps.BeginInvoke(); file=$file }
    }
    $lastReport=[DateTime]::MinValue
    $done=0
    while ($jobs.Count -gt 0) {
        $remaining=@()
        foreach ($job in $jobs) {
            if ($job.handle.IsCompleted) {
                try {
                    $result=$job.ps.EndInvoke($job.handle)
                    if (-not $result) { throw "Download worker returned no verified file." }
                    $done++
                    Write-Host "[$done/$($pending.Count)] Verified $result"
                } catch { $message=$_.Exception.GetBaseException().Message; $failures += $message; Write-Host $message -ForegroundColor Red }
                finally { $job.ps.Dispose() }
            } else { $remaining += $job }
        }
        $jobs=$remaining
        if (($jobs.Count -gt 0) -and ([DateTime]::Now-$lastReport).TotalSeconds -ge 10) {
            $downloaded=[long]0
            foreach ($file in $pending) {
                if (Test-Path -LiteralPath ($file.target+'.download')) { $downloaded += (Get-Item -LiteralPath ($file.target+'.download')).Length }
                if (Test-Path -LiteralPath ($file.target+'.download.segment')) { $downloaded += (Get-Item -LiteralPath ($file.target+'.download.segment')).Length }
                if ((Test-Path -LiteralPath $file.target) -and (Get-Item -LiteralPath $file.target).Length -eq $file.bytes) { $downloaded += $file.bytes }
            }
            $total=($pending | Measure-Object -Property bytes -Sum).Sum
            Write-Host ('Download progress: {0:N1} / {1:N1} MB; completed {2}/{3}' -f ($downloaded/1MB),($total/1MB),$done,$pending.Count)
            $lastReport=[DateTime]::Now
        }
        if ($jobs.Count -gt 0) { Start-Sleep -Milliseconds 300 }
    }
} finally {
    foreach ($job in $jobs) { $job.ps.Stop(); $job.ps.Dispose() }
    $pool.Close(); $pool.Dispose()
}
if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host 'All required game files verified.' -ForegroundColor Green
if ($StartGame) { Start-Process -FilePath (Join-Path $gameRoot 'Project2026.exe') -WorkingDirectory $gameRoot -ArgumentList '-windowed -ResX=1600 -ResY=900' }
