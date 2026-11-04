<#
.SYNOPSIS
    Installs the firefox-butter-smooth profile (user.js + userChrome.css) into a
    Firefox profile, backing up what is already there.

.DESCRIPTION
    Finds the profile through profiles.ini (or -ProfilePath), refuses to run while
    Firefox is open, copies prefs.js to a timestamped backup, then drops user.js
    and chrome\userChrome.css into the profile.

    Profile choice follows profiles.ini the same way Firefox does: an
    [InstallXXXXXXXX] section binds an installation to its default profile, and
    that binding wins over the [ProfileN] Default flag. On a machine with two
    channels installed those two can disagree, and picking the wrong one silently
    configures a browser you never open.

    No admin rights, no registry writes, no changes outside the profile folder.

.PARAMETER ProfilePath
    Full path to a specific profile folder. Skips profile detection.

.PARAMETER List
    Print the profiles found in profiles.ini and exit.

.PARAMETER SkipUserJs
    Copy only the CSS, not user.js. Note: the stylesheet switch lives in user.js,
    so you would have to set toolkit.legacyUserProfileCustomizations.stylesheets
    by hand for the CSS to load.

.PARAMETER SkipChrome
    Copy only user.js.

.EXAMPLE
    .\Install-FirefoxTune.ps1 -List

.EXAMPLE
    .\Install-FirefoxTune.ps1

.EXAMPLE
    .\Install-FirefoxTune.ps1 -ProfilePath 'C:\Users\me\AppData\Roaming\Mozilla\Firefox\Profiles\abcd1234.default-beta'
#>
[CmdletBinding()]
param(
    [string]$ProfilePath,
    [switch]$List,
    [switch]$SkipUserJs,
    [switch]$SkipChrome
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Write-Step  { param([string]$Text) Write-Host "  $Text" }
function Write-Ok    { param([string]$Text) Write-Host "  [ok]   $Text" -ForegroundColor Green }
function Write-Warn2 { param([string]$Text) Write-Host "  [warn] $Text" -ForegroundColor Yellow }

function Get-AppDataRoot {
    if ($env:APPDATA)     { return $env:APPDATA }
    if ($env:USERPROFILE) { return (Join-Path $env:USERPROFILE 'AppData\Roaming') }
    throw 'Cannot locate the roaming AppData folder. Pass -ProfilePath instead.'
}

Write-Host ""
Write-Host "firefox-butter-smooth - installer" -ForegroundColor Cyan
Write-Host "-------------------------------"

# --- 0. sanity: files present -------------------------------------------------
$userJsSrc  = Join-Path $repoRoot 'user.js'
$userCssSrc = Join-Path $repoRoot 'chrome\userChrome.css'

if (-not $SkipUserJs -and -not (Test-Path -LiteralPath $userJsSrc)) {
    throw "user.js not found at $userJsSrc - run this script from inside the cloned repo."
}
if (-not $SkipChrome -and -not (Test-Path -LiteralPath $userCssSrc)) {
    throw "chrome\userChrome.css not found at $userCssSrc - run this script from inside the cloned repo."
}

# --- 1. parse profiles.ini ----------------------------------------------------
$ffRoot  = Join-Path (Get-AppDataRoot) 'Mozilla\Firefox'
$iniPath = Join-Path $ffRoot 'profiles.ini'

function Resolve-ProfilePath {
    param([string]$Raw, [string]$Base)
    $p = $Raw -replace '/', '\'
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $Base $p)
}

