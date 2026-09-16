#!/usr/bin/env python3
"""
Scaffold a new MVVM-C feature folder (and, on first run, the shared
Coordinator/Utils/App structure) for the ZanzarProject Xcode project.

Usage:
    scaffold_feature.py <FeatureName> [--repo-root PATH]

Example:
    scaffold_feature.py IssueReport

<FeatureName> must be PascalCase (e.g. IssueReport, UserProfile).

The Xcode project uses file-system-synchronized groups, so any file created
under ZanzarProject/ZanzarProject is picked up by the build target
automatically -- no .xcodeproj editing needed.

Never overwrites an existing file. Existing files are reported as
"skipped (exists)" so re-running is always safe.
"""

import argparse
import re
import sys
from pathlib import Path

TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "assets" / "templates"


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    for candidate in [current, *current.parents]:
        if (candidate / "ZanzarProject" / "ZanzarProject.xcodeproj").exists():
            return candidate
    raise SystemExit(
        "Could not find ZanzarProject/ZanzarProject.xcodeproj above "
        f"{start}. Pass --repo-root explicitly."
    )


def validate_feature_name(name: str) -> None:
    if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", name):
        raise SystemExit(
            f"'{name}' is not PascalCase. Use something like IssueReport, "
            "UserProfile, OrderHistory."
        )


def lower_first(name: str) -> str:
    return name[0].lower() + name[1:]


def render(template_name: str, feature: str = "") -> str:
    text = (TEMPLATES_DIR / template_name).read_text()
    if not feature:
        return text
    return text.replace("__FEATURE__", feature).replace("__feature__", lower_first(feature))


def write_if_missing(path: Path, content: str, report: list) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        report.append(f"  skipped (exists): {path}")
        return
    path.write_text(content)
    report.append(f"  created: {path}")


def bootstrap_root_structure(app_root: Path, report: list) -> None:
    report.append("Bootstrap check:")

    app_dir = app_root / "App"
    app_dir.mkdir(parents=True, exist_ok=True)
    for filename in ("ContentView.swift", "MyApp.swift"):
        loose_file = app_root / filename
        target_file = app_dir / filename
        if loose_file.exists() and not target_file.exists():
            loose_file.rename(target_file)
            report.append(f"  moved: {loose_file} -> {target_file}")
        elif target_file.exists():
            report.append(f"  skipped (exists): {target_file}")

    coordinator_dir = app_root / "Coordinator"
    write_if_missing(coordinator_dir / "AppCoordinator.swift", render("AppCoordinator.swift.template", ""), report)
    write_if_missing(coordinator_dir / "Routes.swift", render("Routes.swift.template", ""), report)

    utils_dir = app_root / "Utils"
    write_if_missing(utils_dir / "NetworkClient.swift", render("NetworkClient.swift.template", ""), report)

    (app_root / "Extensions").mkdir(parents=True, exist_ok=True)


def scaffold_feature(app_root: Path, tests_root: Path, feature: str, report: list) -> None:
    feature_dir = app_root / "Features" / feature
    report.append(f"Feature '{feature}':")

    write_if_missing(feature_dir / "API" / f"{feature}Service.swift", render("Service.swift.template", feature), report)
    write_if_missing(feature_dir / "Models" / f"{feature}.swift", render("Model.swift.template", feature), report)
    write_if_missing(feature_dir / "ViewModels" / f"{feature}ViewModel.swift", render("ViewModel.swift.template", feature), report)
    write_if_missing(feature_dir / "Views" / f"{feature}View.swift", render("View.swift.template", feature), report)
    (feature_dir / "Views" / "Components").mkdir(parents=True, exist_ok=True)

    test_dir = tests_root / feature
    write_if_missing(test_dir / f"{feature}ViewModelTests.swift", render("ViewModelTests.swift.template", feature), report)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("feature", help="PascalCase feature name, e.g. IssueReport")
    parser.add_argument("--repo-root", type=Path, default=None, help="Override auto-detected repo root")
    args = parser.parse_args()

    validate_feature_name(args.feature)

    repo_root = args.repo_root or find_repo_root(Path.cwd())
    app_root = repo_root / "ZanzarProject" / "ZanzarProject"
    tests_root = repo_root / "ZanzarProject" / "ZanzarProjectTests"

    report: list = []
    bootstrap_root_structure(app_root, report)
    scaffold_feature(app_root, tests_root, args.feature, report)

    print("\n".join(report))


if __name__ == "__main__":
    main()
