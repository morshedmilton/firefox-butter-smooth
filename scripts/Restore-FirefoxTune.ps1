<#
.SYNOPSIS
    Undoes Install-FirefoxTune.ps1: removes user.js, disables chrome\userChrome.css
    and restores the newest prefs.js backup.

.DESCRIPTION
    Profile-side only. Windows GPU preference, NVIDIA settings and the panel
    refresh rate are not touched - docs/10-revert.md has those clicks.

    Nothing is deleted outright: user.js is renamed, chrome\ is renamed, and the
    current prefs.js is copied aside before the backup is put back.

.PARAMETER ProfilePath
    Full path to a specific profile folder. Skips profile detection.

.PARAMETER List
    Print the profiles found in profiles.ini and exit.

.PARAMETER RemoveChrome
    Delete the chrome folder instead of renaming it to chrome.disabled-<stamp>.
#>
[CmdletBinding()]
param(
    [string]$ProfilePath,
    [switch]$List,
    [switch]$RemoveChrome
)

$ErrorActionPreference = 'Stop'

function Write-Ok    { param([string]$Text) Write-Host "  [ok]   $Text" -ForegroundColor Green }
function Write-Warn2 { param([string]$Text) Write-Host "  [warn] $Text" -ForegroundColor Yellow }

function Get-AppDataRoot {
    if ($env:APPDATA)     { return $env:APPDATA }
    if ($env:USERPROFILE) { return (Join-Path $env:USERPROFILE 'AppData\Roaming') }
    throw 'Cannot locate the roaming AppData folder. Pass -ProfilePath instead.'
}

Write-Host ""
Write-Host "firefox-butter-smooth - restore" -ForegroundColor Cyan
Write-Host "-------------------------------"

$ffRoot  = Join-Path (Get-AppDataRoot) 'Mozilla\Firefox'
$iniPath = Join-Path $ffRoot 'profiles.ini'

function Resolve-ProfilePath {
    param([string]$Raw, [string]$Base)
    $p = $Raw -replace '/', '\'
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $Base $p)
}

function Get-FirefoxProfiles {
    $result = [pscustomobject]@{ Profiles = @(); Found = $false }
    if (-not (Test-Path -LiteralPath $iniPath)) { return $result }

    $result.Found = $true
    $sections = @()
    $current  = $null
    foreach ($line in Get-Content -LiteralPath $iniPath) {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') {
            $current = @{ Section = $Matches[1] }
            $sections += $current
            continue
        }
        if ($null -ne $current -and $t -match '^([^=]+)=(.*)$') {
            $current[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    $installs = @()
    foreach ($s in $sections) {
        if ($s.Section -like 'Install*' -and $s.ContainsKey('Default')) {
            $installs += [pscustomobject]@{ Section = $s.Section; Path = (Resolve-ProfilePath -Raw $s['Default'] -Base $ffRoot) }
        }
    }

    $profiles = @()
    foreach ($s in $sections) {
        if ($s.Section -notlike 'Profile*') { continue }
        if (-not $s.ContainsKey('Path'))    { continue }
        $resolved = Resolve-ProfilePath -Raw $s['Path'] -Base $ffRoot
        if (-not (Test-Path -LiteralPath $resolved)) { continue }
        $bound = $null
        foreach ($i in $installs) { if ($i.Path -eq $resolved) { $bound = $i.Section } }
        $profiles += [pscustomobject]@{
            Path      = $resolved
            Name      = if ($s.ContainsKey('Name')) { $s['Name'] } else { Split-Path -Leaf $resolved }
            IsDefault = ($s['Default'] -eq '1')
            BoundTo   = $bound
        }
    }

    if ($profiles.Count -eq 0) {
        $profRoot = Join-Path $ffRoot 'Profiles'
        if (Test-Path -LiteralPath $profRoot) {
            $profiles = Get-ChildItem -LiteralPath $profRoot -Directory |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'prefs.js') } |
                Sort-Object LastWriteTime -Descending |
                ForEach-Object { [pscustomobject]@{ Path = $_.FullName; Name = $_.Name; IsDefault = $false; BoundTo = $null } }
        }
    }

    $result.Profiles = $profiles
    return $result
}

