# POSE-MODDING-RECIPES.md

Copy-paste these prompts into the Cline chat. The AI has POSE.md and working examples loaded — it will produce the actual files for you.

> **Tip:** drag a file from the VS Code file tree onto the Cline chat to give it context. For example, drag your existing `.xl` file before asking "patch this for Male V" — the AI will read the file and propose exact changes.

---

## Recipe 1 — Patch a male pose pack to also work for Male V

**When to use:** A pose mod's male animations only show up on `man_big` characters (Jackie, River) but not Male V.

**Prompt:**

```
I have a pose pack whose male animations only bind to man_big NPCs. Male V can't use them.

Here is the current .xl file: [drag your .xl file into the chat]
Here is the current .yaml file: [drag your .yaml file into the chat]
The male .anims file is: <name_of_male_anims_file>.anims

Patch both files so Male V (man_average) gets every pose. Don't touch the female bindings. Use !append-once. Show me a diff for each file and wait for my approval.
```

The AI will:
1. Read POSE.md §"Checklist for Male V Support"
2. Add the 5 entity scopes (`player_ma_photomode.ent`, `player_ma_photomode_ep1.ent`, `photomode_npc_man_average.ent`, `johnny_photomode.ent`, `photomode_ma.ent`) to the `.xl`
3. Add a `photo_mode.character.malePoses:` block + assignments for `johnnyNPCPoses`, `goroPoses`, `kerryPoses`, `viktorPoses` to the `.yaml` using a YAML anchor for reuse

---

## Recipe 2 — Strip ALL female entries from a male-only patch

**When to use:** You're shipping a patched MBF pack and don't want female poses appearing alongside the existing MF pack.

**Prompt:**

```
I want a male-only version of this pose pack. Strip every female entity binding, every female pose category, every female character assignment. Keep only the male content.

Here is the .xl: [drag .xl]
Here is the .yaml: [drag .yaml]
```

The AI will reference POSE.md §"Stripping Female Entries" and remove `player_wa_*`, `photomode_wa.ent`, `woman_average`, `npv_fem*`, `femalePoses`, `judyPoses`, `panamPoses`, `altPoses`, `evelynPoses`, `hanakoPoses`, `lizzyPoses`, `meredithPoses`, `myersPoses`, `rogueoldPoses`, `rogueyoungPoses`, `songbirdPoses`, `bluemoonPoses`, `purpleforcePoses`, `redmenacePoses`.

---

## Recipe 3 — Fix an AMM pose pack that's empty for Male V

**When to use:** You loaded the pose pack, opened AMM, picked Male V, and the category is empty even though `["Big"]` works.

**Prompt:**

```
This AMM Lua only populates ["Big"] but I want Male V (man_average) to use the same poses through engine retargeting.

Read the file: [drag .lua file]
Copy every animation name from ["Big"] into ["Man Average"]. Show me a diff.
```

---

## Recipe 4 — Build a brand-new pose pack from scratch (just the wrapper files)

**Note:** You still need someone (or you with Blender + WolvenKit) to actually export the `.anims`, `.workspot`, and `.archive`. The AI builds the `.xl`, `.yaml`, and AMM Lua wrappers around those.

**Prompt:**

```
I just exported a new pose pack. Files I have:
  - my_poses.archive  (from WolvenKit pack)
  - my_poses.anims    (inside the archive)
  - my_poses.workspot (inside the archive)
  - The poses are named pose_01 through pose_15
  - It's for Male V only (man_average rig)
  - Pose pack name: "Test Poses"
  - My author tag: "MyName"

Make me:
  1. The .xl file (all Male V entity bindings)
  2. The .yaml file (a new PhotoModePoseCategories.MyName_test category with all 15 poses, registered to malePoses + Johnny + Goro + Kerry + Viktor)
  3. The AMM Lua file
  4. A README.md with install instructions
  5. A folder structure mirror of where each file goes in Cyberpunk 2077/

Use the working example in _Examples/01_pose_pack_yaml/working_pose_pack.yaml as the template style.
```

---

## Recipe 5 — Diagnose "my pose mod doesn't show up"

**Prompt:**

```
I installed a pose pack but the poses don't show up for Male V in Photo Mode.

Read these files: [drag the .xl AND the .yaml AND any AMM lua]
Walk through the diagnostic checklist from _AI-Knowledge/POSE.md and tell me which step is failing.
```

