<#
.SYNOPSIS
  CP2077 Local AI Modding Setup Checker v3.0 (OpenCode Edition)

.DESCRIPTION
  Verifies that everything needed to run a private, local, agentic AI for
  Cyberpunk 2077 modding is installed:
    - NVIDIA GPU + driver
    - Ollama (engine) + required models
    - OpenCode (agentic UI) + opencode.json pointing at Ollama
    - Optionally: WolvenKit, .NET 8, AnythingLLM, CET, REDmod

  With -DownloadMissing it will offer (Y/N) to `ollama pull` any missing models.
  With -WriteConfig it will install %APPDATA%\opencode\opencode.json (the
  drop-in config that ships beside this script).

.PARAMETER DownloadMissing
  Prompt to ollama-pull each missing AI model.

.PARAMETER WriteConfig
  Install opencode.json into %APPDATA%\opencode\ (idempotent; backs up any
  existing file as opencode.json.bak).

.PARAMETER GamePath
  Optional path to the Cyberpunk 2077 install root. When supplied, also
  checks for CET (under bin\x64\plugins\cyber_engine_tweaks) and REDmod
  (the `mods` folder).

.PARAMETER SaveLog
  Mirror all output to setup-check-YYYYMMDD-HHmm.log in the script folder.

.EXAMPLE
  .\check-local-ai-setup.ps1
  .\check-local-ai-setup.ps1 -DownloadMissing -WriteConfig
  .\check-local-ai-setup.ps1 -GamePath "C:\Steam\steamapps\common\Cyberpunk 2077"
#>

[CmdletBinding()]
param(
    [switch] $DownloadMissing,
    [switch] $WriteConfig,
    [string] $GamePath,
    [switch] $SaveLog
)

# ---------------------------------------------------------------------------
# Bookkeeping
# ---------------------------------------------------------------------------
$Script:HasError       = $false
$Script:HasWarn        = $false
$Script:NextStepHint   = $null
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir   # parent of /scripts/

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

function Test-Cmd($name) {
    $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Confirm-YN($question, $default = 'N') {
    $suffix = if ($default -eq 'Y') { '[Y/n]' } else { '[y/N]' }
    $resp = Read-Host "$question $suffix"
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = $default }
    return $resp.Trim().ToUpper().StartsWith('Y')
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  CP2077 Local AI Modding Setup Checker v3.0" -ForegroundColor Magenta
Write-Host "  (OpenCode Edition)"                          -ForegroundColor Magenta
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
    if     ($vramMB -ge 16000) { Write-Ok "VRAM: 16 GB+ -- can run qwen3-coder:30b-a3b comfortably" }
    elseif ($vramMB -ge 12000) { Write-Warn "VRAM: 12-16 GB -- qwen3-coder:30b-a3b will partially offload to CPU; smoother with qwen3-coder:7b" }
    elseif ($vramMB -ge  8000) { Write-Warn "VRAM: 8-12 GB -- prefer qwen3-coder:7b as your primary model" }
    else                       { Write-Err  "VRAM: under 8 GB -- local agentic models will be very slow"; Set-NextStep "Consider a smaller model like qwen3-coder:1.7b or use a cloud provider in opencode.json" }
} else {
    Write-Err "NVIDIA GPU not detected (nvidia-smi missing). Install/update NVIDIA drivers."
    Set-NextStep "Install latest NVIDIA Game Ready driver: https://www.nvidia.com/Download/index.aspx"
}

try {
    $drv = & nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>$null
    if ($LASTEXITCODE -eq 0 -and $drv) {
        Write-Ok ("NVIDIA Driver: {0}" -f ($drv -split "`n")[0].Trim())
    }
} catch {}

$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
if     ($ramGB -ge 32) { Write-Ok ("RAM: {0} GB total -- 32 GB+ enables CPU-offload for 27B/35B models" -f $ramGB) }
elseif ($ramGB -ge 16) { Write-Warn ("RAM: {0} GB total -- enough for primary models, but skip qwen3.5:27b" -f $ramGB) }
else                   { Write-Err  ("RAM: {0} GB total -- below 16 GB recommended minimum" -f $ramGB) }

$sysDrive = (Get-Item $env:SystemDrive).PSDrive
$freeGB   = [math]::Round($sysDrive.Free / 1GB, 0)
if     ($freeGB -ge 60) { Write-Ok   ("Disk Space: {0} GB free on {1}" -f $freeGB, $sysDrive.Name) }
elseif ($freeGB -ge 30) { Write-Warn ("Disk Space: {0} GB free on {1} -- tight if you want all optional models" -f $freeGB, $sysDrive.Name) }
else                    { Write-Err  ("Disk Space: only {0} GB free on {1} -- need 30 GB minimum" -f $freeGB, $sysDrive.Name) }