$found = Get-FirefoxProfiles

if ($List) {
    if (-not $found.Found) { Write-Warn2 "no profiles.ini at $iniPath"; exit 1 }
    foreach ($p in $found.Profiles) {
        $flags = @()
        if ($p.IsDefault) { $flags += 'Default=1' }
        if ($p.BoundTo)   { $flags += "bound to $($p.BoundTo)" }
        Write-Host "    $($p.Name)  $($p.Path)  [$($flags -join ', ')]"
    }
    exit 0
}

$running = Get-Process -Name 'firefox' -ErrorAction SilentlyContinue
if ($running) {
    Write-Host ""
    Write-Warn2 "Firefox is running. Close it and run this again."
    exit 1
}
Write-Ok "Firefox is not running"

$profiles = $found.Profiles

if ($ProfilePath) {
    if (-not (Test-Path -LiteralPath $ProfilePath)) { throw "Profile path does not exist: $ProfilePath" }
    $profiles = @([pscustomobject]@{
        Path = (Resolve-Path -LiteralPath $ProfilePath).Path
        Name = 'manual'; IsDefault = $true; BoundTo = $null
    })
}

if ($profiles.Count -eq 0) {
    Write-Warn2 "No profile found. Nothing to restore."
    exit 1
}

$target = $null
if ($profiles.Count -eq 1) {
    $target = $profiles[0]
}
else {
    $bound = $profiles | Where-Object { $_.BoundTo }
    if ($bound.Count -eq 1)     { $target = $bound[0] }
    elseif ($bound.Count -gt 1) {
        Write-Warn2 "Several installations with their own defaults - pass -ProfilePath."
        exit 1
    }
    else {
        $target = $profiles | Where-Object { $_.IsDefault } | Select-Object -First 1
        if (-not $target) { $target = $profiles[0] }
    }
}

Write-Ok "profile: $($target.Path)"

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- user.js -----------------------------------------------------------------
$userJs = Join-Path $target.Path 'user.js'
if (Test-Path -LiteralPath $userJs) {
    Rename-Item -LiteralPath $userJs -NewName "user.js.removed-$stamp"
    Write-Ok "user.js -> user.js.removed-$stamp"
}
else {
    Write-Warn2 "no user.js in this profile (already clean?)"
}

# --- chrome ------------------------------------------------------------------
$chromeDir = Join-Path $target.Path 'chrome'
$css       = Join-Path $chromeDir 'userChrome.css'
if (Test-Path -LiteralPath $css) {
    if ($RemoveChrome) {
        Remove-Item -LiteralPath $chromeDir -Recurse -Force
        Write-Ok "deleted chrome\"
    }
    else {
        Rename-Item -LiteralPath $css -NewName "userChrome.css.disabled-$stamp"
        Write-Ok "userChrome.css disabled (renamed)"
    }
}

# --- prefs.js ----------------------------------------------------------------
$backups = Get-ChildItem -LiteralPath $target.Path -Filter 'prefs-backup-*.js' -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

if ($backups.Count -gt 0) {
    $prefs = Join-Path $target.Path 'prefs.js'
    if (Test-Path -LiteralPath $prefs) {
        Copy-Item -LiteralPath $prefs -Destination (Join-Path $target.Path "prefs-before-restore-$stamp.js") -Force
    }
    Copy-Item -LiteralPath $backups[0].FullName -Destination $prefs -Force
    Write-Ok "restored $($backups[0].Name) -> prefs.js"
}
else {
    Write-Warn2 "no prefs-backup-*.js found - about:config values are still set"
    Write-Host "         Reset them by hand, or use about:support -> Refresh Firefox."
}

Write-Host ""
Write-Host "Profile side is clean." -ForegroundColor Green
Write-Host ""
Write-Host "  Still manual (docs/10-revert.md):"
Write-Host "    - Settings > Display > Advanced display: refresh rate"
Write-Host "    - Settings > Display > Graphics: Firefox -> Let Windows decide"
Write-Host "    - NVIDIA Control Panel: remove the Firefox program profile"
Write-Host ""
