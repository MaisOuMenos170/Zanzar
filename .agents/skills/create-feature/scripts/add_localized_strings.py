#!/usr/bin/env python3
"""
Upsert entries into Resources/Localizable.xcstrings (Xcode String Catalog
JSON), with English (US) and Brazilian Portuguese translations.

Usage (single entry):
    add_localized_strings.py --key "issueReport.submitButton.title" \\
        --en "Submit" --pt-br "Enviar" [--repo-root PATH]

Usage (batch, from a JSON file):
    add_localized_strings.py --entries-file entries.json [--repo-root PATH]

entries.json is a JSON array of objects: [{"key": "...", "en": "...", "ptBR": "..."}, ...]

Keys should follow <featureName>.<componentName>.<action>, e.g.
"issueReport.submitButton.title". A key with a different shape is still
written, but a warning is printed.

Existing keys are updated in place (both locales overwritten with the given
values); the catalog is never otherwise reordered or reformatted beyond
standard JSON indentation. Safe to re-run.
"""

import argparse
import json
import re
import sys
from pathlib import Path

KEY_PATTERN = re.compile(r"^[a-z][a-zA-Z0-9]*(\.[a-z][a-zA-Z0-9]*){1,}$")

TEMPLATE = {
    "sourceLanguage": "en",
    "strings": {},
    "version": "1.0",
}


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    for candidate in [current, *current.parents]:
        if (candidate / "ZanzarProject" / "ZanzarProject.xcodeproj").exists():
            return candidate
    raise SystemExit(
        "Could not find ZanzarProject/ZanzarProject.xcodeproj above "
        f"{start}. Pass --repo-root explicitly."
    )


def load_catalog(path: Path) -> dict:
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        return json.loads(json.dumps(TEMPLATE))
    return json.loads(path.read_text())


def make_entry(en: str, pt_br: str) -> dict:
    return {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": en}},
            "pt-BR": {"stringUnit": {"state": "translated", "value": pt_br}},
        },
    }


def upsert(catalog: dict, key: str, en: str, pt_br: str, report: list) -> None:
    if not KEY_PATTERN.match(key):
        report.append(
            f"  warning: '{key}' does not look like <featureName>.<componentName>.<action>"
        )
    action = "updated" if key in catalog["strings"] else "added"
    catalog["strings"][key] = make_entry(en, pt_br)
    report.append(f"  {action}: {key}")


def save_catalog(path: Path, catalog: dict) -> None:
    catalog["strings"] = dict(sorted(catalog["strings"].items()))
    path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=False) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo-root", type=Path, default=None, help="Override auto-detected repo root")
    parser.add_argument("--key", help="Single entry: string key")
    parser.add_argument("--en", help="Single entry: English (US) value")
    parser.add_argument("--pt-br", help="Single entry: Brazilian Portuguese value")
    parser.add_argument("--entries-file", type=Path, help="Batch: JSON file with [{key, en, ptBR}, ...]")
    args = parser.parse_args()

    if not args.entries_file and not (args.key and args.en and args.pt_br):
        raise SystemExit("Pass either --entries-file, or all of --key/--en/--pt-br.")

    repo_root = args.repo_root or find_repo_root(Path.cwd())
    catalog_path = repo_root / "ZanzarProject" / "ZanzarProject" / "Resources" / "Localizable.xcstrings"

    catalog = load_catalog(catalog_path)
    report = [f"Localizable.xcstrings ({catalog_path}):"]

    if args.entries_file:
        entries = json.loads(args.entries_file.read_text())
        for entry in entries:
            upsert(catalog, entry["key"], entry["en"], entry["ptBR"], report)
    else:
        upsert(catalog, args.key, args.en, args.pt_br, report)

    save_catalog(catalog_path, catalog)
    print("\n".join(report))


if __name__ == "__main__":
    main()
