# Local AI Setup for Cyberpunk 2077 Modding v4.0 — Easy Mode Edition

> **One installer. One launcher. Zero typed commands.**
> A private, fully local AI assistant that helps you create / edit / fix Cyberpunk 2077 mods. Runs on your own RTX 5080 (or any 8 GB+ NVIDIA GPU). The AI lives inside **VS Code** as a friendly chat panel and can directly **read, write, edit, and run things** in your mod folder — with a click-to-approve button on every action.

---

## What changed from v3.0

| | v3.0 (OpenCode TUI) | **v4.0 (Easy Mode)** |
|---|---|---|
| Interface | Terminal (text-only) | **VS Code chat panel** (visual, click-to-approve) |
| Install steps | ~6 manual steps | **1 double-click** |
| Setup commands typed | several | **zero** |
| Visual diffs of file edits | text-only | **side-by-side colored diffs** |
| Recommended for non-coders | ❌ | **✅** |
| OpenCode terminal flow | included | still bundled as optional power-user path |

---

## How to install (the only section most people need)

### 1. Download the release zip

From [the releases page](https://github.com/AunEin/wkit/releases/latest), download `CP2077-AI-Setup-v4.0.zip` and **extract it anywhere** on your PC (Desktop, Documents, anywhere — just **not** inside the game folder).

### 2. Double-click `INSTALL-EVERYTHING.bat`

Windows will pop up a UAC window asking for admin rights — click **Yes**. (It's needed because the Ollama and VS Code installers want admin.)

The installer then runs by itself. It downloads + installs:

| What | Why | Size |
|---|---|---|
| **Ollama** | The AI engine — runs models on your GPU | ~500 MB |
| **VS Code** | The friendly editor that hosts the AI chat | ~100 MB |
| **Cline** (VS Code extension) | The chat panel where you talk to the AI | ~50 MB |
| **Qwen3-Coder 7B** (the AI brain) | Default model — fast, fits any 8 GB GPU | ~5 GB |

Total: about **6 GB** of downloads. Takes 10–30 minutes on a normal home connection.
You can leave it running and do something else.

It then:
- Asks **once** if you want the bigger 18 GB model (`qwen3-coder:30b-a3b`) for harder tasks. Y or N.
- Puts an **"AI Mod Helper"** icon on your Desktop.
- Opens a Notepad with the **3-click first-time setup guide** for Cline.

> **Already-installed parts are skipped.** If anything goes wrong partway through, just re-run `INSTALL-EVERYTHING.bat` — it picks up where it left off.

### 3. Double-click `AI Mod Helper` on your Desktop

A folder picker pops up. Choose your CP2077 mod folder (or any empty folder you want as a sandbox).

VS Code opens with that folder.

### 4. The 3 clicks inside VS Code

(These are also written out in the Notepad window the installer opened.)

1. Click the **robot icon** in the left sidebar (it says "Cline" on hover).
2. In the setup form that appears:
   - **API Provider** dropdown → pick **`Ollama`**
   - **Base URL** → leave it as `http://localhost:11434/`
   - **Model** dropdown → pick **`qwen3-coder:7b`** (or `qwen3-coder:30b-a3b` if you downloaded the bigger one)
3. Click **"Let's go!"** (or whatever the OK button says).

You're now chatting with your local AI. Try:

> *"List all files in this folder and tell me what you see."*

---

## What you can ask the AI

### Make a brand-new mod

> *"Make a new CET mod called CrouchDamage that doubles weapon damage when V is crouching. Wire it through CET's onUpdate hook."*

The AI will:
1. Plan the file structure
2. Show you the proposed `init.lua` (or `.reds`) — full content, in a diff view
3. Wait for you to click **Approve** before writing anything

### Edit an existing mod

> *"Read all the files in this folder and explain what this mod does."*
>
> *"Now add a hotkey: pressing F7 toggles the effect on/off."*

### Debug a compile error

> *"I ran `redscript-cli compile` and got this error: [paste]. Look at my files and fix it."*

Switch to the optional `deepseek-r1:14b` model first (re-run `INSTALL-EVERYTHING.bat` and answer **Y** to install it) — its chain-of-thought reasoning is great for tricky errors.

### Refactor across many files

> *"Rename the class `MyHelper` to `WeaponHelper` everywhere in this project."*

The AI will show every change as a single multi-file diff for one-click approval.

### Move / pack files

> *"Pack the dist folder into MyMod.zip and copy it into the game's `archive/pc/mod/` folder."*

The AI proposes the exact PowerShell commands and waits for your approval before running them.

---

## Hardware

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | NVIDIA, 8 GB VRAM | RTX 5080 (16 GB) |
| **RAM** | 16 GB | 32 GB |
| **Storage** | 30 GB free | 60 GB+ |
| **OS** | Windows 10 | Windows 11 |

If you don't have an NVIDIA GPU, the AI will still run — just much slower (CPU only). Apple Silicon Macs are also supported by Ollama, but this installer is Windows-only; the manual setup section below works fine there.

---

## Game tools you also need (one-time)

These aren't installed by `INSTALL-EVERYTHING.bat` because they're game-specific and most modders already have them:

| Tool | Purpose | Link |
|------|---------|------|
| **WolvenKit** | Mod creation IDE — required to extract and pack `.archive` files | https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest |
| **.NET Desktop Runtime 8.0** | Required by WolvenKit | https://dotnet.microsoft.com/download/dotnet/8.0 |
| **Cyber Engine Tweaks (CET)** | Lua scripting in-game | https://www.nexusmods.com/cyberpunk2077/mods/107 |
| **REDmod** | Free official CDPR DLC — needed to load `.reds` mods | Steam / GOG / Epic library |

Run the diagnostic script (`scripts\check-local-ai-setup.ps1 -GamePath "C:\Steam\steamapps\common\Cyberpunk 2077"`) and it will tell you which of these are missing.

---

## Picking the right model

The installer downloads **`qwen3-coder:7b`** by default — fast, fits any 8 GB GPU, smart enough for everyday modding tasks. You can switch models any time inside Cline (gear icon at the top of the chat panel → Model dropdown).

| Model | When to use it | Size | VRAM |
|---|---|---|---|
| **qwen3-coder:7b** ⭐ | Default — fast, small, runs anywhere | 5 GB | 6 GB |
| **qwen3-coder:30b-a3b** | Hard tasks, big refactors, RTX 5080 sweet spot | 18 GB | ~14 GB (MoE) |
| **deepseek-r1:14b** | Debugging, chain-of-thought reasoning | 8 GB | 10 GB |
| **qwen3.5:27b** (dense) | Maximum single-shot quality, needs 32 GB RAM | 17 GB | 18+ GB (offload) |

To pull any of these later, either:
- **Easy way**: re-run `INSTALL-EVERYTHING.bat` (it'll ask about the optional ones)
- **Direct way**: in Ollama's terminal, `ollama pull qwen3-coder:30b-a3b`

---

## When something goes wrong

### Re-running the installer fixes most things

`INSTALL-EVERYTHING.bat` is **idempotent** — already-installed pieces are skipped. If you got partway through and something broke, just double-click it again.

### The diagnostic checker

If you want to see exactly what's installed and what's missing without changing anything:

- Right-click `scripts\check-local-ai-setup.ps1` → **Run with PowerShell**
- Or from a PowerShell window in this folder: `.\scripts\check-local-ai-setup.ps1`

It prints a clear `[OK]` / `[WARN]` / `[FAIL]` for every component and a `NEXT STEP` hint at the bottom.

### Common issues

| Symptom | Fix |
|---|---|
| **"Cline can't see any models"** | Ollama isn't running. Look for the llama icon in your system tray (bottom-right). If it's not there, search "Ollama" in the Start Menu and open it. |
| **"AI is very slow"** | Switch to the smaller `qwen3-coder:7b` model. Close Chrome / Edge / other GPU-heavy apps to free VRAM. |
| **"Robot icon not in sidebar"** | Cline extension didn't install. In VS Code: Extensions tab → search "Cline" by saoudrizwan → Install. Or re-run `INSTALL-EVERYTHING.bat`. |
| **"UAC keeps blocking"** | Right-click `INSTALL-EVERYTHING.bat` → **Run as administrator**. |
| **"`code` is not recognized"** | VS Code didn't add itself to PATH. Re-run its installer and make sure "Add to PATH" is checked. |
| **"CUDA out of memory"** | Use the smaller 7B model. Close GPU-heavy apps. Update your NVIDIA driver. |

---

## Power-user / advanced section

### I want a terminal-only flow (no VS Code)

The release zip also includes `opencode.json` — a config for **OpenCode**, an agentic terminal UI (TUI) that does the same things as Cline but in a single terminal window with no editor needed.

1. Install OpenCode: `scoop install opencode` (or `npm install -g opencode-ai`)
2. Copy `opencode.json` from the zip to `%APPDATA%\opencode\opencode.json`
3. In any terminal: `cd <your-mod-folder>` then `opencode`

This is the v3.0 flow — it still works, just isn't the default any more.

### I want a chat-style RAG over uploaded docs (the v2.0 flow)

Install **AnythingLLM** from https://anythingllm.com/desktop and point it at your local Ollama (`http://127.0.0.1:11434`). Then drop `nomic-embed-text` into Ollama (`ollama pull nomic-embed-text`) and use AnythingLLM's workspace upload to feed it decompiled game scripts. Great for "ask the wiki" style questions, not great for editing files.

You can run all three (Cline, OpenCode, AnythingLLM) at the same time — they share the same Ollama backend.

### Manual install steps (no installer)

If `INSTALL-EVERYTHING.bat` isn't an option (locked-down work PC, Linux/Mac, etc.):

1. Install **Ollama**: https://ollama.com/download
2. `ollama pull qwen3-coder:7b`
3. Install **VS Code**: https://code.visualstudio.com/
4. In VS Code, install the **Cline** extension (Extensions tab → search "Cline" by saoudrizwan).
5. Open Cline → API Provider = **Ollama** → Base URL = `http://localhost:11434/` → Model = `qwen3-coder:7b`.

---

## Links

### AI tools

| Tool | Link |
|------|------|
| Ollama | https://ollama.com |
| VS Code | https://code.visualstudio.com |
| Cline (VS Code extension) | https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev |
| OpenCode (optional terminal UI) | https://opencode.ai · https://github.com/sst/opencode |
| AnythingLLM (optional chat/RAG) | https://anythingllm.com |
| LM Studio (optional model browser) | https://lmstudio.ai |

### CP2077 modding

| Resource | Link |
|----------|------|
| WolvenKit (latest) | https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest |
| WolvenKit Wiki | https://wiki.redmodding.org/wolvenkit |
| Cyber Engine Tweaks | https://www.nexusmods.com/cyberpunk2077/mods/107 |
| CET Wiki | https://wiki.redmodding.org/cyber-engine-tweaks |
| REDmod (official) | https://www.cyberpunk.net/en/modding-support |
| CP2077 Modding Wiki | https://wiki.redmodding.org/cyberpunk-2077-modding |
| NativeDB | https://nativedb.red4ext.com |
| Nexus Mods | https://www.nexusmods.com/cyberpunk2077 |
| Codeware (REDscript framework) | https://github.com/psiberx/cp2077-codeware |
| RED4ext | https://github.com/WopsS/RED4ext |

---

## Quick-Start Checklist

- [ ] Downloaded `CP2077-AI-Setup-v4.0.zip` and extracted it
- [ ] Double-clicked `INSTALL-EVERYTHING.bat` and clicked Yes on UAC
- [ ] Watched it install Ollama → VS Code → Cline → Qwen3-Coder 7B
- [ ] (Optional) Said Y to the bigger 30B-A3B model
- [ ] Saw the "AI Mod Helper" shortcut on the Desktop
- [ ] Double-clicked the shortcut and picked a mod folder
- [ ] Clicked the robot icon in VS Code's left sidebar
- [ ] Picked Ollama → qwen3-coder:7b → Let's go!
- [ ] Asked the AI "list all files in this folder and tell me what you see"

**You now have a private, local, fully visual AI assistant for Cyberpunk 2077 modding.**

---

*Last updated: 2026-04-16 · v4.0 · Easy Mode Edition*
