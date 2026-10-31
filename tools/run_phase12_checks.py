#!/usr/bin/env python3
"""Run the relevant Godot checks with separate settings/save paths and timeouts."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

DEFAULT_TESTS = [
    "settings_ui_test", "smoke_test", "opening_test", "music_test",
    "chapter1_ui_test", "chapter1_navigation_test", "boy_atlas_test",
    "chapter2_pause_menu_test", "chapter2_combat_test", "combination_lock_test",
    "wrapping_puzzle_test", "table_slide_test", "mushroom_guidance_test",
    "acorn_memory_test", "save_manager_test", "story_cave_checkpoint_test",
    "finale_preview_menu_test", "finale_audio_test", "finale_routes_test",
]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("tests", nargs="*", default=DEFAULT_TESTS)
    parser.add_argument("--godot", default="/Users/missdaidai/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--output", default="/tmp/piggy-phase12-checks")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=True)
    results = []
    for name in args.tests:
        env = dict(os.environ)
        env["PIGGY_SETTINGS_PATH"] = str(out / (name + "-settings.cfg"))
        env["PIGGY_SAVE_PATH"] = str(out / (name + "-save.json"))
        # A previous test run's preferences must not determine this run's baseline.
        Path(env["PIGGY_SETTINGS_PATH"]).unlink(missing_ok=True)
        cmd = [args.godot, "--headless", "--path", str(root), "--fixed-fps", "60",
               "--log-file", str(out / (name + "-engine.log")),
               "--script", "res://tests/" + name + ".gd"]
        start = time.monotonic()
        try:
            with (out / (name + ".log")).open("w") as stream:
                result = subprocess.run(cmd, env=env, cwd=root, stdout=stream, stderr=subprocess.STDOUT, text=True, timeout=150)
            log = (out / (name + ".log")).read_text()
            code = result.returncode
        except subprocess.TimeoutExpired as error:
            log = (out / (name + ".log")).read_text() + "\nTEST_TIMEOUT\n"
            code = 124
        (out / (name + ".log")).write_text(log)
        passed = code == 0 and "_OK" in log and "SCRIPT ERROR" not in log and "TEST_TIMEOUT" not in log
        results.append({"test": name, "passed": passed, "exit_code": code,
                        "seconds": round(time.monotonic()-start, 2), "log": name+".log"})
        print(name, "PASS" if passed else "FAIL", flush=True)
        (out / "results.json").write_text(json.dumps(results, indent=2))
    raise SystemExit(0 if all(item["passed"] for item in results) else 1)

if __name__ == "__main__":
    main()
