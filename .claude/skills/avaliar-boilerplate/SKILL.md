---
name: avaliar-boilerplate
description: "Avaliação read-only do boilerplate iOS SwiftUI do ZanzarProject. Mapeia estrutura, detecta código genérico vs específico do Zanzar, identifica gaps e sugere melhorias priorizadas sem alterar arquivos. Use quando o usuário pedir para avaliar boilerplate, auditar scaffold, revisar estrutura do projeto Xcode, verificar se o starter está alinhado, checar antes de implementar feature, ou analisar testes/config/assets do app. Actions: avaliar, auditar, revisar, analisar, checar, inspecionar. Objects: boilerplate, scaffold, starter, template, estrutura, ZanzarProject, Xcode. Triggers: 'avaliar boilerplate', 'boilerplate alinhado', 'estrutura do projeto', 'starter pronto', 'scaffold do app', 'o boilerplate suporta', '/avaliar-boilerplate'. Escopo: ZanzarProject/ apenas."
argument-hint: [--area structure|tests|config|ui|assets|all] [--quick] [pergunta ou feature planejada]
---

# Avaliar Boilerplate

IRON LAW: NEVER create, edit, or delete files. Read-only audit — recommendations only. If the user wants changes, stop after the report and wait for a separate explicit request.

Red Flags (stop and reset if any appear):
- Opening Write/StrReplace/Delete on project files during this skill
- "I'll fix this while reviewing..."
- Recommendations without citing a specific file or setting
- Judging alignment without product context (vision, domain, planned features)

## Options

Parse `$ARGUMENTS`:

| Option | Description | Default |
|--------|-------------|---------|
| `--area <name>` | Focus: `structure`, `tests`, `config`, `ui`, `assets`, `all` | `all` |
| `--quick` | Skip vision questions; infer from repo with explicit caveats | false |
| trailing text | Planned feature or specific question (e.g. "navegação com @Observable") | none |

## Workflow

Copy this checklist and check off items as you complete them:

```
Avaliar Boilerplate Progress:

- [ ] Step 1: Scope & Context ⚠️ REQUIRED
  - [ ] 1.1 Confirm scope is ZanzarProject/ only
  - [ ] 1.2 Gather product vision (ask if missing)
  - [ ] 1.3 Parse --area and trailing question
- [ ] Step 2: Inventory ⛔ BLOCKING
  - [ ] 2.1 Run scripts/inventario.py
  - [ ] 2.2 Read flagged files and project.pbxproj
- [ ] Step 3: Evaluate ⚠️ REQUIRED
  - [ ] 3.1 Apply criteria for selected --area
  - [ ] 3.2 Cross-check against product vision
- [ ] Step 4: Report ⚠️ REQUIRED
  - [ ] 4.1 Write report using references/formato-relatorio.md
  - [ ] 4.2 Offer improvement options (no implementation)
- [ ] Step 5: Close
  - [ ] 5.1 Run pre-delivery checklist
  - [ ] 5.2 Ask if user wants to implement any option (separate task)
```

## Step 1: Scope & Context ⚠️ REQUIRED

Ask: Is the audit limited to `ZanzarProject/`? Default yes — ignore `.claude/`, repo-level skills, and root README unless the user explicitly expands scope.

Ask: What is Zanzar? What domain, core features, and architecture choices are planned?

Gather vision from (in order):
1. Current conversation
2. Docs inside `ZanzarProject/` (README, ADRs, comments)
3. User input

Unless `--quick` was passed, stop and ask the user when vision is missing or ambiguous. Minimum questions:
- What does Zanzar do for the user?
- What are the first 2–3 features to build?
- Any fixed choices? (SwiftData vs Core Data, CloudKit, offline-first, etc.)

If `--quick`: proceed with repo inference only. Mark every alignment judgment that depends on vision as **Assumption** in the report.

## Step 2: Inventory ⛔ BLOCKING

Run from repo root:

```bash
python3 .claude/skills/avaliar-boilerplate/scripts/inventario.py ZanzarProject
```

Use the JSON output as ground truth for file tree, generic signals, and config mismatches.

Then read source files the script flags and `ZanzarProject.xcodeproj/project.pbxproj` for:
- Deployment targets (app vs tests)
- Bundle identifiers and placeholders
- Swift concurrency settings
- Supported platforms and device families

Do not skip reading files when the script reports generic names or placeholder content.

## Step 3: Evaluate ⚠️ REQUIRED

Load `references/criterios-ios-swiftui.md` for the selected `--area`:

| --area | Evaluate |
|--------|----------|
| `structure` | Folder layout, entry point, feature boundaries, naming |
| `tests` | Swift Testing setup, coverage of core logic, test helpers |
| `config` | pbxproj, deployment targets, bundle ID, concurrency flags |
| `ui` | SwiftUI patterns, navigation readiness, state management hooks |
| `assets` | Assets.xcassets, localization, string catalogs |
| `all` | All domains above |

For each domain, answer:
1. What exists today? (cite path)
2. Is it generic Xcode template or Zanzar-specific?
3. Does it support the stated/planned features?
4. What gap blocks the next feature?

If the user named a planned feature in `$ARGUMENTS`, add a **Feature Readiness** section: blockers, prerequisites, and structural options.

Prioritize findings:

| Level | Meaning |
|-------|---------|
| P0 | Blocks building planned features or hides wrong product identity |
| P1 | Should fix before feature work spreads |
| P2 | Improves maintainability; safe to defer briefly |
| P3 | Polish or convention nit |

## Step 4: Report ⚠️ REQUIRED

Load `references/formato-relatorio.md` and produce the report in the user's language (Portuguese or English).

Each improvement option must include:
- **What** — concrete change
- **Why** — tied to vision or a P0/P1 finding
- **Trade-off** — cost, complexity, or what it postpones
- **Effort** — S / M / L

Present 2–3 options per major gap when valid approaches exist (minimal / recommended / ideal). Do not pick one for the user unless they ask.

End with: "Quer que eu implemente alguma opção?" — do not implement in this skill run.

## Anti-Patterns

Do NOT:
- Edit, create, or delete any file during the audit
- Give generic SwiftUI advice unrelated to this project's structure
- List findings without file paths or pbxproj settings
- Treat all issues as equal severity
- Assume product vision when context is missing (ask instead, unless `--quick`)
- Audit `.claude/skills/` or repo tooling as part of boilerplate
- Recommend third-party dependencies without noting the project rule to ask first
- Suggest changes that violate project Swift rules (`@Observable`, NavigationStack, FormatStyle, etc.)

## Pre-Delivery Checklist

### Read-only
- [ ] No project files were modified
- [ ] Scope stayed within `ZanzarProject/`

### Report quality
- [ ] Structure map included
- [ ] Every P0/P1 finding cites a file path or build setting
- [ ] Generic vs Zanzar-specific called out explicitly
- [ ] Assumptions labeled when vision was inferred
- [ ] Improvement options have What / Why / Trade-off / Effort
- [ ] Feature-specific question answered if present in `$ARGUMENTS`

### Completeness
- [ ] Selected `--area` fully covered
- [ ] User asked about vision when it was missing (unless `--quick`)
