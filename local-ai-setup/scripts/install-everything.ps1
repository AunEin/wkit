<#
.SYNOPSIS
  CP2077 Local AI Modding -- Easy Mode One-Click Installer (v4.0)

.DESCRIPTION
  Installs EVERYTHING you need to run a private, local AI assistant for
  Cyberpunk 2077 modding -- in a single run, with friendly progress messages
  and almost no questions.

  What it installs (in order):
    1. Ollama         (the AI engine)        -- via winget OR direct .exe
    2. VS Code        (the friendly editor)  -- via winget OR direct .exe
    3. Cline ext.     (the chat panel)       -- via 'code --install-extension'
    4. Qwen3-Coder 7B (the small fast brain) -- ~5 GB, mandatory baseline
    5. (Optional) Qwen3-Coder 30B-A3B        -- ~18 GB, asks Y/N first
    6. Desktop shortcut "AI Mod Helper"      -- one-click launcher
    7. First-time-setup guide opened in Notepad

  Every step prints clear PASS/FAIL. If anything fails partway, you can
  re-run the script -- already-installed pieces are skipped.

.PARAMETER SkipOptionalModel
  Don't ask about the big 30B model.

.PARAMETER InstallDeepSeek
  Also pull deepseek-r1:14b (reasoning/debugging model, +8 GB).

.PARAMETER NoLaunch
  Don't open VS Code at the end (CI / unattended runs).
#>

[CmdletBinding()]
param(
    [switch] $SkipOptionalModel,
    [switch] $InstallDeepSeek,
    [switch] $NoLaunch
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'Continue'

# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------
function Write-Banner($t) {
    Write-Host ""
    Write-Host ("=" * 64) -ForegroundColor Magenta
    Write-Host ("  $t")     -ForegroundColor Magenta
    Write-Host ("=" * 64) -ForegroundColor Magenta
}
function Write-Phase($n, $t) {
    Write-Host ""
    Write-Host ("--- Step $n : $t ---") -ForegroundColor Cyan
}
function Write-Ok($m)   { Write-Host "  [OK]   $m"   -ForegroundColor Green }
function Write-Skip($m) { Write-Host "  [SKIP] $m"   -ForegroundColor DarkGray }
function Write-Warn($m) { Write-Host "  [WARN] $m"   -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "  [FAIL] $m"   -ForegroundColor Red }
function Write-Note($m) { Write-Host "         $m"   -ForegroundColor Gray }

function Test-Cmd($n) { $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

function Confirm-YN($question, $default = 'N') {
    $suffix = if ($default -eq 'Y') { '[Y/n]' } else { '[y/N]' }
    $resp = Read-Host "  $question $suffix"
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $default }
    return $resp.Trim().ToUpper().StartsWith('Y')
}

function Refresh-Path {
    # Pull updated PATH from the registry so newly-installed apps are found
    # without needing the user to restart the terminal.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Wait-OllamaReady($timeoutSec = 60) {
    $end = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $end) {
        try {
            $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -eq 200) { return $true }
        } catch {}
        Start-Sleep -Seconds 2
    }
    return $false
}

# ---------------------------------------------------------------------------
# 0. Welcome
# ---------------------------------------------------------------------------
Write-Banner "CP2077 Local AI -- Easy Mode Installer (v4.0)"
Write-Host ""
Write-Host "  This will install everything you need:"
Write-Host "    1. Ollama          (AI engine)              ~500 MB"
Write-Host "    2. VS Code         (friendly editor)        ~100 MB"
Write-Host "    3. Cline extension (the chat panel)         ~50 MB"
Write-Host "    4. Qwen3-Coder 7B  (the AI brain, baseline) ~5 GB"
Write-Host ""
Write-Host "  Total: about 6 GB of downloads. Takes 10-30 min on a normal"
Write-Host "  home connection. The script tells you what it's doing at"
Write-Host "  every step. You can leave it running."
Write-Host ""
Write-Host "  Already-installed pieces are SKIPPED automatically -- it's"
Write-Host "  safe to re-run this script if anything fails."
Write-Host ""
Read-Host "  Press ENTER to begin (or close this window to cancel)" | Out-Null