function Get-FirefoxProfiles {
    $result = [pscustomobject]@{
        Profiles = @()
        Installs = @()
        IniPath  = $iniPath
        Found    = $false
    }
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
            $installs += [pscustomobject]@{
                Section = $s.Section
                Path    = (Resolve-ProfilePath -Raw $s['Default'] -Base $ffRoot)
            }
        }
    }

    $profiles = @()
    foreach ($s in $sections) {
        if ($s.Section -notlike 'Profile*') { continue }
        if (-not $s.ContainsKey('Path'))    { continue }
        $resolved = Resolve-ProfilePath -Raw $s['Path'] -Base $ffRoot
        if (-not (Test-Path -LiteralPath $resolved)) { continue }
        $bound = $null
        foreach ($i in $installs) {
            if ($i.Path -eq $resolved) { $bound = $i.Section }
        }
        $profiles += [pscustomobject]@{
            Path      = $resolved
            Name      = if ($s.ContainsKey('Name')) { $s['Name'] } else { Split-Path -Leaf $resolved }
            IsDefault = ($s['Default'] -eq '1')
            BoundTo   = $bound
            HasPrefs  = (Test-Path -LiteralPath (Join-Path $resolved 'prefs.js'))
            HasUserJs = (Test-Path -LiteralPath (Join-Path $resolved 'user.js'))
            HasChrome = (Test-Path -LiteralPath (Join-Path $resolved 'chrome\userChrome.css'))
        }
    }

    if ($profiles.Count -eq 0) {
        $profRoot = Join-Path $ffRoot 'Profiles'
        if (Test-Path -LiteralPath $profRoot) {
            $profiles = Get-ChildItem -LiteralPath $profRoot -Directory |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'prefs.js') } |
                Sort-Object LastWriteTime -Descending |
                ForEach-Object {
                    [pscustomobject]@{
                        Path = $_.FullName; Name = $_.Name; IsDefault = $false; BoundTo = $null
                        HasPrefs = $true
                        HasUserJs = (Test-Path -LiteralPath (Join-Path $_.FullName 'user.js'))
                        HasChrome = (Test-Path -LiteralPath (Join-Path $_.FullName 'chrome\userChrome.css'))
                    }
                }
        }
    }

    $result.Profiles = $profiles
    $result.Installs = $installs
    return $result
}

$found = Get-FirefoxProfiles

if ($List) {
    if (-not $found.Found) { Write-Warn2 "no profiles.ini at $iniPath"; exit 1 }
    Write-Host ""
    Write-Host "  profiles.ini: $iniPath"
    Write-Host ""
    foreach ($p in $found.Profiles) {
        $flags = @()
        if ($p.IsDefault) { $flags += 'Default=1' }
        if ($p.BoundTo)   { $flags += "bound to $($p.BoundTo)" }
        if ($p.HasUserJs) { $flags += 'has user.js' }
        if ($p.HasChrome) { $flags += 'has userChrome.css' }
        Write-Host "    $($p.Name)"
        Write-Host "      $($p.Path)"
        if ($flags.Count) { Write-Host "      [$($flags -join ', ')]" -ForegroundColor DarkGray }
    }
    Write-Host ""
    exit 0
}

# --- 2. Firefox must be closed ------------------------------------------------
$running = Get-Process -Name 'firefox' -ErrorAction SilentlyContinue
if ($running) {
    Write-Host ""
    Write-Warn2 "Firefox is running ($($running.Count) process(es))."
    Write-Host "         Close every Firefox window and run this again."
    Write-Host "         (Firefox rewrites prefs.js on exit and would overwrite the install.)"
    exit 1
}
Write-Ok "Firefox is not running"

# --- 3. locate the profile ----------------------------------------------------
$profiles = $found.Profiles

if ($ProfilePath) {
    if (-not (Test-Path -LiteralPath $ProfilePath)) { throw "Profile path does not exist: $ProfilePath" }
    $profiles = @([pscustomobject]@{
        Path = (Resolve-Path -LiteralPath $ProfilePath).Path
        Name = 'manual'
        IsDefault = $true
        BoundTo = $null
        HasPrefs = (Test-Path -LiteralPath (Join-Path $ProfilePath 'prefs.js'))
        HasUserJs = $false
        HasChrome = $false
    })
}

if ($profiles.Count -eq 0) {
    Write-Host ""
    Write-Warn2 "No Firefox profile found in $ffRoot"
    Write-Host ""
    Write-Host "         That usually means Firefox has not been started yet on this"
    Write-Host "         account. Open Firefox once, close it, then run this again."
    Write-Host "         You can also pass the folder from about:support -> Profile Folder:"
    Write-Host "           .\Install-FirefoxTune.ps1 -ProfilePath 'C:\path\to\profile'"
    exit 1
}

