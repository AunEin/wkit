# Local AI Setup for Cyberpunk 2077 Modding v3.0 (OpenCode + Ollama, RTX 5080 / Windows)

> **One-stop tutorial**: install a private, local, agentic AI on your RTX 5080 that **reads, writes, edits, and moves files in your mod project** — no cloud, no subscriptions, no copy-pasting code out of a chat window.
>
> **What's new in v3.0** — we replaced the chat-only AnythingLLM frontend with **OpenCode**, an agentic terminal UI that can directly edit, create, patch, and transfer files inside your mod folder. The AI now does the work; you just review and approve.

---

## Why v3.0 is better than v2.0

| | v2.0 (AnythingLLM) | **v3.0 (OpenCode)** |
|---|---|---|
| Chat with AI | ✅ | ✅ |
| RAG (search game files) | ✅ | ✅ (on-demand, no upload) |
| **Edit files on disk** | ❌ copy/paste manually | ✅ direct edits, with diff preview |
| **Create files on disk** | ❌ | ✅ |
| **Transfer/move files** | ❌ | ✅ via shell |
| **Run commands** (compile reds, pack archive) | ❌ | ✅ |
| Multi-step "do this whole task" | ❌ | ✅ agent loop |
| Approval prompts before writes | n/a | ✅ per-operation |

In short: v2.0 was a smart librarian. v3.0 is a junior modder who actually does the work.

---

## Table of Contents