# ---------------------------------------------------------------------------
# Pre-flight: detect winget
# ---------------------------------------------------------------------------
$useWinget = Test-Cmd 'winget'
if ($useWinget) {
    Write-Host ""
    Write-Host "  winget detected -- installs will use Microsoft's package manager." -ForegroundColor DarkGreen
} else {
    Write-Host ""
    Write-Host "  winget NOT detected -- installs will use direct .exe downloads." -ForegroundColor Yellow
    Write-Host "  (winget ships with Windows 10 1809+ as 'App Installer' from the Microsoft Store.)"
}

# ---------------------------------------------------------------------------
# 1. Ollama
# ---------------------------------------------------------------------------
Write-Phase 1 "Install Ollama (the AI engine)"

if (Test-Cmd 'ollama') {
    Write-Skip "Ollama is already installed."
} else {
    $installed = $false
    if ($useWinget) {
        Write-Note "Running: winget install --id Ollama.Ollama --source winget --accept-source-agreements --accept-package-agreements"
        & winget install --id Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Host
        Refresh-Path
        if (Test-Cmd 'ollama') { $installed = $true }
    }
    if (-not $installed) {
        Write-Note "Falling back to direct download from ollama.com..."
        $url = 'https://ollama.com/download/OllamaSetup.exe'
        $dst = Join-Path $env:TEMP 'OllamaSetup.exe'
        try {
            Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing -ErrorAction Stop
            Write-Note "Launching the Ollama installer (it has its own GUI -- click through it)..."
            Start-Process -FilePath $dst -Wait
            Refresh-Path
            if (Test-Cmd 'ollama') { $installed = $true }
        } catch {
            Write-Err  "Could not download Ollama: $($_.Exception.Message)"
            Write-Note "Manual download: https://ollama.com/download/windows"
        }
    }
    if ($installed) { Write-Ok "Ollama installed." } else { Write-Err "Ollama install failed -- please install manually then re-run this script." }
}

# Make sure the Ollama background service is up
Write-Note "Waiting for the Ollama service to come online..."
if (-not (Wait-OllamaReady 10)) {
    Write-Note "Service not running yet -- starting it..."
    $ollamaExe = (Get-Command ollama -ErrorAction SilentlyContinue).Source
    if (-not $ollamaExe) { $ollamaExe = 'ollama.exe' }
    try { Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden } catch {}
    Start-Sleep -Seconds 3
}
if (Wait-OllamaReady 30) { Write-Ok "Ollama service responding on port 11434." } else { Write-Warn "Could not confirm Ollama is running (check the system tray for the llama icon)." }

# ---------------------------------------------------------------------------
# 2. VS Code
# ---------------------------------------------------------------------------
Write-Phase 2 "Install Visual Studio Code (the friendly editor)"

if (Test-Cmd 'code') {
    Write-Skip "VS Code is already installed."
} else {
    $installed = $false
    if ($useWinget) {
        Write-Note "Running: winget install --id Microsoft.VisualStudioCode --silent --accept-package-agreements"
        # Single-quoted outer string so PS does not eat the inner double-quotes
        # that Inno Setup's /MERGETASKS argument needs.
        & winget install --id Microsoft.VisualStudioCode --silent --accept-source-agreements --accept-package-agreements --override '/MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"' 2>&1 | Out-Host
        Refresh-Path
        if (Test-Cmd 'code') { $installed = $true }
    }
    if (-not $installed) {
        Write-Note "Falling back to direct download from code.visualstudio.com..."
        $url = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user'
        $dst = Join-Path $env:TEMP 'VSCodeUserSetup.exe'
        try {
            Invoke-WebRequest -Uri $url -OutFile $dst -UseBasicParsing -ErrorAction Stop
            Write-Note "Launching the VS Code installer silently (this is fully automatic)..."
            Start-Process -FilePath $dst -ArgumentList '/VERYSILENT','/MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait
            Refresh-Path
            if (Test-Cmd 'code') { $installed = $true }
        } catch {
            Write-Err  "Could not download VS Code: $($_.Exception.Message)"
            Write-Note "Manual download: https://code.visualstudio.com/"
        }
    }
    if ($installed) { Write-Ok "VS Code installed." } else { Write-Err "VS Code install failed -- please install manually then re-run this script." }
}