# --- 4. pick one --------------------------------------------------------------
$target = $null

if ($profiles.Count -eq 1) {
    $target = $profiles[0]
}
else {
    # an [Install...] binding is what Firefox itself uses - prefer it
    $bound = $profiles | Where-Object { $_.BoundTo }
    if ($bound.Count -eq 1) {
        $target = $bound[0]
        Write-Warn2 "Several profiles found - using the one bound to $($target.BoundTo)."
    }
    elseif ($bound.Count -gt 1) {
        Write-Host ""
        Write-Warn2 "Several Firefox installations, each with its own default profile:"
        foreach ($b in $bound) {
            Write-Host "      $($b.BoundTo)  ->  $($b.Path)"
        }
        Write-Host "         Pass -ProfilePath with the one you actually use."
        exit 1
    }
    else {
        $default = $profiles | Where-Object { $_.IsDefault } | Select-Object -First 1
        if ($default) {
            $target = $default
            Write-Warn2 "Several profiles found - using Default=1 from profiles.ini."
        }
        else {
            Write-Host ""
            Write-Host "  Multiple profiles, none marked default:"
            for ($i = 0; $i -lt $profiles.Count; $i++) {
                Write-Host ("    [{0}] {1}" -f $i, $profiles[$i].Path)
            }
            $pick = Read-Host "  Pick one by number"
            $target = $profiles[[int]$pick]
        }
    }
}

Write-Ok "profile: $($target.Path)"
if ($target.HasUserJs) { Write-Warn2 "this profile already has a user.js - it will be backed up and replaced" }

# --- 5. back up ---------------------------------------------------------------
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$prefs = Join-Path $target.Path 'prefs.js'

if (Test-Path -LiteralPath $prefs) {
    $prefsBak = Join-Path $target.Path "prefs-backup-$stamp.js"
    Copy-Item -LiteralPath $prefs -Destination $prefsBak
    Write-Ok "backed up prefs.js -> $(Split-Path -Leaf $prefsBak)"
}
else {
    Write-Warn2 "no prefs.js yet in this profile - nothing to back up"
}

$existingUserJs = Join-Path $target.Path 'user.js'
if (Test-Path -LiteralPath $existingUserJs) {
    $jsBak = Join-Path $target.Path "user.js.bak-$stamp"
    Copy-Item -LiteralPath $existingUserJs -Destination $jsBak
    Write-Ok "backed up existing user.js -> $(Split-Path -Leaf $jsBak)"
}

# --- 6. install ---------------------------------------------------------------
if (-not $SkipUserJs) {
    Copy-Item -LiteralPath $userJsSrc -Destination $existingUserJs -Force
    Write-Ok "installed user.js"
}

if (-not $SkipChrome) {
    $chromeDir = Join-Path $target.Path 'chrome'
    if (-not (Test-Path -LiteralPath $chromeDir)) {
        New-Item -ItemType Directory -Path $chromeDir | Out-Null
    }
    $cssDst = Join-Path $chromeDir 'userChrome.css'
    if (Test-Path -LiteralPath $cssDst) {
        Copy-Item -LiteralPath $cssDst -Destination (Join-Path $chromeDir "userChrome.css.bak-$stamp") -Force
        Write-Ok "backed up existing userChrome.css"
    }
    Copy-Item -LiteralPath $userCssSrc -Destination $cssDst -Force
    Write-Ok "installed chrome\userChrome.css"
}

# --- 7. next steps ------------------------------------------------------------
Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "  Next:"
Write-Host "    1. Start Firefox."
Write-Host "    2. about:support -> Graphics: Compositing must say 'WebRender'."
Write-Host "    3. If it says 'WebRender (Software)', read docs/09-troubleshooting.md."
Write-Host ""
Write-Host "  Undo the profile side with:  .\scripts\Restore-FirefoxTune.ps1"
Write-Host "  Undo the Windows/NVIDIA side by hand:  docs/10-revert.md"
Write-Host ""