# ---------------------------------------------------------------------------
# OLLAMA
# ---------------------------------------------------------------------------
Write-Header "OLLAMA"

if (Test-Cmd 'ollama') {
    try { $ver = (& ollama --version) -join ' ' } catch { $ver = '<unknown>' }
    Write-Ok ("Ollama: {0}" -f $ver.Trim())

    $serverUp = $false
    try {
        $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        if ($resp.StatusCode -eq 200) { $serverUp = $true }
    } catch {}

    if ($serverUp) {
        Write-Ok "Ollama server: Running (port 11434)"
    } else {
        Write-Err "Ollama server: NOT running on port 11434"
        Set-NextStep "Open the Ollama app from your Start Menu (look for the llama tray icon), or run 'ollama serve' in PowerShell."
    }
} else {
    Write-Err "Ollama not installed."
    Set-NextStep "Download Ollama for Windows: https://ollama.com/download/windows"
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

# Required: name, label, install hint
$required = @(
    @{ name = 'qwen3-coder:30b-a3b'; label = 'Primary agentic coder (MoE, 16 GB VRAM sweet spot)'; pull = 'qwen3-coder:30b-a3b' },
    @{ name = 'qwen3-coder:7b';      label = 'Small/fast model (used as small_model in opencode.json)'; pull = 'qwen3-coder:7b' },
    @{ name = 'deepseek-r1:14b';     label = 'Reasoning/debugging model'; pull = 'deepseek-r1:14b' }
)
$optional = @(
    @{ name = 'qwen3.5:27b';     label = 'Optional dense powerhouse (needs 32 GB RAM)'; pull = 'qwen3.5:27b' },
    @{ name = 'nomic-embed-text';label = 'Optional: embeddings for AnythingLLM RAG'; pull = 'nomic-embed-text' }
)

function Test-ModelInstalled([string]$wanted) {
    foreach ($m in $script:installedModels) {
        if ($m -eq $wanted) { return $true }
        # Allow tag-less match: "qwen3-coder" ~ "qwen3-coder:30b-a3b"
        $base = ($wanted -split ':')[0]
        if ($m -like "$base*") { return $true }
    }
    return $false
}

foreach ($m in $required) {
    if (Test-ModelInstalled $m.name) {
        Write-Ok ("Model: {0}  --  {1}" -f $m.name, $m.label)
    } else {
        Write-Err ("Model missing: {0}  --  {1}" -f $m.name, $m.label)
        Set-NextStep ("Run:  ollama pull {0}" -f $m.pull)
        if ($DownloadMissing -and (Test-Cmd 'ollama')) {
            if (Confirm-YN ("    Download {0} now? (~several GB)" -f $m.name)) {
                Write-Host ("    Pulling {0}..." -f $m.pull) -ForegroundColor Cyan
                & ollama pull $m.pull
                if ($LASTEXITCODE -eq 0) { Write-Ok ("Pulled {0}" -f $m.name) }
                else                     { Write-Err ("ollama pull failed for {0}" -f $m.pull) }
            }
        }
    }
}

foreach ($m in $optional) {
    if (Test-ModelInstalled $m.name) {
        Write-Ok ("Optional model: {0}  --  {1}" -f $m.name, $m.label)
    } else {
        Write-Warn ("Optional model not found: {0} ({1})" -f $m.name, $m.label)
        if ($DownloadMissing -and (Test-Cmd 'ollama')) {
            if (Confirm-YN ("    Download optional {0} now?" -f $m.name)) {
                Write-Host ("    Pulling {0}..." -f $m.pull) -ForegroundColor Cyan
                & ollama pull $m.pull
                if ($LASTEXITCODE -eq 0) { Write-Ok ("Pulled {0}" -f $m.name) }
                else                     { Write-Err ("ollama pull failed for {0}" -f $m.pull) }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# OPENCODE
# ---------------------------------------------------------------------------
Write-Header "OPENCODE"

if (Test-Cmd 'opencode') {
    try { $ocVer = (& opencode --version 2>&1) -join ' ' } catch { $ocVer = '<unknown>' }
    Write-Ok ("OpenCode: {0}" -f $ocVer.Trim())
} else {
    Write-Err "OpenCode not installed (command 'opencode' not on PATH)."
    Set-NextStep "Install OpenCode:  scoop install opencode  -OR-  npm install -g opencode-ai  -OR-  download from https://github.com/sst/opencode/releases"
}

$cfgDir       = Join-Path $env:APPDATA 'opencode'
$cfgPath      = Join-Path $cfgDir 'opencode.json'
$bundledCfg   = Join-Path $RepoRoot 'opencode.json'

if (Test-Path $cfgPath) {
    $hasOllama = $false
    try {
        $cfgObj = Get-Content $cfgPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($cfgObj.provider.ollama) { $hasOllama = $true }
    } catch {
        Write-Warn ("opencode.json present but failed to parse: {0}" -f $_.Exception.Message)
    }
    if ($hasOllama) {
        Write-Ok ("Config: {0} (Ollama provider configured)" -f $cfgPath)
    } else {
        Write-Warn ("Config exists at {0} but does NOT define an Ollama provider." -f $cfgPath)
        Set-NextStep ("Replace it with the bundled opencode.json: copy `"{0}`" `"{1}`"" -f $bundledCfg, $cfgPath)
    }
} else {
    Write-Warn ("Config missing: {0}" -f $cfgPath)
    if ($WriteConfig) {
        if (Test-Path $bundledCfg) {
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            Copy-Item -Path $bundledCfg -Destination $cfgPath -Force
            Write-Ok ("Installed config: {0}" -f $cfgPath)
        } else {
            Write-Err ("Bundled opencode.json not found at {0}" -f $bundledCfg)
        }
    } else {
        Set-NextStep ("Re-run with -WriteConfig, or manually copy `"{0}`" to `"{1}`"" -f $bundledCfg, $cfgPath)
    }
}

# Offer to write config even when present-but-broken
if ($WriteConfig -and (Test-Path $cfgPath)) {
    try {
        $cfgObj = Get-Content $cfgPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if (-not $cfgObj.provider.ollama) {
            if (Confirm-YN "Overwrite the existing opencode.json with the bundled v3.0 config? (a backup .bak will be made)") {
                Copy-Item -Path $cfgPath -Destination "$cfgPath.bak" -Force
                Copy-Item -Path $bundledCfg -Destination $cfgPath -Force
                Write-Ok ("Replaced config (backup at {0}.bak)" -f $cfgPath)
            }
        }
    } catch {}
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
if ($wkPath) {
    Write-Ok ("WolvenKit: Found at {0}" -f $wkPath)
} else {
    Write-Warn "WolvenKit not found in common locations. (Skip if you intend to install it elsewhere.)"
}

# .NET 8
$dotnet8 = $false
try {
    $rids = & dotnet --list-runtimes 2>$null
    if ($rids -match 'Microsoft\.WindowsDesktop\.App 8\.') { $dotnet8 = $true }
} catch {}
if ($dotnet8) {
    Write-Ok ".NET Desktop Runtime 8.0: Installed"
} else {
    Write-Warn ".NET Desktop Runtime 8.0 not detected (required by WolvenKit)."
    Set-NextStep "Install .NET 8 Desktop Runtime: https://dotnet.microsoft.com/download/dotnet/8.0"
}

# CET / REDmod (only if -GamePath supplied)
if ($GamePath) {
    Write-Header "GAME TOOLS (CET / REDmod)"
    if (Test-Path $GamePath) {
        $cetPath = Join-Path $GamePath 'bin\x64\plugins\cyber_engine_tweaks'
        if (Test-Path $cetPath) { Write-Ok "Cyber Engine Tweaks: Installed" }
        else                    { Write-Warn ("CET not found at {0}" -f $cetPath); Set-NextStep "Install CET: https://www.nexusmods.com/cyberpunk2077/mods/107" }

        $redmodPath = Join-Path $GamePath 'tools\redmod'
        if (Test-Path $redmodPath) { Write-Ok "REDmod tools: Installed" }
        else                       { Write-Warn ("REDmod tools not found at {0} (install the free DLC via Steam/GOG/Epic)" -f $redmodPath) }
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
} elseif ($Script:HasWarn) {
    Write-Host "    PASSED with warnings -- see [WARN] lines above" -ForegroundColor Yellow
} else {
    Write-Host "    ALL CHECKS PASSED -- run 'opencode' in your mod folder!" -ForegroundColor Green
}
Write-Host "============================================" -ForegroundColor Magenta

if ($Script:NextStepHint) {
    Write-Host ""
    Write-Host ("  NEXT STEP: {0}" -f $Script:NextStepHint) -ForegroundColor Cyan
}

if ($SaveLog) { Stop-Transcript | Out-Null; Write-Host ("`n  Log saved to: {0}" -f $LogFile) -ForegroundColor DarkGray }

exit ([int]$Script:HasError)
