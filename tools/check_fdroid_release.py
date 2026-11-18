#!/usr/bin/env python3
"""Check that the F-Droid recipe matches the latest release tag.

This is meant to be run before and after cutting a release tag during the
three-month maintenance period required by F-Droid's inclusion policy:

    python3 tools/check_fdroid_release.py

Use --strict when preparing a new tag to also require HEAD to be the tag's
commit, which means every change destined for the release is in the tag:

    python3 tools/check_fdroid_release.py --strict

Requires PyYAML (python3 -m pip install pyyaml).
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: python3 -m pip install pyyaml")

ROOT = Path(__file__).resolve().parents[1]
RECIPE = ROOT / "docs/fdroid/io.github.gichuregaston.capitan.yml"
VERSION_RE = re.compile(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", re.MULTILINE)
TAG_RE = re.compile(r"^v\d+(?:\.\d+)*$")
SAFE_MATH_RE = re.compile(r"^[\d\s+\-*/()]+$")

# Flutter's ABI code -> (APK output name, --target-platform value).
ABIS = {
    1: ("app-armeabi-v7a-release.apk", "android-arm"),
    2: ("app-arm64-v8a-release.apk", "android-arm64"),
    4: ("app-x86_64-release.apk", "android-x64"),
}


def git(*args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def latest_tag() -> str | None:
    tags = git("tag", "--list", "v*", "--sort=-v:refname").splitlines()
    return next((tag for tag in tags if TAG_RE.match(tag)), None)


def eval_vercode(expression: str, base: int) -> int:
    """Evaluate a VercodeOperation such as '1000 + %c' for a base version code."""
    source = expression.replace("%c", str(base))
    if not SAFE_MATH_RE.fullmatch(source):
        raise ValueError(f"unsafe VercodeOperation: {expression!r}")
    return int(eval(source, {"__builtins__": {}}, {}))  # noqa: S307 - validated above


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="also require HEAD to be the commit pointed to by the release tag",
    )
    args = parser.parse_args()

    tag = latest_tag()
    if tag is None:
        print("FAIL: no release tag matching v<number> found")
        return 1

    commit = git("rev-parse", f"{tag}^{{commit}}")
    pubspec = git("show", f"{tag}:pubspec.yaml")
    match = VERSION_RE.search(pubspec)
    if match is None:
        print(f"FAIL: {tag}:pubspec.yaml has no version: X.Y.Z+N line")
        return 1
    version_name, version_code = match.group(1), int(match.group(2))

    recipe = yaml.safe_load(RECIPE.read_text(encoding="utf-8"))
    builds = recipe["Builds"]
    operations = recipe.get("VercodeOperation") or []
    checks = []

    try:
        expected_codes = [eval_vercode(op, version_code) for op in operations]
        abi_codes = [eval_vercode(op, 0) // 1000 for op in operations]
    except ValueError as exc:
        print(f"FAIL: {exc}")
        return 1

    checks.append(
        (
            bool(operations) and len(builds) == len(operations),
            "build/operation count",
            f"{len(builds)} builds / {len(operations)} operations",
            "one build per VercodeOperation",
        )
    )

    for index, (build, expected, abi) in enumerate(
        zip(builds, expected_codes, abi_codes), start=1
    ):
        output, platform = ABIS.get(abi, ("<unknown ABI>", "<unknown platform>"))
        command = " ".join(str(line) for line in (build.get("build") or []))
        checks.extend(
            [
                (build["versionName"] == version_name, f"build {index} versionName", build["versionName"], version_name),
                (build["versionCode"] == expected, f"build {index} versionCode", build["versionCode"], expected),
                (build["commit"] == commit, f"build {index} commit", build["commit"], commit),
                (build["output"] == f"build/app/outputs/flutter-apk/{output}", f"build {index} output", build["output"], output),
                (platform in command, f"build {index} target", platform, platform),
            ]
        )

    checks.append(
        (
            recipe["CurrentVersion"] == version_name,
            "CurrentVersion",
            recipe["CurrentVersion"],
            version_name,
        )
    )
    expected_current = max(expected_codes) if expected_codes else version_code
    checks.append(
        (
            recipe["CurrentVersionCode"] == expected_current,
            "CurrentVersionCode",
            recipe["CurrentVersionCode"],
            expected_current,
        )
    )

    changelog = f"fastlane/metadata/android/en-US/changelogs/{version_code}.txt"
    try:
        git("cat-file", "-e", f"{tag}:{changelog}")
        checks.append((True, "changelog", changelog, "present"))
    except subprocess.CalledProcessError:
        checks.append((False, "changelog", changelog, "missing"))

    if args.strict:
        head = git("rev-parse", "HEAD")
        checks.append((head == commit, "HEAD", head, commit))

    print(f"Release tag: {tag} ({commit[:12]})")
    failed = 0
    for ok, field, actual, expected in checks:
        print(f"{'ok  ' if ok else 'FAIL'} {field}: {actual}")
        if not ok:
            print(f"       expected: {expected}")
            failed += 1

    if failed:
        print(f"\n{failed} check(s) failed; see docs/fdroid.md before resubmitting.")
        return 1
    print("\nF-Droid recipe matches the latest release tag.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
