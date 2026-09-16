#!/usr/bin/env python3
"""Scan ZanzarProject for boilerplate signals. Read-only — prints JSON to stdout."""

import json
import re
import sys
from pathlib import Path

GENERIC_TYPE_NAMES = {
    "MyApp",
    "ContentView",
    "App",
    "Item",
}

GENERIC_STRINGS = [
    "Hello, world!",
    "Hello World",
    "Write your test here",
]

PBXPROJ_KEYS = [
    "IPHONEOS_DEPLOYMENT_TARGET",
    "PRODUCT_BUNDLE_IDENTIFIER",
    "SWIFT_DEFAULT_ACTOR_ISOLATION",
    "SWIFT_APPROACHABLE_CONCURRENCY",
    "TARGETED_DEVICE_FAMILY",
    "SUPPORTED_PLATFORMS",
    "STRING_CATALOG_GENERATE_SYMBOLS",
]


def swift_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.swift"))


def scan_swift(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    rel = path.as_posix()
    findings: dict = {"path": rel, "signals": []}

    for name in GENERIC_TYPE_NAMES:
        if re.search(rf"\b(struct|class|enum|actor)\s+{re.escape(name)}\b", text):
            findings["signals"].append(f"generic_type:{name}")

    for snippet in GENERIC_STRINGS:
        if snippet in text:
            findings["signals"].append(f"placeholder_string:{snippet!r}")

    if "#Playground" in text:
        findings["signals"].append("playground_in_app_target")

    if re.search(r"@Test\s+func\s+example\b", text):
        findings["signals"].append("placeholder_test:example")

    if "import Playgrounds" in text:
        findings["signals"].append("import_playgrounds")

    if "ObservableObject" in text or "@StateObject" in text:
        findings["signals"].append("legacy_observable_pattern")

    if "NavigationStack" not in text and "struct ContentView" in text:
        findings["signals"].append("no_navigation_stack_in_content_view")

    todo_count = len(re.findall(r"\b(TODO|FIXME|XXX)\b", text))
    if todo_count:
        findings["signals"].append(f"markers:TODO/FIXME={todo_count}")

    if findings["signals"]:
        return findings
    return {"path": rel, "signals": ["clean"]}


def parse_pbxproj(pbxproj: Path) -> dict:
    text = pbxproj.read_text(encoding="utf-8", errors="replace")
    configs: dict[str, dict[str, str]] = {}

    blocks = re.split(r"/\* (Debug|Release) configuration for PBXNativeTarget \"([^\"]+)\" \*/", text)
    # blocks: [prefix, Debug, ZanzarProject, body, Release, ZanzarProject, body, ...]
    i = 1
    while i + 2 < len(blocks):
        build_type = blocks[i]
        target = blocks[i + 1]
        body = blocks[i + 2]
        key = f"{target} ({build_type})"
        settings: dict[str, str] = {}
        for line_key in PBXPROJ_KEYS:
            match = re.search(rf"^\s*{re.escape(line_key)}\s*=\s*(.+);", body, re.MULTILINE)
            if match:
                settings[line_key] = match.group(1).strip().strip('"')
        if settings:
            configs[key] = settings
        i += 3

    mismatches: list[str] = []
    app_targets = {k: v for k, v in configs.items() if k.startswith("ZanzarProject (") and "Tests" not in k}
    test_targets = {k: v for k, v in configs.items() if "ZanzarProjectTests" in k}

    app_ios = {v.get("IPHONEOS_DEPLOYMENT_TARGET") for v in app_targets.values()}
    test_ios = {v.get("IPHONEOS_DEPLOYMENT_TARGET") for v in test_targets.values()}
    if app_ios and test_ios and app_ios != test_ios:
        mismatches.append(f"deployment_target_mismatch:app={sorted(app_ios)} tests={sorted(test_ios)}")

    for settings in app_targets.values():
        bundle = settings.get("PRODUCT_BUNDLE_IDENTIFIER", "")
        if "devplaceholder" in bundle or "example" in bundle.lower():
            mismatches.append(f"placeholder_bundle_id:{bundle}")

    return {"targets": configs, "mismatches": mismatches}


def file_tree(root: Path, max_depth: int = 4) -> list[str]:
    lines: list[str] = []
    root = root.resolve()
    for path in sorted(root.rglob("*")):
        if any(part.startswith(".") for part in path.relative_to(root).parts):
            continue
        if path.is_dir():
            continue
        rel = path.relative_to(root)
        if len(rel.parts) > max_depth:
            continue
        lines.append(rel.as_posix())
    return lines


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: inventario.py <path-to-ZanzarProject>", file=sys.stderr)
        return 1

    project_root = Path(sys.argv[1]).resolve()
    if not project_root.is_dir():
        print(json.dumps({"error": f"not a directory: {project_root}"}))
        return 1

    app_dir = project_root / "ZanzarProject"
    tests_dir = project_root / "ZanzarProjectTests"
    pbxproj = project_root / "ZanzarProject.xcodeproj" / "project.pbxproj"

    swift_scan = [scan_swift(p) for p in swift_files(project_root)]
    flagged = [s for s in swift_scan if s["signals"] != ["clean"]]

    assets_dir = app_dir / "Assets.xcassets"
    has_string_catalog = any(project_root.rglob("*.xcstrings"))

    report = {
        "project_root": str(project_root),
        "file_tree": file_tree(project_root),
        "swift_files": len(swift_scan),
        "flagged_swift": flagged,
        "has_assets": assets_dir.is_dir(),
        "has_string_catalog": has_string_catalog,
        "pbxproj": parse_pbxproj(pbxproj) if pbxproj.is_file() else {"error": "project.pbxproj not found"},
    }

    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
