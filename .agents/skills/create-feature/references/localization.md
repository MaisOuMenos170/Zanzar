# Localizing feature strings

Every user-facing string a View or Component displays — button titles, labels,
placeholders, alerts, accessibility labels — goes into
`Resources/Localizable.xcstrings`, never as a hardcoded literal left
untranslated. The project already builds with `LOCALIZATION_PREFERS_STRING_CATALOGS`
and `STRING_CATALOG_GENERATE_SYMBOLS`, so this is the project's real
localization mechanism, not optional scaffolding.

Two locales, every time:
- **`en`** — English (US). This is also the catalog's `sourceLanguage`,
  matching the Xcode project's `developmentRegion`.
- **`pt-BR`** — Brazilian Portuguese.

Never add a key with only one locale filled in.

## Key naming

`<featureName>.<componentName>.<action>`, each segment lowerCamelCase:

```
issueReport.submitButton.title
issueReport.descriptionField.placeholder
issueReport.header.subtitle
issueReport.submissionFailedAlert.message
```

`featureName` matches the feature's folder name (lowerCamelCase of the
PascalCase `<FeatureName>`). `componentName` is the specific control/section
the string belongs to, not the whole screen. `action` is what the string
does: `title`, `placeholder`, `message`, `label`, `subtitle`, `buttonTitle` if
`componentName` alone is ambiguous, etc.

## Workflow

1. While writing the View/Component (create-feature Step 6), collect every
   string literal you'd otherwise hardcode instead of writing it inline.
2. Add them all at once with `scripts/add_localized_strings.py`, either one
   at a time:

   ```bash
   python3 scripts/add_localized_strings.py \
     --key "issueReport.submitButton.title" \
     --en "Submit" --pt-br "Enviar"
   ```

   or in batch from a JSON file (preferred for a whole screen's strings):

   ```bash
   python3 scripts/add_localized_strings.py --entries-file /tmp/issue_report_strings.json
   ```

   where the file is a JSON array: `[{"key": "...", "en": "...", "ptBR": "..."}, ...]`.

3. Reference the key directly in SwiftUI — do not hand-write generated-symbol
   names, they're compiler-generated and unpredictable before a build:

   ```swift
   Text("issueReport.header.subtitle")
   TextField("issueReport.descriptionField.placeholder", text: $description)
   Button("issueReport.submitButton.title") { /* ... */ }
   ```

   For a string with a dynamic value, use a format string with `%@`/`%lld`
   and `String(format:)`, or interpolate directly in a `Text` (SwiftUI keys
   the catalog lookup off the interpolated `LocalizedStringKey` pattern) —
   ask if the dynamic case isn't obvious rather than guessing the substitution
   syntax.

The script is idempotent and upserts by key — safe to re-run if a string's
copy changes later; it will warn (not block) if a key doesn't match the
`<featureName>.<componentName>.<action>` shape.
