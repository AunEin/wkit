# POSE.md -- Cyberpunk 2077 Pose Modding Knowledge Base

**Author:** AunEin  
**Last updated:** 2026-04-13  
**Purpose:** Reference for future sessions when working with CP2077 pose packs, body scaling, Photo Mode, and AMM integration.

---

## Table of Contents

1. [Patches Created](#patches-created)
2. [CP2077 Body Rigs](#cp2077-body-rigs)
3. [Photo Mode Entity Scopes](#photo-mode-entity-scopes)
4. [ArchiveXL (.xl files)](#archivexl-xl-files)
5. [TweakXL (.yaml files)](#tweakxl-yaml-files)
6. [AMM Collab Poses (.lua files)](#amm-collab-poses-lua-files)
7. [Mesh Scaling (Making V Bigger)](#mesh-scaling-making-v-bigger)
8. [Tools Used](#tools-used)
9. [File Locations & Install Paths](#file-locations--install-paths)
10. [GitHub Repos Created](#github-repos-created)
11. [Common Pitfalls](#common-pitfalls)
12. [Step-by-Step: Patching a Pose Pack for Male V](#step-by-step-patching-a-pose-pack-for-male-v)

---

## Patches Created

### 1. Money Power Glory -- Male V Patch

**Original mod:** "Posepack Money Power Glory - Fem x Man Big" by Vesna  
**Problem:** Male animations (`ves_mpg_male_pm.anims`) only bound to Man Big entities. Male V (`man_average`) completely missing from `.xl` and `.yaml`.  
**What we did:**
- Patched `.xl` -- added 5 male average entity bindings for `ves_mpg_male_pm.anims`
- New `.yaml` -- added `malePoses`, `johnnyNPCPoses`, `goroPoses`, `kerryPoses`, `viktorPoses` with all 25 poses
- Patched AMM Lua -- populated `["Man Average"]` table with all 25 animation names
- 25 poses total, all available for Male V

**Release:** https://github.com/AunEin/CP2077-MPG-MaleV-Patch/releases/tag/v1.0.0  
**Install:** `.xl` replaces original, `.yaml` goes alongside original, AMM Lua replaces original

### 2. In The Mood For Love MBF -- Male V Only Patch

**Original mod:** "Ellie x BV - In The Mood For Love MBF PM"  
**Problem:** Same bug -- male animations (`big_mbf.anims`) only bound to Man Big entities. Male V missing from `.xl`, no `malePoses` in `.yaml`.  
**Additional requirement:** Strip ALL female entries because user already has the MF (Male-Female) version installed which handles Female V.

**What we did:**
- Patched `.xl` -- removed all 7 female entity bindings (`player_wa_*`, `photomode_wa.ent`, `woman_average`, `npv_fem*`), added 5 male average entity bindings for `big_mbf.anims`
- Replacement `.yaml` -- completely replaces original. Removed entire `InTheMoodForLoveMBF_F` category, all 11 female pose definitions, and all female character assignments (`femalePoses`, `judyPoses`, `panamPoses`, `altPoses`, `evelynPoses`, `hanakoPoses`, `lizzyPoses`, `meredithPoses`, `myersPoses`, `rogueoldPoses`, `rogueyoungPoses`, `songbirdPoses`, `bluemoonPoses`, `purpleforcePoses`, `redmenacePoses`). Only 11 MB poses remain, assigned to male characters only.
- 11 poses total (the `_mb` variants), male-only

**Why male-only:** The MF version ("In The Mood For Love MF PM") already provides Female V poses with different animation files, different TweakDB names (`_f`/`_m` suffixes vs `_mb`), and different file paths (`in_the_mood_for_love_fm_pm/` vs `in_the_mood_for_love_mbf_pm/`). No conflicts when both installed side-by-side.

**Compatibility analysis (MF vs MBF):**
| Aspect | MF Version | MBF Version (patched) |
|--------|-----------|----------------------|
| .xl filename | `In_The_Mood_For_Love_FM.xl` | `In_The_Mood_For_Love_MBF.xl` |
| .yaml path | `in_the_mood_for_love_fm_pm/` | `in_the_mood_for_love_mbf_pm/` |
| Male anims | `ellie_bv_poses_masc.anims` | `big_mbf.anims` |
| Pose suffixes | `_m` / `_f` | `_mb` (no suffix for F, removed) |
| Category names | `InTheMoodForLoveM` / `InTheMoodForLoveF` | `InTheMoodForLoveMBF_MB` |
| Conflicts? | **None** | **None** |

**MF version already works for Male V out of the box** -- it has `player_ma_photomode.ent`, `photomode_ma.ent`, and `malePoses` already. No patching needed.

**Release:** https://github.com/AunEin/CP2077-ITMFL-MaleV-Patch/releases/tag/v1.1.0  
**Install:** Both `.xl` and `.yaml` REPLACE the originals (not alongside)

### 3. BigV Mod

**Purpose:** Make Male V appear physically larger (1.1x scale + height boost) in Photo Mode  
**Approach:** Redscript ScriptableSystem + CET Lua overlay  
**Release:** https://github.com/AunEin/CP2077-BigV

---

## CP2077 Body Rigs

| Rig Name | Skeleton | Used By |
|----------|----------|---------|
| `man_base` / `man_average` | `player_man_skeleton` | **Male V**, Johnny, Goro, Kerry, Viktor |
| `man_big` | `man_big_skeleton` | Jackie, River, Reed, Kurt |
| `woman_base` / `woman_average` | `player_woman_skeleton` | **Female V**, Judy, Panam, etc. |

**Critical insight:** Male V is `man_average`, NOT `man_big`. Most "male" pose packs target `man_big` NPCs and forget about Male V entirely. This is the root cause of every patch we've made.

---

## Photo Mode Entity Scopes

### Pre-2.2 (explicit paths)
```
base\characters\entities\player\photo_mode\player_ma_photomode.ent       # Male V (base game)
ep1\characters\entities\player\photo_mode\player_ma_photomode_ep1.ent    # Male V (Phantom Liberty)
base\characters\entities\player\photo_mode\player_wa_photomode.ent       # Female V (base game)
ep1\characters\entities\player\photo_mode\player_wa_photomode_ep1.ent    # Female V (PL)
base\characters\entities\photomode_replacer\photomode_npc_man_average.ent # Male average NPCs
base\characters\entities\photomode_replacer\photomode_npc_man_big.ent    # Man big NPCs
base\characters\entities\photomode_replacer\photomode_npc_woman_average.ent # Female NPCs
base\characters\entities\player\photo_mode\johnny_photomode.ent          # Johnny Silverhand
```

### 2.2+ Shorthand Scopes
```
photomode_ma.ent   # All male average (catches Male V + man_average NPCs)
photomode_mb.ent   # All man big
photomode_wa.ent   # All woman average
```

### Body Mod Variants (VTK/Gymfiend)
Female V gets numbered variants like `player_wa_photomode11.ent`, `player_wa_photomode12m.ent`, etc.  
Male V with body mods typically still uses the base `player_ma_photomode.ent` scope + the 2.2 shorthand.

---

## ArchiveXL (.xl files)

These bind `.anims` animation sets to entity scopes. The game loads animations for an entity based on these bindings.

### Structure
```yaml
animations:
  - entity: base\characters\entities\player\photo_mode\player_ma_photomode.ent
    set: my_mod\my_anims.anims
  - entity: photomode_ma.ent          # 2.2+ shorthand
    set: my_mod\my_anims.anims

localization:
  onscreens:
    en-us: my_mod\my_local.json
```

### Key Rules
- One `.xl` file per mod, goes in `archive/pc/mod/`
- Entity paths use backslashes `\` (Windows-style)
- The `set:` path is relative to the archive root
- You must bind to EVERY entity scope variant you want to support
- **If you miss an entity scope, those poses simply won't appear** -- no error, just silent failure

### Checklist for Male V Support
```yaml
# Must have ALL of these for Male V:
- entity: base\characters\entities\player\photo_mode\player_ma_photomode.ent
  set: your_mod\your_male_anims.anims
- entity: ep1\characters\entities\player\photo_mode\player_ma_photomode_ep1.ent
  set: your_mod\your_male_anims.anims
- entity: base\characters\entities\photomode_replacer\photomode_npc_man_average.ent
  set: your_mod\your_male_anims.anims
- entity: base\characters\entities\player\photo_mode\johnny_photomode.ent
  set: your_mod\your_male_anims.anims
- entity: photomode_ma.ent
  set: your_mod\your_male_anims.anims
```

### Stripping Female Entries
When making a male-only patch, remove these entity scopes from the `.xl`:
```
player_wa_photomode.ent          # Female V base
player_wa_photomode_ep1.ent      # Female V PL
player_wa_photomode*.ent         # All numbered body mod variants
photomode_npc_woman_average.ent  # Female NPCs
photomode_npc_npv_fem*.ent       # Female NPV variants
photomode_wa.ent                 # 2.2+ shorthand for all female
```
Also remove any `female_*.anims` references from the `set:` entries.

---

## TweakXL (.yaml files)

These register poses with Photo Mode character categories. Without these, even if animations are loaded, Photo Mode won't list them.

### Structure
```yaml
photo_mode.character.malePoses:           # Male V
    - !append-once PhotoModePoses.my_pose_1
    - !append-once PhotoModePoses.my_pose_2

photo_mode.character.femalePoses:         # Female V
    - !append-once PhotoModePoses.my_pose_1

photo_mode.character.johnnyNPCPoses:      # Johnny
    - !append-once PhotoModePoses.my_pose_1

photo_mode.character.jackiePoses:         # Jackie (man_big)
    - !append-once PhotoModePoses.my_pose_1
```

### Key Rules
- Goes in `r6/tweaks/your_mod_folder/`
- TweakXL merges all `.yaml` files, so patches can live alongside originals
- `!append-once` prevents duplicates if multiple files add the same pose
- Pose names reference TweakDB records defined in the mod's localization JSON
- YAML anchors (`&name` / `*name`) can reuse pose lists across multiple characters

### Patch vs Replace Strategy
- **Patch (new file alongside):** Use when you only NEED TO ADD entries (e.g., adding `malePoses`). The original `.yaml` stays untouched.
- **Replace (overwrite original):** Use when you need to REMOVE entries (e.g., stripping female poses). If you just add a patch file, the original's female entries would still be active and show broken poses in the list.

### All Character Categories
```
malePoses, femalePoses, johnnyNPCPoses, jackiePoses, riverPoses,
reedPoses, kurtPoses, judyPoses, panamPoses, goroPoses, kerryPoses,
viktorPoses, rogueOldPoses, rogueYoungPoses, altPoses, evelynPoses,
hanakoPoses, lizzyPoses, meredithPoses, blueMoonPoses, songbirdPoses,
myersPoses
```

### Male-Only Character Assignments
```yaml
photo_mode.character.malePoses: &MyMalePoses        # Male V
    - !append-once PhotoModePoses.my_pose_1

# man_average NPCs
photo_mode.character.johnnyNPCPoses: *MyMalePoses
photo_mode.character.goroPoses: *MyMalePoses
photo_mode.character.kerryPoses: *MyMalePoses
photo_mode.character.viktorPoses: *MyMalePoses

# man_big NPCs
photo_mode.character.jackiePoses: *MyMalePoses
photo_mode.character.kurtPoses: *MyMalePoses
photo_mode.character.riverPoses: *MyMalePoses
photo_mode.character.reedPoses: *MyMalePoses
```

---

## AMM Collab Poses (.lua files)

AMM (Appearance Menu Mod) uses Lua files for custom poses, separate from Photo Mode.

### File Location
```
bin/x64/plugins/cyber_engine_tweaks/mods/AppearanceMenuMod/Collabs/Custom Poses/<folder>/<file>.lua
```

### Structure
```lua
return {
  modder = "AuthorName",
  category = "My Pose Category [MAN BIG]",
  entity_path = "my_mod\\controller\\my_entity.ent",

  anims = {
      ["Man Average"] = {
        "my_anim_1",
        "my_anim_2",
      },
      ["Woman Average"] = {},
      ["Big"] = {
        "my_anim_1",
        "my_anim_2",
      },
      ["Child"] = {},
      ["Fat"] = {},
      ["Man Massive"] = {},
      ["Player Man"] = {},
      ["Player Woman"] = {},
  }
}
```

### AMM Rig Keys
| Key | Maps To |
|-----|---------|
| `"Man Average"` | Male V, Johnny, Goro, Kerry, Viktor |
| `"Big"` | Jackie, River, Reed, Kurt |
| `"Woman Average"` | Female V, Judy, Panam, etc. |
| `"Player Man"` | Male V specifically (rarely used) |
| `"Player Woman"` | Female V specifically (rarely used) |
| `"Man Massive"` | Adam Smasher, Sasquatch |
| `"Fat"` | Dex, Brendan, etc. |
| `"Child"` | Child-rig NPCs |

### Caveat: Cross-Rig Animation
If a pose pack only ships a `man_big` workspot/entity, adding anims to `["Man Average"]` relies on engine retargeting from `man_big` to `man_base`. This usually works but may fail if the `.workspot` file's `finalAnimsets` only has `man_big` rig entries. Fixing that requires WolvenKit to add a `man_base` finalAnimset entry.

---

## Mesh Scaling (Making V Bigger)

### The BigV Approach (Redscript)
Uses `SetVisualScale()` on mesh components + `TeleportationFacility.Teleport()` for height offset.

#### Key APIs
```swift
// Get/set visual scale on mesh components (requires Codeware RTTI expansion)
component.SetVisualScale(scaleVector);
component.GetVisualScale() -> Vector3;

// Force mesh refresh after scale change
entSkinnedMeshComponent.LoadAppearance();  // or RefreshAppearance via RTTI

// Height repositioning
let tf = GameInstance.GetTeleportationFacility(GetGameInstance());
let pos = entity.GetWorldPosition();
let newPos = new Vector4(pos.X, pos.Y, pos.Z + heightBoost, pos.W);
tf.Teleport(entity, newPos, entity.GetWorldOrientation().IsZero() ? EulerAngles(0,0,0) : entity.GetWorldOrientation());
```

#### Correct Vector3 Construction in Redscript
```swift
// DO THIS (field-by-field):
let v: Vector3;
v.X = factor;
v.Y = factor;
v.Z = factor;

// NOT THIS (constructor may silently fail):
// let v = new Vector3(factor, factor, factor);
```

#### Component Type Casting
```swift
// CORRECT -- cast to exact type:
let skinned = comp as entSkinnedMeshComponent;
let morph = comp as entMorphTargetSkinnedMeshComponent;

// WRONG -- these are sibling classes, not parent-child:
// let mesh = skinnedComp as MeshComponent;  // ALWAYS NULL
```

### BigV Mod Architecture
- **ScriptableSystem** pattern with `OnAttach` / `OnPlayerAttach` lifecycle
- Hooks `PhotoModePlayerEntityComponent.SetupInventory` (entering photo mode)
- Hooks `gameuiPhotoModeMenuController.OnHide` (leaving photo mode)
- Tick loop (0.35s) reapplies scale through pose changes
- CET Lua overlay for real-time slider adjustment

---

## Tools Used

| Tool | Purpose |
|------|---------|
| **WolvenKit** | Unpacking `.archive` files, inspecting `.ent`, `.anims`, `.workspot` files |
| **ArchiveXL** | Loading custom animations via `.xl` entity bindings |
| **TweakXL** | Registering poses with Photo Mode via `.yaml` tweaks |
| **Codeware** | Redscript runtime extensions (CallbackSystem, RTTI expansion) |
| **RED4ext** | Native plugin loading framework |
| **CET (Cyber Engine Tweaks)** | Lua scripting, console, mod overlays |
| **AMM (Appearance Menu Mod)** | Custom poses via Lua collab files |
| **Redscript** | Swift-like scripting for game logic hooks |
| **GitHub CLI (`gh`)** | Creating repos, releases, uploading assets |

---

## File Locations & Install Paths

### Cyberpunk 2077 Mod Directories
```
Cyberpunk 2077/
  archive/pc/mod/              # .archive and .xl files
  r6/tweaks/                   # .yaml TweakXL files
  r6/scripts/                  # .reds Redscript files
  bin/x64/plugins/
    cyber_engine_tweaks/mods/  # CET Lua mods
      AppearanceMenuMod/
        Collabs/Custom Poses/  # AMM pose Lua files
```

### Money Power Glory Patch Files
```
archive/pc/mod/
  _0_Vesna_HoV_Xbae_WA_MB_MoneyPowerGlory_Posepack.archive  # Animations (DO NOT REPLACE)
  _0_Vesna_HoV_Xbae_WA_MB_MoneyPowerGlory_Posepack.xl       # Entity bindings (REPLACE with patch)
r6/tweaks/vesna_xbaebsae/
  Vesna_FA_MB_MoneyPowerGlory.yaml                            # Original tweak (KEEP)
  Vesna_FA_MB_MoneyPowerGlory_MaleV_Patch.yaml                # Patch tweak (ADD)
bin/x64/plugins/cyber_engine_tweaks/mods/AppearanceMenuMod/
  Collabs/Custom Poses/house_of_vesna/
    vesna_mpg_man_big.lua                                     # AMM poses (REPLACE with patch)
```

### In The Mood For Love MBF Patch Files
```
archive/pc/mod/
  Ellie_X_BV_In_The_Mood_For_Love_MBF_PM.archive             # Animations (DO NOT REPLACE)
  In_The_Mood_For_Love_MBF.xl                                 # Entity bindings (REPLACE with patch)
r6/tweaks/in_the_mood_for_love_mbf_pm/
  In_The_Mood_For_Love_MBF.yaml                               # REPLACE with patch (male-only)
```

### In The Mood For Love MF Files (no patch needed)
```
archive/pc/mod/
  Ellie_X_BV_In_The_Mood_For_Love_FM_PM.archive              # Already has Male V support
  In_The_Mood_For_Love_FM.xl                                  # Already has man_average bindings
r6/tweaks/in_the_mood_for_love_fm_pm/
  In_The_Mood_For_Love_FM.yaml                                # Already has malePoses
```

---

## GitHub Repos Created

| Repo | Description | URL |
|------|-------------|-----|
| `AunEin/CP2077-MPG-MaleV-Patch` | Photo Mode + AMM fix for Money Power Glory poses on Male V | https://github.com/AunEin/CP2077-MPG-MaleV-Patch |
| `AunEin/CP2077-ITMFL-MaleV-Patch` | Male-only Photo Mode fix for In The Mood For Love MBF poses | https://github.com/AunEin/CP2077-ITMFL-MaleV-Patch |
| `AunEin/CP2077-BigV` | Mesh scaling mod (1.1x) for Photo Mode | https://github.com/AunEin/CP2077-BigV |

### Release Assets
- **CP2077-MPG-MaleV-Patch v1.0.0:**
  - `MPG-MaleV-Patch-v1.0.0.zip` -- Photo Mode fix (.xl + .yaml)
  - `CP2077-MPG-MaleV-AMM-Patch.zip` -- AMM fix (patched .lua)
- **CP2077-ITMFL-MaleV-Patch v1.1.0:**
  - `ITMFL-MaleV-Patch-v1.1.0.zip` -- Male-only Photo Mode fix (.xl + .yaml replace originals)

---

## Common Pitfalls

1. **"Poses don't show for Male V"** -- Check both the `.xl` file (entity bindings) AND the `.yaml` file (malePoses entry). Both must be present.

2. **"Poses show in list but T-pose when selected"** -- Animation rig mismatch. The `.anims` file was built for a different skeleton. May need WolvenKit to add the correct rig to the `.workspot` finalAnimsets.

3. **"SetVisualScale does nothing"** -- Make sure you're casting to the correct component type (`entSkinnedMeshComponent`, not `MeshComponent`). Call `LoadAppearance()` after setting scale.

4. **"Vector3 constructor returns zero"** -- Use field-by-field assignment in Redscript, not the constructor.

5. **"AMM poses work for Big but not Man Average"** -- The `["Man Average"]` table in the Lua file is probably empty. Populate it with the animation names. If using a man_big entity_path, engine retargeting must work (check workspot finalAnimsets).

6. **"Token expired" on GitHub release** -- GitHub PATs expire. Generate a new one at https://github.com/settings/tokens with `repo` scope.

7. **"Duplicate female poses showing when MF and MBF installed together"** -- If patching MBF for male-only, you must REPLACE the original `.yaml` (not add alongside) to remove the female pose registrations. Otherwise both MF and MBF will register female poses, causing duplicates.

8. **"GitHub repo disabled after push"** -- GitHub sometimes auto-flags new repos with rapid binary uploads. The release/download still works. Re-enable the repo in GitHub settings or contact support.

---

## Step-by-Step: Patching a Pose Pack for Male V

### Photo Mode Fix
1. Find the mod's `.xl` file in `archive/pc/mod/`
2. Look for the male `.anims` file bindings (e.g., `big_mbf.anims`, `ves_mpg_male_pm.anims`)
3. Check if `player_ma_photomode.ent` and `photomode_ma.ent` are present
4. If missing, add these entity bindings pointing to the male `.anims` file:
   ```yaml
   - entity: base\characters\entities\player\photo_mode\player_ma_photomode.ent
     set: <path_to_male_anims>
   - entity: ep1\characters\entities\player\photo_mode\player_ma_photomode_ep1.ent
     set: <path_to_male_anims>
   - entity: base\characters\entities\photomode_replacer\photomode_npc_man_average.ent
     set: <path_to_male_anims>
   - entity: base\characters\entities\player\photo_mode\johnny_photomode.ent
     set: <path_to_male_anims>
   - entity: photomode_ma.ent
     set: <path_to_male_anims>
   ```
5. If making male-only, also REMOVE all female entity bindings from the `.xl`
6. Find the mod's `.yaml` file in `r6/tweaks/`
7. If adding only: create a new `.yaml` alongside with `malePoses` entries
8. If stripping female: REPLACE the original `.yaml` with male-only version
9. Use `!append-once` with the same pose TweakDB names from the original yaml

### AMM Fix
1. Find the mod's AMM Lua in `Collabs/Custom Poses/`
2. Open it and check if `["Man Average"]` table has animations
3. If empty, copy the animation names from `["Big"]` or `["Woman Average"]` into it
4. Replace the file

### Verification
- **Photo Mode**: Load Male V save > Enter Photo Mode > Check pose category
- **AMM**: Open AMM > Poses tab > Select your V > Check category appears

### Checking for Conflicts Between Pack Variants
Before patching, compare variant packs (e.g., MF vs MBF) to ensure:
- Different `.xl` filenames
- Different `.yaml` directory paths
- Different TweakDB pose names (check suffixes like `_m`, `_f`, `_mb`)
- Different pose category names
- Different `.anims` file paths
If all are different, they can coexist. If any overlap, one must replace the other.
