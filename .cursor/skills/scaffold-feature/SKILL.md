---
name: scaffold-feature
description: "Scaffold only the MVVM-C folder structure and boilerplate files for a new ZanzarProject feature — no implementation, localization, navigation wiring, or tests. Use when the user asks to scaffold, prepare, set up folders, or create the directory structure for a new feature/screen/module in ZanzarProject — e.g. 'scaffold the X feature', 'create folders for X', 'prepare the structure for a new feature', 'só a estrutura da feature X', 'criar as pastas da feature X'. Do NOT use when the user wants a fully implemented feature — use create-feature instead."
---

# Scaffold Feature

Scaffold the folder structure and placeholder files for a new feature. **Stop after scaffolding** — do not implement API, ViewModel, View, localization, navigation, or tests.

IRON LAW: Every feature folder is produced by `scripts/scaffold_feature.py` — never hand-created file by file.

## Workflow

Copy this checklist and check off items as you complete them:

```
Scaffold Feature Progress:

- [ ] Step 1: Confirm feature name ⚠️ REQUIRED
  - [ ] 1.1 PascalCase name agreed (e.g. IssueReport)
  - [ ] 1.2 Tell the user which feature will be scaffolded
- [ ] Step 2: Run scaffold script ⛔ BLOCKING
  - [ ] Run scripts/scaffold_feature.py <FeatureName>
  - [ ] Review and report created vs. skipped files
- [ ] Step 3: Summarize structure ⚠️ REQUIRED
  - [ ] Show the folder tree that was created
  - [ ] Remind user to use create-feature for full implementation
```

## Step 1: Confirm feature name

You only need the **PascalCase feature name** — not endpoints, fields, or navigation details.

If the user gave a vague name ("report screen", "user profile"), propose a PascalCase name and confirm before scaffolding:

> "Vou criar a estrutura de pastas para a feature **IssueReport**."

Do not ask about API contracts, navigation style, or UI behavior — that belongs to **create-feature**.

## Step 2: Run scaffold script ⛔ BLOCKING

From the repo root (or pass `--repo-root`):

```bash
python3 .agents/skills/create-feature/scripts/scaffold_feature.py <FeatureName>
```

`<FeatureName>` must be PascalCase. The script:

- Auto-detects the repo root via `ZanzarProject/ZanzarProject.xcodeproj`
- On first run, bootstraps shared infrastructure (`App/`, `Coordinator/`, `Utils/`, `Features/Shared/`, `Resources/`)
- Creates the feature folders and boilerplate files (see Step 3)
- Creates the test stub at `ZanzarProjectTests/<FeatureName>/`
- Never overwrites existing files — reruns are safe

If bootstrap will run (no `Coordinator/AppCoordinator.swift` yet), tell the user before running — it moves entry files and creates shared infrastructure.

The Xcode project uses file-system-synchronized groups — no `.xcodeproj` editing.

## Step 3: Summarize structure

After the script runs, report what was **created** vs **skipped (exists)**.

Show this expected tree (adjust `<FeatureName>`):

```
ZanzarProject/ZanzarProject/Features/Shared/   ← created on bootstrap (cross-feature UI/helpers)
  Views/Components/                            ← e.g. Auth/
  Utils/
ZanzarProject/ZanzarProject/Features/<FeatureName>/
  API/
    <FeatureName>Service.swift       ← protocol + impl stub
  Models/
    <FeatureName>.swift                ← domain model stub
  ViewModels/
    <FeatureName>ViewModel.swift
  Views/
    <FeatureName>View.swift
    Components/                        ← empty, for extracted subviews
ZanzarProject/ZanzarProjectTests/<FeatureName>/
  <FeatureName>ViewModelTests.swift    ← test stub only
```

End with a short note:

> Estrutura pronta. Para implementar API, ViewModel, View, localização, navegação e testes, use a skill **create-feature**.

For the full layer contract, see [.agents/skills/create-feature/references/architecture.md](../../.agents/skills/create-feature/references/architecture.md).

## What this skill does NOT do

- Do NOT implement Request/Response, domain models, ViewModel logic, or Views
- Do NOT add strings to `Localizable.xcstrings`
- Do NOT wire `Routes.swift` or `AppCoordinator.swift`
- Do NOT fill in test assertions
- Do NOT hand-create folders or files — always use the script

## Anti-Patterns

- Do NOT use **create-feature** when the user only asked for folder structure
- Do NOT continue into implementation after scaffolding unless the user explicitly asks
- Do NOT invent a feature name without confirming with the user
