# SETUP-GUIDE.md

This file is the same content as [`testtest.md`](https://github.com/AunEin/wkit/blob/axl-generator-add-toggles/testtest.md) at the root of the repository. It's bundled in the release zip so you have the full tutorial offline.

For the canonical, latest version, always check the repo:
**https://github.com/AunEin/wkit/blob/axl-generator-add-toggles/testtest.md**

---

The full tutorial covers:

1. **What You Need** — hardware (RTX 5080) and software (Ollama, OpenCode, WolvenKit, CET, REDmod)
2. **Install Ollama** — the local AI engine
3. **Download the Best Models** — Qwen3-Coder 30B-A3B (primary), Qwen3-Coder 7B (fast), DeepSeek R1 14B (reasoning)
4. **Install OpenCode** — the agentic terminal UI that actually edits/creates/moves your mod files (Scoop / npm / Chocolatey / manual)
5. **Configure OpenCode for Ollama** — `opencode.json` (a copy ships in this zip) goes to `%APPDATA%\opencode\`
6. **Use It on Your CP2077 Mod Project** — the read/write/edit/bash/grep/glob/apply_patch/webfetch tool loop
7. **Install CP2077 Modding Tools** — WolvenKit, CET, REDmod, .NET 8
8. **Optional: AnythingLLM** — keep the v2.0 chat-style RAG alongside OpenCode
9. **Workflow** — scaffold a mod, edit an existing mod, debug compile errors, refactor across files, transfer mod into the game folder
10. **Automation Script** — what `RUN-SETUP-CHECK.bat` and `RUN-SETUP-AND-DOWNLOAD.bat` actually do
11. **Troubleshooting** — common failures and one-line fixes
12. **Links & Resources** — every tool, model, and reference linked

---

> **TL;DR**: extract this zip, double-click `RUN-SETUP-CHECK.bat`, then double-click `RUN-SETUP-AND-DOWNLOAD.bat`, install OpenCode (`scoop install opencode`), then run `opencode` inside any mod folder.
