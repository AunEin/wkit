<#
.SYNOPSIS
  AI Mod Helper -- launches VS Code at your CP2077 mod folder so the local
  AI (Cline + Ollama) is ready to edit/create files for you.

.DESCRIPTION
  - If you pass -Path, it opens VS Code there immediately.
  - Otherwise it pops up a friendly Windows folder-picker.
  - Remembers the last folder you used so the next launch is one click.
#>

[CmdletBinding()]
param(
    [string] $Path
)

$ErrorActionPreference = 'Continue'

# Load WinForms up-front so the early-exit MessageBox calls below work too.
Add-Type -AssemblyName System.Windows.Forms

function Test-Cmd($n) { $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

# ---------------------------------------------------------------------------
# Sanity: make sure VS Code is installed
# ---------------------------------------------------------------------------
if (-not (Test-Cmd 'code')) {
    [System.Windows.Forms.MessageBox]::Show(
        "VS Code is not installed (or not on PATH).`n`nRun INSTALL-EVERYTHING.bat first to set everything up.",
        "AI Mod Helper",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    exit 1
}

# ---------------------------------------------------------------------------
# Sanity: make sure Ollama is responding (warn but don't block)
# ---------------------------------------------------------------------------
$ollamaUp = $false
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    if ($r.StatusCode -eq 200) { $ollamaUp = $true }
} catch {}

if (-not $ollamaUp) {
    Write-Host ""
    Write-Host "  Ollama isn't responding. Trying to start it..." -ForegroundColor Yellow
    if (Test-Cmd 'ollama') {
        $ollamaExe = (Get-Command ollama -ErrorAction SilentlyContinue).Source
        if (-not $ollamaExe) { $ollamaExe = 'ollama.exe' }
        try { Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden } catch {}
        Start-Sleep -Seconds 4
    }
}

# ---------------------------------------------------------------------------
# Pick the mod folder
# ---------------------------------------------------------------------------
$rememberPath = Join-Path $env:APPDATA 'cp2077-ai-helper\last-folder.txt'

if (-not $Path) {
    $initial = ''
    if (Test-Path $rememberPath) {
        try {
            $cand = (Get-Content $rememberPath -Raw).Trim()
            if ($cand -and (Test-Path $cand)) { $initial = $cand }
        } catch {}
    }

    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description       = "Pick the folder you want the AI to work in (your mod folder)."
    $dlg.ShowNewFolderButton = $true
    if ($initial) { $dlg.SelectedPath = $initial }

    $result = $dlg.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        exit 0
    }
    $Path = $dlg.SelectedPath
}

if (-not (Test-Path $Path)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Folder not found:`n$Path",
        "AI Mod Helper",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

# Remember for next time
try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $rememberPath) | Out-Null
    Set-Content -Path $rememberPath -Value $Path -Encoding UTF8
} catch {}

# ---------------------------------------------------------------------------
# Open VS Code
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  Opening VS Code at: $Path" -ForegroundColor Cyan
Write-Host "  When VS Code opens, click the Cline robot icon in the LEFT sidebar."
Write-Host ""

# `code` is a .cmd shim, so we need cmd.exe
Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','code',('"' + $Path + '"') -WindowStyle Hidden
exit 0
