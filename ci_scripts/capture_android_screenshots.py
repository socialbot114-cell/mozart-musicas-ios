#!/usr/bin/env python3
"""Capture the main app screens from an Android emulator with adb."""

from __future__ import annotations

import argparse
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path


APP_PACKAGE = "br.com.musicaspara.estudar.debug"
APP_ACTIVITY = "br.com.musicaspara.estudar.MainActivity"
UI_HIERARCHY_PATH = "/sdcard/window.xml"
UI_TIMEOUT_SECONDS = 45


def run_adb(*arguments: str, timeout: int = 60) -> subprocess.CompletedProcess:
    command = ["adb", *arguments]
    try:
        return subprocess.run(command, check=True, capture_output=True, timeout=timeout)
    except subprocess.CalledProcessError as error:
        details = (error.stderr or error.stdout or b"").decode(errors="replace").strip()
        raise RuntimeError(f"adb command failed: {command}: {details}") from error


def read_hierarchy() -> ET.Element:
    run_adb("shell", "uiautomator", "dump", "--compressed", UI_HIERARCHY_PATH)
    result = run_adb("exec-out", "cat", UI_HIERARCHY_PATH)
    return ET.fromstring(result.stdout)


def find_text(root: ET.Element, text: str) -> ET.Element | None:
    for node in root.iter("node"):
        if node.attrib.get("text") == text or node.attrib.get("content-desc") == text:
            return node
    return None


def wait_for_text(text: str, timeout: int = UI_TIMEOUT_SECONDS) -> ET.Element:
    deadline = time.monotonic() + timeout
    last_root: ET.Element | None = None
    while time.monotonic() < deadline:
        last_root = read_hierarchy()
        node = find_text(last_root, text)
        if node is not None:
            return node
        time.sleep(1)

    visible_texts = []
    if last_root is not None:
        visible_texts = [
            node.attrib.get("text", "")
            for node in last_root.iter("node")
            if node.attrib.get("text")
        ]
    raise RuntimeError(f"Timed out waiting for {text!r}; visible text: {visible_texts}")


def tap_node(node: ET.Element) -> None:
    bounds = node.attrib.get("bounds", "")
    values = [
        int(value)
        for value in bounds.replace("][", ",").replace("[", "").replace("]", "").split(",")
    ]
    if len(values) != 4:
        raise RuntimeError(f"Cannot tap node with invalid bounds: {bounds!r}")
    left, top, right, bottom = values
    x, y = (left + right) // 2, (top + bottom) // 2
    run_adb("shell", "input", "tap", str(x), str(y))


def capture_screenshot(output_directory: Path, filename: str) -> None:
    result = run_adb("exec-out", "screencap", "-p")
    output_path = output_directory / filename
    output_path.write_bytes(result.stdout)
    if not result.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError(f"Screenshot is not a valid PNG: {output_path}")
    print(f"Saved {output_path}")


def capture_screen(output_directory: Path, ready_text: str, filename: str) -> None:
    wait_for_text(ready_text)
    time.sleep(1)
    capture_screenshot(output_directory, filename)


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
    run_adb(
        "shell", "am", "start", "-W", "-n", f"{APP_PACKAGE}/{APP_ACTIVITY}", timeout=60
    )

    capture_screen(args.output, "Bom estudo", "01-inicio.png")
    tap_node(wait_for_text("Explorar"))
    capture_screen(args.output, "Estude do seu jeito", "02-explorar.png")
    tap_node(wait_for_text("Foco"))
    capture_screen(args.output, "Sessão de foco", "03-foco.png")
    tap_node(wait_for_text("Biblioteca"))
    capture_screen(args.output, "Biblioteca de compositores", "04-biblioteca.png")


if __name__ == "__main__":
    main()
