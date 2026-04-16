============================================================
  CP2077 Local AI Setup v3.0 -- OpenCode Edition
  Quick-start instructions
============================================================

WHAT'S IN THIS ZIP
------------------
  RUN-SETUP-CHECK.bat          Double-click: checks your system
  RUN-SETUP-AND-DOWNLOAD.bat   Double-click: downloads what's missing
                               and installs the opencode.json config
  scripts\check-local-ai-setup.ps1   The PowerShell brain behind the .bats
  opencode.json                Drop this into %APPDATA%\opencode\
                               (the .bats can do this for you)
  SETUP-GUIDE.md               The full tutorial -- read this if anything
                               is unclear
  README.txt                   You are here

HOW TO USE (THE FAST WAY)
-------------------------
  1. Extract this zip ANYWHERE on your PC.
     (Don't put it inside the Cyberpunk 2077 game folder.)

  2. Double-click   RUN-SETUP-CHECK.bat
     -- It tells you what's already installed and what's missing.
     -- It does NOT install anything yet.

  3. Double-click   RUN-SETUP-AND-DOWNLOAD.bat
     -- It downloads any missing AI models and writes opencode.json
        to %APPDATA%\opencode\.
     -- It will ASK before each big download (Y/N).

  4. Open your mod folder in any terminal (PowerShell, Windows Terminal,
     or VS Code's built-in terminal) and type:
         opencode
     The agentic AI TUI opens. Try:
         "list every .reds file in this folder and explain what it does"

THE FIRST TIME YOU RUN A POWERSHELL SCRIPT
------------------------------------------
Windows blocks scripts by default. Open PowerShell ONCE and run:

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

Press Y to confirm. You only need to do this once, ever.

If you're on a corporate machine and that command is blocked, the .bat
files use   powershell -ExecutionPolicy Bypass   so they should work
without changing the policy.

WHAT YOU STILL NEED TO INSTALL MANUALLY
---------------------------------------
The .bat files take care of the AI side (Ollama models + opencode.json).
You install these yourself once:

  Ollama          https://ollama.com/download/windows
  OpenCode        scoop install opencode
                  -- OR --
                  npm install -g opencode-ai
                  -- OR --
                  download from https://github.com/sst/opencode/releases
  WolvenKit       https://github.com/WolvenKit/WolvenKit-nightly-releases/releases/latest
  CET             https://www.nexusmods.com/cyberpunk2077/mods/107
  REDmod          Free DLC on Steam/GOG/Epic
  .NET 8 Desktop  https://dotnet.microsoft.com/download/dotnet/8.0

The CHECK script tells you which of those are missing.

NEED HELP?
----------
  Read SETUP-GUIDE.md (the full tutorial)
  Or open an issue: https://github.com/AunEin/wkit/issues

============================================================
