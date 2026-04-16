# Cyberpunk 2077 Modding Workspace

This folder is set up for **AI-assisted CP2077 modding** with Cline + Ollama. Open it in VS Code, click the Cline robot in the left sidebar, and start chatting.

---

## Folder layout

```
.clinerules                 <- AI system rules (auto-loaded by Cline; don't delete)
.vscode/                    <- VS Code settings + recommended extensions
_AI-Knowledge/              <- Reference docs the AI reads on every conversation
  POSE.md                   <- Complete pose-modding bible (rigs, scopes, .xl, .yaml, AMM)
  POSE-MODDING-RECIPES.md   <- Copy-paste prompts for common modding tasks
_Examples/                  <- Real working files from shipped mods
  01_pose_pack_yaml/        <- Working TweakXL .yaml example
  02_amm_collab_lua/        <- Working AMM Lua example
README.md                   <- You are here
```

The `_AI-Knowledge/` folder is what makes this workspace different from a blank folder — Cline reads `POSE.md` and the recipes any time you ask a question, so you don't have to teach the AI from scratch every session.

---

## What to do first

1. Make sure Cline is wired up: API Provider = `Ollama`, Model = `qwen3-coder:7b`.
2. Try this prompt verbatim:

   > "Look at the files in this workspace and tell me what kind of CP2077 modding it's set up for, then list 3 things I can ask you to do."

3. If you have a mod folder somewhere else, **drag the whole folder onto the VS Code window** to add it to the workspace. The AI will see those files too.

---

## Common starting prompts

Pick one to copy into the Cline chat:

- *"I want to make a new pose pack from scratch. Walk me through what I need to prepare in WolvenKit and Blender first."*
- *"Patch this pose pack so Male V can use the male animations: [drag your mod folder]."*
- *"Read this .xl and .yaml: [drag files]. Diagnose why Male V doesn't see the poses."*
- *"Make a CET mod called HelloWorld that prints to the console when the game starts."*
- *"Make Male V appear 1.2x bigger in Photo Mode using Redscript. Reference the BigV approach in _AI-Knowledge/POSE.md."*

For more, see `_AI-Knowledge/POSE-MODDING-RECIPES.md`.

---

## Tips

- **Drag files into the chat** to give the AI context. It reads them and uses them in its answer.
- **Switch models** for hard tasks: gear icon → Model dropdown → `qwen3-coder:30b-a3b` (if installed) or `deepseek-r1:14b`.
- **Approve changes one at a time.** When the AI proposes a file change, it shows a diff. Click "Save" to apply, "Reject" to throw it out, or click in the diff to edit before saving.
- **You can ask the AI to run shell commands.** "Pack this folder into a zip" → it'll propose `Compress-Archive ...` and wait for your approval.
- **Don't edit binary files** (`.archive`, `.anims`, `.workspot`, `.ent`, `.mesh`) — open them in WolvenKit instead. The AI knows this and will refuse.
