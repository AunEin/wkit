<#
.SYNOPSIS
  CP2077 Local AI Modding Setup Checker v4.3 (Cline + VS Code Edition)

.DESCRIPTION
  Verifies the "Easy Mode" stack:
    - NVIDIA GPU + driver
    - Ollama (engine) + required models
    - VS Code + Cline extension (the visual UI)
    - Optionally: WolvenKit, .NET 8, CET, REDmod, OpenCode (power-user TUI)

  This is a diagnostic tool. To actually INSTALL anything, run
  INSTALL-EVERYTHING.bat instead -- this script just checks.

  v4.3: baseline model is qwen2.5-coder:7b (was qwen3-coder:7b -- a
  tag that doesn't exist on Ollama). Optional bigger tag is
  qwen3-coder:30b-a3b-q4_K_M (the actual published 30B-A3B tag).

.PARAMETER GamePath
  Optional path to the Cyberpunk 2077 install root. When supplied, also
  checks for CET (under bin\x64\plugins\cyber_engine_tweaks) and REDmod.

.PARAMETER SaveLog
  Mirror all output to setup-check-YYYYMMDD-HHmm.log in the script folder.

.EXAMPLE
  .\check-local-ai-setup.ps1
  .\check-local-ai-setup.ps1 -GamePath "C:\Steam\steamapps\common\Cyberpunk 2077"
#>

[CmdletBinding()]
param(
    [string] $GamePath,
    [switch] $SaveLog
)

$Script:HasError       = $false
$Script:HasWarn        = $false
$Script:NextStepHint   = $null
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($SaveLog) {
    $stamp   = Get-Date -Format 'yyyyMMdd-HHmm'
    $LogFile = Join-Path $ScriptDir "setup-check-$stamp.log"
    Start-Transcript -Path $LogFile -Force | Out-Null
}

function Write-Header($t) { Write-Host ""; Write-Host "  --- $t ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Ok($m)     { Write-Host "  [OK]    $m"  -ForegroundColor Green }
function Write-Warn($m)   { Write-Host "  [WARN]  $m"  -ForegroundColor Yellow; $Script:HasWarn  = $true }
function Write-Err($m)    { Write-Host "  [FAIL]  $m"  -ForegroundColor Red;    $Script:HasError = $true }
function Set-NextStep($m) { if (-not $Script:NextStepHint) { $Script:NextStepHint = $m } }

function Test-Cmd($name) { $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  CP2077 Local AI Modding Setup Checker v4.3" -ForegroundColor Magenta
Write-Host "  (Cline + VS Code Easy Mode Edition)"        -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# ---------------------------------------------------------------------------
# SYSTEM
# ---------------------------------------------------------------------------
Write-Header "SYSTEM"

$gpuName = $null; $vramMB = 0
try {
    $smi = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>$null
    if ($LASTEXITCODE -eq 0 -and $smi) {
        $first = ($smi -split "`n")[0].Trim()
        $parts = $first -split ',', 2
        $gpuName = $parts[0].Trim()
        $vramMB  = [int]($parts[1].Trim())
    }
} catch {}

if ($gpuName) {
    Write-Ok ("NVIDIA GPU: {0} ({1} MB)" -f $gpuName, $vramMB)
    if     ($vramMB -ge 16000) { Write-Ok "VRAM: 16 GB+ -- can run qwen3-coder:30b-a3b-q4_K_M comfortably" }
    elseif ($vramMB -ge 12000) { Write-Warn "VRAM: 12-16 GB -- 30B-A3B will partially offload to CPU; smoother with qwen2.5-coder:7b" }
    elseif ($vramMB -ge  8000) { Write-Warn "VRAM: 8-12 GB -- prefer qwen2.5-coder:7b as your primary model" }
    else                       { Write-Err  "VRAM: under 8 GB -- local agentic models will be very slow"; Set-NextStep "Consider a smaller model or a cloud provider" }
} else {
    Write-Err "NVIDIA GPU not detected (nvidia-smi missing). Install/update NVIDIA drivers."
    Set-NextStep "Install latest NVIDIA Game Ready driver: https://www.nvidia.com/Download/index.aspx"
}

try {
    $drv = & nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>$null
    if ($LASTEXITCODE -eq 0 -and $drv) { Write-Ok ("NVIDIA Driver: {0}" -f ($drv -split "`n")[0].Trim()) }
} catch {}

$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
if     ($ramGB -ge 32) { Write-Ok ("RAM: {0} GB total" -f $ramGB) }
elseif ($ramGB -ge 16) { Write-Warn ("RAM: {0} GB total -- skip the optional 27B model" -f $ramGB) }
else                   { Write-Err  ("RAM: {0} GB total -- below 16 GB recommended minimum" -f $ramGB) }

$sysDrive = (Get-Item $env:SystemDrive).PSDrive
$freeGB   = [math]::Round($sysDrive.Free / 1GB, 0)
if     ($freeGB -ge 60) { Write-Ok   ("Disk Space: {0} GB free on {1}" -f $freeGB, $sysDrive.Name) }
elseif ($freeGB -ge 30) { Write-Warn ("Disk Space: {0} GB free on {1} -- tight if you want optional models" -f $freeGB, $sysDrive.Name) }
else                    { Write-Err  ("Disk Space: only {0} GB free on {1} -- need 30 GB minimum" -f $freeGB, $sysDrive.Name) }

# ---------------------------------------------------------------------------
# OLLAMA
# ---------------------------------------------------------------------------
Write-Header "OLLAMA"

if (Test-Cmd 'ollama') {
    try { $ver = (& ollama --version) -join ' ' } catch { $ver = '<unknown>' }
    Write-Ok ("Ollama: {0}" -f $ver.Trim())
    $serverUp = $false
    try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -eq 200) { $serverUp = $true } } catch {}
    if ($serverUp) { Write-Ok "Ollama server: Running (port 11434)" }
    else           { Write-Err "Ollama server: NOT running on port 11434"; Set-NextStep "Open the Ollama app from your Start Menu (look for the llama tray icon)." }
} else {
    Write-Err "Ollama not installed."
    Set-NextStep "Run INSTALL-EVERYTHING.bat (or manually: https://ollama.com/download/windows)"
}

# ---------------------------------------------------------------------------
# AI MODELS
# ---------------------------------------------------------------------------
Write-Header "AI MODELS"

$installedModels = @()
if (Test-Cmd 'ollama') {
    try {
        $rawList = (& ollama list 2>$null) -split "`n" | Where-Object { $_ -and ($_ -notmatch '^NAME') }
        foreach ($line in $rawList) {
            $name = ($line -split '\s+')[0].Trim()
            if ($name) { $installedModels += $name }
        }
    } catch {}
}

function Test-ModelInstalled([string]$wanted) {
    foreach ($m in $script:installedModels) {
        if ($m -eq $wanted) { return $true }
        $base = ($wanted -split ':')[0]
        if ($m -like "$base*") { return $true }
    }
    return $false
}

# v4.3 baseline: qwen2.5-coder:7b is what the installer actually pulls
# (qwen3-coder has no 7B variant on Ollama). Any qwen*-coder model counts
# as a working baseline for Cline's purposes.
$hasCoder = $false
foreach ($m in $script:installedModels) {
    if ($m -like 'qwen2.5-coder:*' -or $m -like 'qwen3-coder:*') { $hasCoder = $true; break }
}
if (Test-ModelInstalled 'qwen2.5-coder:7b') {
    Write-Ok ("Model: qwen2.5-coder:7b  --  Required baseline (~4.7 GB)")
} elseif ($hasCoder) {
    Write-Ok ("Coder model present (non-default tag) -- Cline will work")
} else {
    Write-Err ("Model missing: qwen2.5-coder:7b -- the baseline AI brain")
    Set-NextStep "Run INSTALL-EVERYTHING.bat (or:  ollama pull qwen2.5-coder:7b)"
}

foreach ($m in @(
    @{ name='qwen3-coder:30b-a3b-q4_K_M'; label='Optional bigger model (16 GB VRAM, smarter)' },
    @{ name='deepseek-r1:14b';            label='Optional reasoning/debugging model' },
    @{ name='qwen3.5:27b';                label='Optional dense powerhouse (32 GB RAM)' }
)) {
    if (Test-ModelInstalled $m.name) {
        Write-Ok ("Optional model: {0}  --  {1}" -f $m.name, $m.label)
    } else {
        Write-Warn ("Optional model not found: {0} ({1})" -f $m.name, $m.label)
    }
}

# ---------------------------------------------------------------------------
# VS CODE + CLINE  (the v4.0 main UI)
# ---------------------------------------------------------------------------
Write-Header "VS CODE + CLINE (the main UI)"

if (Test-Cmd 'code') {
    try { $codeVer = (& code --version 2>$null | Select-Object -First 1).Trim() } catch { $codeVer = '<unknown>' }
    Write-Ok ("VS Code: {0}" -f $codeVer)

    $extId = 'saoudrizwan.claude-dev'
    $exts  = @()
    try { $exts = & code --list-extensions 2>$null } catch {}
    if ($exts -contains $extId) {
        Write-Ok ("Cline extension ({0}) installed" -f $extId)
    } else {
        Write-Err ("Cline extension NOT installed ({0})" -f $extId)
        Set-NextStep "Run INSTALL-EVERYTHING.bat (or: code --install-extension saoudrizwan.claude-dev)"
    }
} else {
    Write-Err "VS Code not installed (or 'code' command not on PATH)."
    Set-NextStep "Run INSTALL-EVERYTHING.bat (or download: https://code.visualstudio.com/)"
}

# ---------------------------------------------------------------------------
# OPTIONAL: OpenCode (power-user TUI)
# ---------------------------------------------------------------------------
Write-Header "OPENCODE (optional, advanced)"

if (Test-Cmd 'opencode') {
    try { $ocVer = (& opencode --version 2>&1) -join ' ' } catch { $ocVer = '<unknown>' }
    Write-Ok ("OpenCode: {0}" -f $ocVer.Trim())
    $cfgPath = Join-Path $env:APPDATA 'opencode\opencode.json'
    if (Test-Path $cfgPath) { Write-Ok ("OpenCode config: {0}" -f $cfgPath) } else { Write-Warn ("OpenCode config missing: {0}" -f $cfgPath) }
} else {
    Write-Warn "OpenCode not installed -- this is optional, only needed if you prefer a terminal UI."
}

# ---------------------------------------------------------------------------
# WOLVENKIT (optional)
# ---------------------------------------------------------------------------
Write-Header "WOLVENKIT (optional)"

$wkCandidates = @(
    'C:\CyberpunkModding\WolvenKit\WolvenKit.exe',
    'C:\WolvenKit\WolvenKit.exe',
    "$env:LOCALAPPDATA\WolvenKit\WolvenKit.exe",
    "$env:USERPROFILE\AppData\Local\WolvenKit\WolvenKit.exe"
)
$wkPath = $null
foreach ($p in $wkCandidates) { if (Test-Path $p) { $wkPath = $p; break } }
if ($wkPath) { Write-Ok ("WolvenKit: Found at {0}" -f $wkPath) } else { Write-Warn "WolvenKit not found in common locations." }

$dotnet8 = $false
try { $rids = & dotnet --list-runtimes 2>$null; if ($rids -match 'Microsoft\.WindowsDesktop\.App 8\.') { $dotnet8 = $true } } catch {}
if ($dotnet8) { Write-Ok ".NET Desktop Runtime 8.0: Installed" } else { Write-Warn ".NET Desktop Runtime 8.0 not detected (required by WolvenKit)."; Set-NextStep "Install .NET 8 Desktop Runtime: https://dotnet.microsoft.com/download/dotnet/8.0" }

if ($GamePath) {
    Write-Header "GAME TOOLS (CET / REDmod)"
    if (Test-Path $GamePath) {
        $cetPath = Join-Path $GamePath 'bin\x64\plugins\cyber_engine_tweaks'
        if (Test-Path $cetPath) { Write-Ok "Cyber Engine Tweaks: Installed" } else { Write-Warn ("CET not found at {0}" -f $cetPath); Set-NextStep "Install CET: https://www.nexusmods.com/cyberpunk2077/mods/107" }

        $redmodPath = Join-Path $GamePath 'tools\redmod'
        if (Test-Path $redmodPath) { Write-Ok "REDmod tools: Installed" } else { Write-Warn ("REDmod tools not found at {0}" -f $redmodPath) }
    } else {
        Write-Err ("GamePath does not exist: {0}" -f $GamePath)
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
if ($Script:HasError) {
    Write-Host "    SOME CHECKS FAILED -- see [FAIL] lines above" -ForegroundColor Red
    Write-Host "    Easiest fix: re-run INSTALL-EVERYTHING.bat"   -ForegroundColor Red
} elseif ($Script:HasWarn) {
    Write-Host "    PASSED with warnings -- see [WARN] lines above" -ForegroundColor Yellow
} else {
    Write-Host "    ALL CHECKS PASSED -- double-click 'AI Mod Helper' on your Desktop!" -ForegroundColor Green
}
Write-Host "============================================" -ForegroundColor Magenta

if ($Script:NextStepHint) {
    Write-Host ""
    Write-Host ("  NEXT STEP: {0}" -f $Script:NextStepHint) -ForegroundColor Cyan
}

if ($SaveLog) { Stop-Transcript | Out-Null; Write-Host ("`n  Log saved to: {0}" -f $LogFile) -ForegroundColor DarkGray }

exit ([int]$Script:HasError)