1. [What You Need (Hardware & Software)](#1-what-you-need)
2. [Install Ollama (The AI Engine)](#2-install-ollama)
3. [Download the Best Models for Your GPU](#3-download-the-best-models)
4. [Install OpenCode (The Agentic UI)](#4-install-opencode)
5. [Configure OpenCode for Ollama](#5-configure-opencode-for-ollama)
6. [Use It on Your CP2077 Mod Project](#6-use-it-on-your-cp2077-mod-project)
7. [Install CP2077 Modding Tools](#7-install-cp2077-modding-tools)
8. [Optional: Keep AnythingLLM for Chat-Style Q&A](#8-optional-anythingllm)
9. [Workflow: How to Actually Use This for Modding](#9-workflow)
10. [Automation Script (Auto-Check Everything)](#10-automation-script)
11. [Troubleshooting](#11-troubleshooting)
12. [Links & Resources](#12-links--resources)

---

## 1. What You Need

### Hardware

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | Any NVIDIA GPU with 8+ GB VRAM | RTX 5080 (16 GB VRAM) |
| **RAM** | 16 GB | 32 GB |
| **Storage** | 30 GB free (AI models + tools) | 60 GB+ free |
| **CPU** | Any modern 4-core | 8-core or better |

> **Not an RTX 5080?** Any NVIDIA GPU with 8+ GB VRAM works (RTX 3060 12GB, RTX 4070, etc.). On <16 GB VRAM use the smaller `qwen3-coder:7b` instead of the 30B-A3B variant, and skip the optional powerhouse models.

### Software (all free)

| Software | What It Does | Download |
|----------|-------------|----------|
| **Ollama** | Runs AI models on your GPU (the engine) | https://ollama.com/download/windows |
| **OpenCode** ⭐ | Agentic TUI that edits/creates/moves your mod files | https://opencode.ai |
| **VS Code** (recommended) | Editor with built-in terminal — runs OpenCode in a tab | https://code.visualstudio.com |
| **WolvenKit** | Primary CP2077 mod creation tool | https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest |
| **Cyber Engine Tweaks (CET)** | Lua scripting framework for CP2077 | https://www.nexusmods.com/cyberpunk2077/mods/107 |
| **REDmod** | Official CDPR modding DLC (free) | Steam/GOG/Epic library |
| **AnythingLLM** (optional) | Chat-style RAG over uploaded docs (v2.0-style) | https://anythingllm.com/desktop |

---

## 2. Install Ollama

Ollama is the backend engine that actually runs AI models on your RTX 5080. It runs quietly in the background.

### Steps

1. Go to **https://ollama.com/download/windows**
2. Download the Windows installer
3. Run the installer (no admin required, installs to your home folder)
   > **Windows SmartScreen popup?** Click **"More info"** → **"Run anyway"**. Ollama is open-source.
4. Wait for it to finish — Ollama will start automatically in your system tray (look for the llama icon, bottom-right).

### Verify

Open **PowerShell** or **Command Prompt**:

```
ollama --version
```

You should see a version number like `ollama version 0.6.x`.

---

## 3. Download the Best Models

For OpenCode-style agentic file editing you need a model with **strong tool-calling**. Below is the loadout for the RTX 5080 (16 GB VRAM).

Open **PowerShell** and run these one at a time:

### Must-Have: Coding Agent (best tool-calling on 16 GB VRAM)

```powershell
ollama pull qwen3-coder:30b-a3b
```

> **Qwen3-Coder 30B-A3B** — Mixture-of-Experts (MoE) model with 30B total parameters but only ~3B active per token. State-of-the-art open coding model with excellent agentic tool-use (read/write/edit/bash). Fits 16 GB VRAM with Ollama's auto-offload, runs at ~50–80 tok/s on a 5080. **This is your primary OpenCode model.**

### Fast Fallback: Smaller Coder (instant responses, low VRAM)

```powershell
ollama pull qwen3-coder:7b
```

> Used by OpenCode as `small_model` for cheap operations like generating chat titles or quick explanations. Also a great main model if you only have 8–12 GB VRAM.

### Reasoning Model (debugging, hard problems)

```powershell
ollama pull deepseek-r1:14b
```

> **DeepSeek R1 14B** — Chain-of-thought reasoning. Switch to this when OpenCode is stuck on a tricky compile error or an obscure REDscript bug. ~70 tok/s on RTX 5080.

### Embedding Model (only needed if you also install AnythingLLM)

```powershell
ollama pull nomic-embed-text
```

> Skip this if you're not installing AnythingLLM. OpenCode reads files on demand and does **not** require an embedding model.

### Optional Powerhouse: Dense 27B (highest single-shot quality)

```powershell
ollama pull qwen3.5:27b
```

> All 27B parameters active per token = maximum reasoning depth. Needs **32 GB system RAM** (auto-splits between GPU and CPU). Slower but smarter for one-shot architectural questions.

### How Much Space?

| Model | Download Size | VRAM Usage | Fits 16 GB VRAM? |
|-------|--------------|------------|------------------|
| qwen3-coder:30b-a3b ⭐ | ~18 GB | ~14 GB (MoE sparsity) | ✅ Yes — primary |
| qwen3-coder:7b | ~5 GB | ~6 GB | ✅ Yes — small_model |
| deepseek-r1:14b | ~8 GB | ~10 GB | ✅ Yes |
| nomic-embed-text | ~275 MB | ~300 MB | ✅ Yes (optional) |
| qwen3.5:27b | ~17 GB | ~18+ GB | ⚠️ GPU+CPU split (32 GB+ RAM) |

> **One model loaded at a time.** Ollama auto-loads/unloads. Even though you download all of them, only the active model uses VRAM.

---

## 4. Install OpenCode

OpenCode is your friendly **agentic** UI. Unlike a chat window, it can:

- **Read** any file in your mod project
- **Write** new files (REDscript, Lua, JSON, XML, YAML, …)
- **Edit** existing files using exact-string replacements (with diff preview)
- **Apply patches** (multi-file edits in one go)
- **Run shell commands** — copy/move files, invoke `redscript-cli`, pack `.archive`s, run WolvenKit CLI
- **Search** your project with `grep` and `glob`
- **Web fetch** — grab a snippet from the wiki without leaving the TUI

Every destructive action prompts you for approval. Nothing happens behind your back.

### Install on Windows — pick ONE

**Option A — Scoop (recommended, easiest):**

```powershell
# Install Scoop once (skip if you already have it):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install OpenCode:
scoop install opencode
```

**Option B — npm (if you have Node.js 18+):**

```powershell
npm install -g opencode-ai
```

**Option C — Chocolatey:**

```powershell
choco install opencode
```

**Option D — Manual binary**: download the Windows zip from https://github.com/sst/opencode/releases/latest, extract, and add the folder to your PATH.

### Verify

```powershell
opencode --version
```

You should see `1.x.x` printed back.

---

## 5. Configure OpenCode for Ollama

OpenCode reads its config from one of two places (project beats global):

| Scope | Path |
|---|---|
| Global (all projects) | `%APPDATA%\opencode\opencode.json` |
| Per-project | `<your-mod-project>\opencode.json` |

### Recommended global config

Open **PowerShell** and create the global config in one shot:

```powershell
$cfg = @'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3-coder:30b-a3b",
  "small_model": "ollama/qwen3-coder:7b",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "qwen3-coder:30b-a3b": { "name": "Qwen3-Coder 30B-A3B (primary)" },
        "qwen3-coder:7b":      { "name": "Qwen3-Coder 7B (fast)" },
        "deepseek-r1:14b":     { "name": "DeepSeek R1 14B (reasoning)" },
        "qwen3.5:27b":         { "name": "Qwen 3.5 27B (powerhouse, 32 GB RAM)" }
      }
    }
  }
}
'@
$dir = "$env:APPDATA\opencode"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Set-Content -Path "$dir\opencode.json" -Value $cfg -Encoding UTF8
```

> A ready-made copy of this same JSON ships in the release zip as `opencode.json` — you can just drop it into `%APPDATA%\opencode\` instead of running the script.

### Switch model on the fly

Inside OpenCode, type `/model` and pick from the dropdown. The list mirrors what you defined in `models` above.

### Per-project override

If a specific mod needs a different default model, drop an `opencode.json` in that project's root with just:

```json
{ "$schema": "https://opencode.ai/config.json", "model": "ollama/deepseek-r1:14b" }
```

---

## 6. Use It on Your CP2077 Mod Project

### Start a session

```powershell
cd "C:\CyberpunkModding\MyMod"      # your mod folder (or any folder with mod sources)
opencode
```

The TUI opens. Type your request and hit Enter.

### What "the AI edits files" actually looks like

You: *"Create a Lua mod under `r6/scripts/` that doubles all weapon damage when V crouches. Wire it through CET's onUpdate."*

OpenCode will:

1. `glob` your project to find existing scripts and learn naming conventions
2. `read` any related files for context (e.g. existing CET configs)
3. Show you the **proposed file path** and **full content** of the new `.reds` / `.lua` file
4. Wait for your **y/N** approval
5. Write the file
6. Optionally `bash` `redscript-cli compile ...` to validate

You see every change before it lands. You can edit OpenCode's proposal inline, or reject and re-prompt.

### Built-in tools you'll use most

| Tool | What it does | Trigger |
|---|---|---|
| `read` | Reads a file you reference | "look at `r6/scripts/Foo.reds`" |
| `write` | Creates/overwrites a file | "create a new mod at …" |
| `edit` | Exact-string replacement, in place | "change line X in Foo.reds to …" |
| `apply_patch` | Multi-file diff in one go | "refactor this across A, B, C" |
| `bash` | Runs any shell command | "compile it", "copy this to r6\\scripts" |
| `grep` | Regex search across the project | "find every call to `GetPlayer()`" |
| `glob` | Find files by pattern | "list all `.reds` under modules/" |
| `webfetch` | Grab a URL for context | "look up the EquipmentSystem on nativedb" |

### File transfer / moving files

OpenCode doesn't have a dedicated `mv` tool — it uses `bash`. Just ask:

> "Move all .reds files from `dist/scripts` into the game's `r6\scripts` folder."

It will propose:

```powershell
Move-Item -Path "dist\scripts\*.reds" -Destination "C:\Steam\...\Cyberpunk 2077\r6\scripts\" -Force
```

…and wait for your approval.

---

## 7. Install CP2077 Modding Tools

### WolvenKit (Mod Creation IDE)

1. Download from: https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest
2. **Requires**: .NET Desktop Runtime 8.0.x — https://dotnet.microsoft.com/download/dotnet/8.0
3. Extract to a folder like `C:\CyberpunkModding\WolvenKit\` (NOT inside the game directory)
4. Run `WolvenKit.exe`
5. On first launch, set your **Game Executable Path** to your `Cyberpunk2077.exe`:
   - **Steam**: `C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe`
   - **GOG**: `C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077\bin\x64\Cyberpunk2077.exe`

### Cyber Engine Tweaks (CET)

1. Download latest from https://www.nexusmods.com/cyberpunk2077/mods/107 (or https://github.com/maximegmd/CyberEngineTweaks/releases)
2. Extract `cet_x_xx_x.zip`
3. Copy the `bin` folder into your Cyberpunk 2077 game directory (it merges with the existing `bin` folder)
4. Disable Steam/Discord/GeForce overlays — they block the CET console

### REDmod (Official CDPR DLC)

1. Open Steam / GOG / Epic
2. Search your DLC list for **"Cyberpunk 2077 REDmod"**
3. Install it (free)

### Verify your mod folder structure

```
Cyberpunk 2077/
  bin/x64/plugins/cyber_engine_tweaks/mods/    <-- Your Lua mods
  r6/scripts/                                   <-- REDscript mods
  archive/pc/mod/                               <-- Archive mods
  mods/                                         <-- REDmod-compatible mods
```

---

## 8. Optional: AnythingLLM

If you also want a chat-style "ask the wiki" experience (the v2.0 workflow), AnythingLLM still works great alongside OpenCode. Install it from https://anythingllm.com/desktop and point it at your local Ollama (`http://127.0.0.1:11434`) — see the [v2.0 guide](https://github.com/sinica57pls-dot/CP2077/blob/main/testtest.md) for the full RAG-upload walkthrough.

**Rule of thumb:**
- **OpenCode** for *doing things* in your mod project (edit, create, refactor, run commands)
- **AnythingLLM** for *asking things* about a frozen knowledge base (uploaded decompiled scripts, wiki dumps)

You can run both at once — they share the same Ollama backend.

---

## 9. Workflow

### Starting a new mod

```powershell
mkdir C:\CyberpunkModding\MyAwesomeMod
cd    C:\CyberpunkModding\MyAwesomeMod
opencode
```

Then prompt:

> "Scaffold a new CET mod called 'CrouchDamage' that doubles weapon damage when crouching. Set up the standard folder structure, write `init.lua`, and create a README."

OpenCode creates the entire skeleton, file by file, asking approval for each write.

### Editing an existing mod

```powershell
cd "C:\Steam\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\SomeMod"
opencode
```

> "Read all the lua files in this mod and explain what it does."
>
> "Now add a hotkey binding so F7 toggles the effect on/off."

### Debugging compile errors

> "I just ran `redscript-cli compile r6/scripts` and got this error: [paste]. Look at the relevant files and fix it."

Switch to the reasoning model first: `/model` → `deepseek-r1:14b`.

### Refactoring across files

> "Rename the class `MyHelper` to `WeaponHelper` everywhere in this project, including all references."

OpenCode uses `apply_patch` to do all edits in a single reviewed diff.

### Transferring built mod into the game folder

> "Pack the `dist/` folder into `MyMod.zip` and copy the contents into the game's `archive/pc/mod/` folder."

---

## 10. Automation Script

The release zip ships a PowerShell script that checks if everything is installed correctly and offers to download missing models for you.

**File**: `scripts\check-local-ai-setup.ps1`

### What it checks

- NVIDIA GPU detected and VRAM size
- NVIDIA driver version
- System RAM
- Disk space
- Ollama installed and server running
- Required models downloaded (`qwen3-coder:30b-a3b`, `qwen3-coder:7b`, `deepseek-r1:14b`)
- OpenCode installed (and version)
- `%APPDATA%\opencode\opencode.json` present and references the Ollama provider
- Optional: AnythingLLM, WolvenKit, .NET 8, CET, REDmod (if game path is provided)

### How to run (the easy way)

1. **Extract the release zip** anywhere on your PC
2. **Double-click `RUN-SETUP-CHECK.bat`** — it checks your system and tells you what's missing
3. **Double-click `RUN-SETUP-AND-DOWNLOAD.bat`** — it downloads anything missing and writes your `opencode.json` for you

> No PowerShell knowledge needed. No command line. Just double-click.

### How to run (the script directly)

```powershell
# Basic check (AI tools only):
.\scripts\check-local-ai-setup.ps1

# Auto-download missing models + write opencode.json:
.\scripts\check-local-ai-setup.ps1 -DownloadMissing -WriteConfig

# Full check including CP2077 game tools:
.\scripts\check-local-ai-setup.ps1 -GamePath "C:\Steam\steamapps\common\Cyberpunk 2077"

# Save output to a log file:
.\scripts\check-local-ai-setup.ps1 -SaveLog
```

### Sample output

```
============================================
  CP2077 Local AI Modding Setup Checker v3.0
============================================

  --- SYSTEM ---
  [OK]    NVIDIA GPU: NVIDIA GeForce RTX 5080 (16384 MB)
  [OK]    NVIDIA Driver: 572.83
  [OK]    RAM: 32 GB total
  [OK]    Disk Space: 123 GB free on C:

  --- OLLAMA ---
  [OK]    Ollama: ollama version 0.6.2
  [OK]    Ollama server: Running (port 11434)

  --- AI MODELS ---
  [OK]    Model: qwen3-coder:30b-a3b (18 GB) -- Primary agentic coder
  [OK]    Model: qwen3-coder:7b (5 GB)        -- Small/fast model
  [OK]    Model: deepseek-r1:14b (8 GB)       -- Reasoning/debugging
  [WARN]  Optional model not found: qwen3.5:27b

  --- OPENCODE ---
  [OK]    OpenCode: 1.4.7
  [OK]    Config: %APPDATA%\opencode\opencode.json (Ollama provider configured)

  --- WOLVENKIT (optional) ---
  [OK]    WolvenKit: Found at C:\CyberpunkModding\WolvenKit\WolvenKit.exe
  [OK]    .NET Desktop Runtime 8.0: Installed

============================================
    ALL CHECKS PASSED -- run `opencode` in your mod folder!
============================================
```

---

## 11. Troubleshooting

### "opencode is not recognized as a command"

- Restart your terminal after installing
- If installed via Scoop: ensure `%USERPROFILE%\scoop\shims` is in your PATH
- If installed via npm: ensure `npm config get prefix` points somewhere on your PATH

### OpenCode says "no models available" or "provider error"

- Ollama isn't running. Check the system tray (llama icon)
- Open `http://127.0.0.1:11434` in a browser — you should see `Ollama is running`
- Verify your `opencode.json` `baseURL` ends with `/v1` (it's the OpenAI-compatible endpoint, NOT the bare Ollama API)

### "Model qwen3-coder:30b-a3b not found"

- The exact tag may have shifted. Run `ollama list` to see what you have, then:
  - `ollama pull qwen3-coder` (latest tag) **or**
  - update the `models` section of `opencode.json` to whatever name `ollama list` shows

### Tool calls fail / OpenCode just says it would do something but doesn't

- The model isn't tool-calling. The Qwen3-Coder family is trained for tools; if you've switched to a chat-only model (`qwen3.5:9b`, `llama3:8b`), switch back to a coder model
- Re-run the same prompt with `/model ollama/qwen3-coder:30b-a3b`

### "CUDA out of memory"

- Close Chrome/Edge or disable browser GPU acceleration
- Use the smaller `qwen3-coder:7b`
- Reduce OpenCode context: in opencode.json add `"options": { "num_ctx": 32768 }` under the model entry

### Ollama not auto-starting after reboot

- Search **"Ollama"** in the Start Menu and open it
- To make it persistent: **Task Manager** → **Startup apps** → enable Ollama

### "Running scripts is disabled on this system" (PowerShell)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Type **Y** when prompted.

---

## 12. Links & Resources

### AI Tools

| Tool | Link |
|------|------|
| Ollama | https://ollama.com |
| OpenCode ⭐ | https://opencode.ai · https://github.com/sst/opencode |
| AnythingLLM (optional) | https://anythingllm.com |
| LM Studio (optional) | https://lmstudio.ai |
| Open WebUI (optional) | https://github.com/open-webui/open-webui |

### AI Models (Ollama)

| Model | Pull Command | Notes |
|-------|-------------|-------|
| Qwen3-Coder 30B-A3B ⭐ | `ollama pull qwen3-coder:30b-a3b` | Primary agentic coder, MoE, fits 16 GB VRAM |
| Qwen3-Coder 7B | `ollama pull qwen3-coder:7b` | Small/fast model + small_model role |
| DeepSeek R1 14B | `ollama pull deepseek-r1:14b` | Reasoning/debugging |
| Qwen 3.5 27B (dense) | `ollama pull qwen3.5:27b` | Optional powerhouse, GPU+CPU offload (32 GB RAM) |
| Nomic Embed Text | `ollama pull nomic-embed-text` | Only needed if you also use AnythingLLM |

### CP2077 Modding

| Resource | Link |
|----------|------|
| WolvenKit (latest) | https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest |
| WolvenKit Wiki | https://wiki.redmodding.org/wolvenkit |
| Cyber Engine Tweaks | https://www.nexusmods.com/cyberpunk2077/mods/107 |
| CET Wiki | https://wiki.redmodding.org/cyber-engine-tweaks |
| REDmod (official) | https://www.cyberpunk.net/en/modding-support |
| CP2077 Modding Wiki | https://wiki.redmodding.org/cyberpunk-2077-modding |
| NativeDB (all classes/functions) | https://nativedb.red4ext.com |
| Nexus Mods (CP2077) | https://www.nexusmods.com/cyberpunk2077 |
| Codeware (REDscript framework) | https://github.com/psiberx/cp2077-codeware |
| RED4ext (native plugin loader) | https://github.com/WopsS/RED4ext |

---

## Quick Start Checklist

- [ ] NVIDIA drivers updated to latest
- [ ] Ollama installed and running
- [ ] `qwen3-coder:30b-a3b` model downloaded (primary)
- [ ] `qwen3-coder:7b` model downloaded (small_model)
- [ ] `deepseek-r1:14b` model downloaded (reasoning)
- [ ] OpenCode installed (`opencode --version` works)
- [ ] `%APPDATA%\opencode\opencode.json` created and points to Ollama
- [ ] WolvenKit installed with game path configured
- [ ] CET installed in game directory
- [ ] REDmod DLC installed
- [ ] Run `RUN-SETUP-CHECK.bat` — all green
- [ ] Run `opencode` inside your mod folder — TUI opens, model dropdown shows your local models

**You're ready to mod Cyberpunk 2077 with a private, local, agentic AI that actually edits your files.**

---

*Last updated: 2026-04-16 · v3.0 · OpenCode Edition*
