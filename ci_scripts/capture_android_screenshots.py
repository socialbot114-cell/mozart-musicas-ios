#!/usr/bin/env python3
"""Capture the main app screens from an Android emulator with adb."""

from __future__ import annotations

import argparse
import re
import subprocess
import time
from pathlib import Path


APP_PACKAGE = "br.com.musicaspara.estudar.debug"
APP_ACTIVITY = "br.com.musicaspara.estudar.MainActivity"
NAVIGATION_DESTINATIONS = 4
BOTTOM_NAV_CENTER_OFFSET_DP = 64


def run_adb(*arguments: str, timeout: int = 60) -> subprocess.CompletedProcess:
    command = ["adb", *arguments]
    try:
        return subprocess.run(command, check=True, capture_output=True, timeout=timeout)
    except subprocess.CalledProcessError as error:
        details = (error.stderr or error.stdout or b"").decode(errors="replace").strip()
        raise RuntimeError(f"adb command failed: {command}: {details}") from error


def display_metrics() -> tuple[int, int, int]:
    size_output = run_adb("shell", "wm", "size").stdout.decode(errors="replace")
    density_output = run_adb("shell", "wm", "density").stdout.decode(errors="replace")
    sizes = re.findall(r"(?:Physical|Override) size:\s*(\d+)x(\d+)", size_output)
    densities = re.findall(r"(?:Physical|Override) density:\s*(\d+)", density_output)
    if not sizes or not densities:
        raise RuntimeError(f"Could not read emulator display metrics: {size_output!r} {density_output!r}")
    width, height = map(int, sizes[-1])
    density = int(densities[-1])
    return width, height, density


def tap_navigation_tab(index: int, width: int, height: int, density: int) -> None:
    x = round(width * (index + 0.5) / NAVIGATION_DESTINATIONS)
    y = height - round(BOTTOM_NAV_CENTER_OFFSET_DP * density / 160)
    print(f"Tap navigation destination {index + 1} at ({x}, {y})")
    run_adb("shell", "input", "tap", str(x), str(y))


def capture_screenshot(output_directory: Path, filename: str) -> None:
    result = run_adb("exec-out", "screencap", "-p")
    output_path = output_directory / filename
    output_path.write_bytes(result.stdout)
    if not result.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError(f"Screenshot is not a valid PNG: {output_path}")
    print(f"Saved {output_path}")


def capture_screen(output_directory: Path, title: str, filename: str) -> None:
    time.sleep(1)
    print(f"Capturing {title}")
    capture_screenshot(output_directory, filename)


def dismiss_system_ui_anr_dialog(width: int, height: int) -> None:
    window_dump = run_adb("shell", "dumpsys", "window", "windows").stdout.decode(errors="replace").lower()
    if "not responding" not in window_dump:
        print("No system ANR dialog detected")
        return

    # The emulator may show a transient ANR dialog from Settings or System UI.
    x = round(width * 0.42)
    y = round(height * 0.50)
    print(f"Dismiss system ANR dialog at ({x}, {y})")
    run_adb("shell", "input", "tap", str(x), str(y))


def select_tab(index: int, width: int, height: int, density: int) -> None:
    tap_navigation_tab(index, width, height, density)
    time.sleep(3)
    dismiss_system_ui_anr_dialog(width, height)
    tap_navigation_tab(index, width, height, density)
    time.sleep(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--apk",
        type=Path,
        default=Path("app/build/outputs/apk/debug/app-debug.apk"),
    )
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    apk_path = args.apk
    if not apk_path.is_file():
        raise FileNotFoundError(f"Debug APK not found: {apk_path}")

    run_adb("install", "-r", str(apk_path), timeout=600)
    run_adb("shell", "am", "force-stop", APP_PACKAGE)
    start_result = run_adb("shell", "am", "start", "-n", f"{APP_PACKAGE}/{APP_ACTIVITY}", timeout=60)
    start_output = start_result.stdout.decode(errors="replace")
    if "Error:" in start_output:
        raise RuntimeError(f"App did not start successfully: {start_output}")
    print(start_output.strip())
    time.sleep(1)

    width, height, density = display_metrics()
    capture_screen(args.output, "Início", "01-inicio.png")
    select_tab(1, width, height, density)
    capture_screen(args.output, "Explorar", "02-explorar.png")
    select_tab(2, width, height, density)
    capture_screen(args.output, "Foco", "03-foco.png")
    select_tab(3, width, height, density)
    capture_screen(args.output, "Biblioteca", "04-biblioteca.png")


if __name__ == "__main__":
    main()