The AI will check:
- Does the `.xl` bind to `player_ma_photomode.ent` and `photomode_ma.ent`? (most common miss)
- Does the `.yaml` have a `photo_mode.character.malePoses:` block?
- Do the `animationName:` values in the YAML match what's referenced in the `.workspot` (the AI can't read .workspot — will tell you to check in WolvenKit)
- Is the rig in the `.workspot` `finalAnimsets` correct? (AI will tell you to verify in WolvenKit)

---

## Recipe 6 — Add a hotkey-toggleable CET mod (e.g. "press F7 to do X")

**Prompt:**

```
Make a CET mod called "<MyMod>" that does <X> when I press F7. Toggle on/off.

Folder structure:
  bin/x64/plugins/cyber_engine_tweaks/mods/<MyMod>/
    init.lua
    README.md

Wire the F7 binding through CET's HotkeyManager (modules.NativeSettingsUI hotkey API).
```

The AI will produce a complete `init.lua` with:
- `registerForEvent('onInit', ...)` to register the hotkey
- `registerHotkey('toggle_x', 'Toggle X', function() ... end)` for binding through CET's settings UI
- A persistent toggle state stored via `GetMod()`'s shared object

---

## Recipe 7 — Make Male V bigger (mesh scaling)

**When to use:** You want a thicker / taller Male V like the existing **BigV** mod but with your own scale.

**Prompt:**

```
I want a Redscript mod that makes Male V appear 1.2x bigger (mesh scale) and 0.15m taller in Photo Mode only.

Reference the BigV approach documented in _AI-Knowledge/POSE.md §"Mesh Scaling" — use the field-by-field Vector3, cast to entSkinnedMeshComponent, hook PhotoModePlayerEntityComponent.SetupInventory and gameuiPhotoModeMenuController.OnHide.

Build a complete ScriptableSystem in r6/scripts/<modname>/<modname>.reds. Include a CET overlay if quick.
```

---

## Recipe 8 — Bug-hunt a REDscript compile error

**Prompt:**

```
I'm getting this REDscript compile error:

[paste error here]

My code is: [drag .reds file or paste]

Look at the error and the code. If you need to know what a class or method does, tell me to look it up on https://nativedb.red4ext.com — don't make up signatures.
```

For tougher errors, switch to a stronger model first: in the Cline chat panel, click the gear → Model dropdown → pick `qwen3-coder:30b-a3b` (if you downloaded it) or `deepseek-r1:14b` (better at chain-of-thought reasoning).

---

## Recipe 9 — Pack a finished mod into a release zip

**Prompt:**

```
This folder is ready to release. Look at every file under here, then:
  1. Build a clean folder mirror that matches the game's install layout (archive/pc/mod/, r6/tweaks/, etc.) using only the files that should go to the user
  2. Zip that mirror into <ModName>-v1.0.0.zip in the workspace root
  3. Write a RELEASE.md with install steps, requirements (ArchiveXL/TweakXL/AMM/Codeware), and a credits section.
```

The AI will use the `bash` tool to build the zip. It will show you the file list and ask for approval before running PowerShell's `Compress-Archive`.

---

## Recipe 10 — Investigate an unfamiliar mod before patching it

**Prompt:**

```
I downloaded this mod and want to understand it before changing anything. Read every text file in the folder (.xl, .yaml, .lua, .reds, .json, .md), then tell me:

  1. What does the mod do, in one paragraph?
  2. Which game systems does it touch?
  3. Which body rigs does it support?
  4. What are the entry points (where does code execution start)?
  5. Are there any obvious bugs or missing pieces?

Then list 3 small improvements I could make.
```

This is the best first prompt for any unfamiliar mod folder.

---

## Switching models inside Cline

In the chat panel, click the gear icon at the top → API Provider section → change the **Model** dropdown:

| Model | When to use |
|---|---|
| `qwen3-coder:7b` | Default — fast, fine for 90% of pose-pack work |
| `qwen3-coder:30b-a3b` | Big refactors across 5+ files; new mod scaffolding |
| `deepseek-r1:14b` | "I have no idea why this isn't working" — chain-of-thought debugging |

You don't have to restart Cline. The next message uses the new model.