# ---------------------------------------------------------------------------
# 3. Cline extension
# ---------------------------------------------------------------------------
Write-Phase 3 "Install Cline (the chat panel inside VS Code)"

if (Test-Cmd 'code') {
    $extId = 'saoudrizwan.claude-dev'
    $existing = @(& code --list-extensions 2>$null)
    if ($existing -contains $extId) {
        Write-Skip "Cline ($extId) is already installed."
    } else {
        Write-Note "Running: code --install-extension $extId --force"
        & code --install-extension $extId --force 2>&1 | Out-Host
        $existing = @(& code --list-extensions 2>$null)
        if ($existing -contains $extId) { Write-Ok "Cline installed." } else { Write-Err "Cline install failed -- open VS Code and search the Extensions panel for 'Cline'." }
    }
} else {
    Write-Err "VS Code 'code' command not found -- skipping Cline install."
    Write-Note "After VS Code is installed, re-run this script."
}

# ---------------------------------------------------------------------------
# 4. Pull baseline AI model (mandatory)
# ---------------------------------------------------------------------------
Write-Phase 4 "Download the AI brain (Qwen3-Coder 7B, ~5 GB)"

if (Test-Cmd 'ollama') {
    $list = @()
    try { $list = (& ollama list 2>$null) -split "`n" | Where-Object { $_ -and ($_ -notmatch '^NAME') } | ForEach-Object { ($_ -split '\s+')[0].Trim() } } catch {}

    function Has-Model([string]$name) {
        $base = ($name -split ':')[0]
        foreach ($m in $script:list) { if ($m -eq $name -or $m -like "$base*") { return $true } }
        return $false
    }

    if (Has-Model 'qwen3-coder:7b') {
        Write-Skip "qwen3-coder:7b already downloaded."
    } else {
        Write-Note "Pulling qwen3-coder:7b -- this is the big download. Time depends on your connection."
        & ollama pull qwen3-coder:7b
        if ($LASTEXITCODE -eq 0) { Write-Ok "qwen3-coder:7b downloaded." } else { Write-Err "Pull failed (exit $LASTEXITCODE). Re-run this script to retry." }
    }

    # ---------------------------------------------------------------------------
    # 5. Optional bigger model
    # ---------------------------------------------------------------------------
    Write-Phase 5 "Optional: bigger / smarter model (Qwen3-Coder 30B-A3B, ~18 GB)"

    if (Has-Model 'qwen3-coder:30b-a3b') {
        Write-Skip "qwen3-coder:30b-a3b already downloaded."
    } elseif ($SkipOptionalModel) {
        Write-Skip "Skipping (SkipOptionalModel flag set)."
    } else {
        Write-Host ""
        Write-Host "  The 30B-A3B model is much smarter for hard tasks but is an 18 GB"
        Write-Host "  download and needs an NVIDIA GPU with 16 GB+ VRAM (RTX 5080 etc)."
        Write-Host "  You can always pull it later by running this installer again."
        Write-Host ""
        if (Confirm-YN 'Download the bigger 30B-A3B model now?' 'N') {
            & ollama pull qwen3-coder:30b-a3b
            if ($LASTEXITCODE -eq 0) { Write-Ok "qwen3-coder:30b-a3b downloaded." } else { Write-Err "Pull failed (exit $LASTEXITCODE)." }
        } else {
            Write-Skip "Skipped 30B-A3B."
        }
    }

    if ($InstallDeepSeek -and -not (Has-Model 'deepseek-r1:14b')) {
        Write-Phase '5b' "Pull DeepSeek R1 14B (reasoning model, ~8 GB)"
        & ollama pull deepseek-r1:14b
        if ($LASTEXITCODE -eq 0) { Write-Ok "deepseek-r1:14b downloaded." }
    }
} else {
    Write-Err "Ollama not available -- cannot download AI models."
}

