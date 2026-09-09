# Nhìn Ăn Chữa Lành — Flutter handoff pack

This folder is intended to be dropped directly into a Flutter repository or attached to a coding-agent workspace.

Files:

- `MASTER_PROMPT.md` — complete source-of-truth implementation brief
- `ui_reference.png` — visual UI reference
- `design_tokens.json` — palette, typography, spacing and radius tokens
- `ACCEPTANCE_CHECKLIST.md` — final QA checklist
- `ONE_PROMPT.txt` — the only prompt you need to paste after importing the pack

Recommended use:

1. Open/create the Flutter repository in Codex or Antigravity.
2. Copy this whole folder into the repository root, for example as `/product_handoff/`.
3. Attach/allow the agent to read the folder.
4. Paste the contents of `ONE_PROMPT.txt` once.
5. Let the agent implement and iterate until checks pass.

If the repository already has backend/API code, tell the coding agent to preserve it. `MASTER_PROMPT.md` already instructs the agent not to wipe a working codebase.
