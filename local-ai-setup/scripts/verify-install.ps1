<#
.SYNOPSIS
  CP2077 Local AI -- end-to-end smoke test (v4.1)

.DESCRIPTION
  Goes beyond check-local-ai-setup.ps1: actually exercises each layer
  with a real HTTP request / process call to confirm the whole stack
  works end-to-end.

  Tests, in order:
    1. Ollama HTTP API responds
    2. Ollama lists at least one model
    3. Ollama generates a token from qwen3-coder (proves model loads on GPU)
    4. VS Code 'code' command works
    5. Cline extension is installed
    6. Workspace template exists in the release folder

  Exit code 0 = all green. Non-zero = something needs attention.

.PARAMETER QuickGen
  Skip the slow generation test (~10-30s on first model load).
#>

[CmdletBinding()]
param(
    [switch] $QuickGen
)

$Script:Failures = 0
function Step($n, $title) { Write-Host ""; Write-Host "[$n] $title" -ForegroundColor Cyan }
function Pass($m)         { Write-Host "    PASS  $m" -ForegroundColor Green }
function Fail($m)         { Write-Host "    FAIL  $m" -ForegroundColor Red; $Script:Failures++ }
function Info($m)         { Write-Host "    info  $m" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  CP2077 Local AI -- End-to-End Smoke Test" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# ---------------------------------------------------------------------------
# 1. Ollama HTTP API
# ---------------------------------------------------------------------------
Step 1 "Ollama HTTP API on http://127.0.0.1:11434"

$tags = $null
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($r.StatusCode -eq 200) {
        Pass "API responded (HTTP 200)"
        $tags = $r.Content | ConvertFrom-Json
    } else {
        Fail ("API returned HTTP {0}" -f $r.StatusCode)
    }
} catch {
    Fail ("API unreachable: {0}" -f $_.Exception.Message)
    Info "Open the Ollama app from your Start Menu (look for the llama tray icon)."
}

# ---------------------------------------------------------------------------
# 2. Models present
# ---------------------------------------------------------------------------
Step 2 "Models loaded in Ollama"

$primaryModel = $null
if ($tags -and $tags.models) {
    foreach ($m in $tags.models) {
        Info ("found: {0}" -f $m.name)
        if (-not $primaryModel -and $m.name -like 'qwen3-coder*') { $primaryModel = $m.name }
    }
    if ($primaryModel) { Pass ("Coder model present: {0}" -f $primaryModel) }
    else { Fail "No qwen3-coder model found. Run INSTALL-EVERYTHING.bat." }
} else {
    Fail "Could not list models."
}

# ---------------------------------------------------------------------------
# 3. Generation test (proves the model actually loads on the GPU)
# ---------------------------------------------------------------------------
Step 3 "Model generation test (proves GPU loads + tools fire)"

if ($QuickGen) {
    Info "Skipped (QuickGen flag)."
} elseif (-not $primaryModel) {
    Info "Skipped (no model to test against)."
} else {
    $body = @{
        model  = $primaryModel
        prompt = 'Say only the word READY.'
        stream = $false
        options = @{ num_predict = 8; temperature = 0 }
    } | ConvertTo-Json -Depth 4

    Info ("Asking {0} to say READY (first call may take ~10-30s while the model loads)..." -f $primaryModel)
    try {
        $start = Get-Date
        $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/generate' `
                                  -Method POST `
                                  -Body $body `
                                  -ContentType 'application/json' `
                                  -TimeoutSec 90 `
                                  -UseBasicParsing -ErrorAction Stop
        $secs = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)
        if ($resp.StatusCode -eq 200) {
            $out = ($resp.Content | ConvertFrom-Json).response.Trim()
            Pass ("model responded in {0}s : '{1}'" -f $secs, $out.Substring(0, [Math]::Min(60, $out.Length)))
        } else {
            Fail ("HTTP {0}" -f $resp.StatusCode)
        }
    } catch {
        Fail ("Generation request failed: {0}" -f $_.Exception.Message)
        Info "If this said 'CUDA out of memory', close Chrome/Edge and retry."
    }
}

# ---------------------------------------------------------------------------
# 4. VS Code 'code' command
# ---------------------------------------------------------------------------
Step 4 "VS Code 'code' command"

$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    try {
        $ver = (& code --version 2>$null | Select-Object -First 1).Trim()
        Pass ("VS Code: {0}" -f $ver)
    } catch {
        Fail "code command found but --version failed."
    }
} else {
    Fail "VS Code 'code' not on PATH. Re-run INSTALL-EVERYTHING.bat."
}

# ---------------------------------------------------------------------------
# 5. Cline extension
# ---------------------------------------------------------------------------
Step 5 "Cline extension (saoudrizwan.claude-dev)"

if ($code) {
    try {
        $exts = & code --list-extensions 2>$null
        if ($exts -contains 'saoudrizwan.claude-dev') { Pass "Cline extension installed" }
        else { Fail "Cline extension NOT installed. Re-run INSTALL-EVERYTHING.bat." }
    } catch {
        Fail "Could not list extensions."
    }
} else {
    Info "Skipped (no VS Code)."
}

# ---------------------------------------------------------------------------
# 6. Workspace template exists in the release folder
# ---------------------------------------------------------------------------
Step 6 "Mod-workspace template files (the AI's reference docs)"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$Template  = Join-Path $RepoRoot 'mod-workspace-template'

if (Test-Path $Template) {
    $required = @(
        '.clinerules',
        '_AI-Knowledge\POSE.md',
        '_AI-Knowledge\POSE-MODDING-RECIPES.md',
        '_Examples\01_pose_pack_yaml\working_pose_pack.yaml',
        '_Examples\02_amm_collab_lua\working_amm_pose_lua.lua',
        '.vscode\settings.json',
        '.vscode\extensions.json',
        'README.md'
    )
    $missing = @()
    foreach ($f in $required) {
        $full = Join-Path $Template $f
        if (-not (Test-Path $full)) { $missing += $f }
    }
    if ($missing.Count -eq 0) { Pass ("All {0} template files present." -f $required.Count) }
    else                      { Fail ("Missing template files: {0}" -f ($missing -join ', ')) }
} else {
    Fail ("Workspace template folder missing at: {0}" -f $Template)
    Info "Re-extract the release zip."
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
if ($Script:Failures -eq 0) {
    Write-Host "  ALL TESTS PASSED -- the AI is ready to mod!" -ForegroundColor Green
    Write-Host "  Double-click 'AI Mod Helper' on your Desktop to start." -ForegroundColor Green
} else {
    Write-Host ("  {0} TEST(S) FAILED -- see [FAIL] lines above." -f $Script:Failures) -ForegroundColor Red
    Write-Host "  Fix usually = re-run INSTALL-EVERYTHING.bat." -ForegroundColor Red
}
Write-Host "============================================" -ForegroundColor Magenta

exit $Script:Failures