# ---------------------------------------------------------------------------
# 6. Desktop shortcut "AI Mod Helper"
# ---------------------------------------------------------------------------
Write-Phase 6 "Create the 'AI Mod Helper' shortcut on your Desktop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot    = Split-Path -Parent $ScriptDir
$LauncherBat = Join-Path $RepoRoot 'AI-MOD-HELPER.bat'
$Desktop     = [Environment]::GetFolderPath('Desktop')
$LinkPath    = Join-Path $Desktop 'AI Mod Helper.lnk'

if (-not (Test-Path $LauncherBat)) {
    Write-Warn "Launcher AI-MOD-HELPER.bat not found in the extracted folder -- skipping shortcut."
} else {
    try {
        $sh = New-Object -ComObject WScript.Shell
        $sc = $sh.CreateShortcut($LinkPath)
        $sc.TargetPath       = $LauncherBat
        $sc.WorkingDirectory = $RepoRoot
        $sc.IconLocation     = "$env:SystemRoot\System32\shell32.dll,167"
        $sc.Description      = 'Open VS Code at your Cyberpunk 2077 mod folder with the local AI helper ready.'
        $sc.Save()
        Write-Ok "Shortcut created: $LinkPath"
    } catch {
        Write-Warn "Could not create Desktop shortcut: $($_.Exception.Message)"
        Write-Note "You can still launch by double-clicking AI-MOD-HELPER.bat in this folder."
    }
}

# ---------------------------------------------------------------------------
# 7. Open the first-time setup guide
# ---------------------------------------------------------------------------
Write-Phase 7 "Open the first-time setup guide"

$Guide = Join-Path $RepoRoot 'CLINE-FIRST-TIME-SETUP.txt'
if (Test-Path $Guide) {
    if (-not $NoLaunch) {
        try { Start-Process notepad.exe -ArgumentList "`"$Guide`"" } catch { Write-Warn "Could not open Notepad." }
        Write-Ok "Opened CLINE-FIRST-TIME-SETUP.txt in Notepad."
    } else {
        Write-Skip "NoLaunch flag set -- guide path: $Guide"
    }
} else {
    Write-Warn "CLINE-FIRST-TIME-SETUP.txt missing from the extracted folder."
}

# ---------------------------------------------------------------------------
# 8. Done
# ---------------------------------------------------------------------------
Write-Banner "ALL DONE"
Write-Host ""
Write-Host "  Next steps (also in the Notepad window that just opened):"
Write-Host ""
Write-Host "  1. Double-click 'AI Mod Helper' on your Desktop." -ForegroundColor Cyan
Write-Host "  2. When asked, point it at your Cyberpunk 2077 mod folder."
Write-Host "  3. VS Code opens with the Cline robot icon in the left sidebar."
Write-Host "  4. Click the robot. It asks you to pick a provider:"
Write-Host "       - API Provider:  pick  Ollama"
Write-Host "       - Base URL:      http://localhost:11434/    (already there)"
Write-Host "       - Model:         pick  qwen3-coder:7b"
Write-Host "     ...and you're chatting with your local AI."
Write-Host ""
Write-Host "  Tip: drag any file from the VS Code sidebar onto the Cline chat"
Write-Host "       to give the AI context, then ask it to edit, refactor, or"
Write-Host "       create new mod files. It shows you the diff and asks 'Save?'"
Write-Host "       before touching anything."
Write-Host ""
exit 0
