============================================================
  CP2077 Local AI Setup v4.1  --  EASY MODE EDITION
  (one-click install, friendly visual UI, no commands,
   pre-loaded with pose-modding knowledge)
============================================================

WHAT THIS IS
------------
A private, fully local AI assistant that runs on YOUR PC (no
cloud, no subscriptions) and helps you create / edit / fix
mods for Cyberpunk 2077 -- including pose packs, AMM Lua
collabs, REDscript hooks, CET overlays, and mesh scaling.

You chat with the AI in a panel inside VS Code. When the AI
wants to write a new file or change one, it shows you the
exact change and waits for you to click APPROVE. Nothing
happens behind your back.

NEW IN v4.1: when you launch "AI Mod Helper" and pick a
folder, the helper drops a "_AI-Knowledge" folder into it
with the full pose-modding bible (entity scopes, body rigs,
ArchiveXL/TweakXL/AMM patterns, common pitfalls) AND a recipe
file with copy-paste prompts for the most common modding
tasks. The AI reads these on every conversation -- no need
to teach it from scratch. Existing files are NEVER touched.


HOW TO INSTALL  (just two clicks!)
----------------------------------

  1. Double-click   INSTALL-EVERYTHING.bat

     Windows will pop a UAC prompt -- click YES (it needs
     admin rights to install Ollama and VS Code).

     The script then downloads + installs everything:
       - Ollama         (the AI engine)         ~500 MB
       - VS Code        (the friendly editor)   ~100 MB
       - Cline          (the chat panel)        ~50 MB
       - Qwen3-Coder 7B (the AI brain)          ~5 GB

     It tells you what it's doing the whole time. Total
     download is around 6 GB -- 10 to 30 min on a normal
     home connection. You can leave it running.

     When it finishes, it puts a "AI Mod Helper" icon on
     your Desktop.

  2. Double-click "AI Mod Helper" on your Desktop.

     It asks "what folder?" -- pick your CP2077 mod folder
     (or any empty folder). VS Code opens.

     A small popup window with a "first-time setup" guide
     also opens in Notepad. Follow it -- it's 3 clicks
     inside VS Code to wire Cline up to your local Ollama.

  That's it. You're chatting with your local AI.


WHAT'S IN THIS ZIP
------------------

  INSTALL-EVERYTHING.bat            <-- run this first
  AI-MOD-HELPER.bat                 <-- the launcher (auto-
                                       scaffolds AI knowledge
                                       into your mod folder)
  VERIFY-INSTALL.bat                <-- end-to-end smoke test
                                       (pings every layer)
  CLINE-FIRST-TIME-SETUP.txt        <-- the 3-click guide
  README.txt                        <-- you are here
  opencode.json                     <-- bonus: config for the
                                       advanced "OpenCode"
                                       terminal UI (optional)

  scripts\install-everything.ps1    <-- the installer brain
  scripts\ai-mod-helper.ps1         <-- the launcher brain
  scripts\verify-install.ps1        <-- the verifier brain
  scripts\check-local-ai-setup.ps1  <-- diagnostic tool

  mod-workspace-template\           <-- gets copied INTO your
                                       mod folder by the helper
    .clinerules                       (Cline auto-loads this)
    _AI-Knowledge\
      POSE.md                         (pose-modding bible)
      POSE-MODDING-RECIPES.md         (copy-paste prompts)
    _Examples\
      01_pose_pack_yaml\              (working .yaml example)
      02_amm_collab_lua\              (working AMM Lua example)
    .vscode\settings.json             (editor defaults for
                                       .reds, .xl, .workspot,
                                       .ent, .app, .mi)
    .vscode\extensions.json           (recommended extensions)
    README.md                         (workspace intro)


WHAT YOU GET TO DO IN THE CHAT
------------------------------

Type any of these into the Cline chat box at the bottom of
VS Code:

  > Make a new CET mod called HelloWorld that prints
    "hello from V" in the CET console when the game starts.

  > Read the .lua files in this folder and explain what
    this mod does in plain English.

  > Take this code: [paste]
    Convert it from Lua to REDscript.

  > Add a hotkey binding: pressing F7 should toggle the
    effect on and off.

  > I got this compile error: [paste]
    Look at my files and fix it.

The AI does the work, shows you a side-by-side diff of any
change, and waits for you to click APPROVE.


HARDWARE
--------
   GPU: NVIDIA card with 8+ GB VRAM (RTX 3060 12GB, RTX 4070,
        RTX 5080, etc.) -- 16 GB sweet spot.
  RAM: 16 GB minimum, 32 GB recommended.
  DISK: 30 GB free.
  WIN: Windows 10 or 11.


THE OPTIONAL BIGGER MODEL
-------------------------
The installer can also pull a much bigger / smarter model
(Qwen3-Coder 30B-A3B, 18 GB). It asks Y/N before downloading
since it's a large file. You can re-run the installer ANY TIME
to add it later -- already-installed pieces are skipped.


IS SOMETHING NOT WORKING?
-------------------------
Re-run INSTALL-EVERYTHING.bat (it's safe to run again).

To CHECK without changing anything, double-click:

   VERIFY-INSTALL.bat
     -- This is the end-to-end smoke test. It actually pings
        Ollama, generates a token from the model on your GPU,
        confirms VS Code is callable, and confirms the Cline
        extension is installed. Takes ~30 seconds.

For a static "is it installed?" check (no model load):

   scripts\check-local-ai-setup.ps1  (right-click -> Run with PowerShell)


I WANT TO USE THE TERMINAL INSTEAD (advanced)
---------------------------------------------
If you prefer a command-line experience, OpenCode (a TUI
agentic coder) also works with the same Ollama backend. The
opencode.json file in this zip is the matching config -- copy
it to %APPDATA%\opencode\opencode.json. See the full guide
(testtest.md) on the repo for details.


NEED HELP?
----------
Open an issue: https://github.com/AunEin/wkit/issues
Full guide:    https://github.com/AunEin/wkit/blob/axl-generator-add-toggles/testtest.md

============================================================
