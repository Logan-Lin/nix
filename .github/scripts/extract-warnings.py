#!/usr/bin/env python3
"""Parse a timestamped internal-json nix build log into JSONL of diagnostics.

Input lines look like:
    1729800123 @nix {"action":"msg","level":1,"msg":"...","raw":"..."}

Only msg events with level 0 (error), 1 (warn), or 2 (notice) are emitted.
Output is one JSON object per line: {"level": <int>, "msg": <str>}.
"""
import json
import sys


def main() -> None:
    for raw in sys.stdin:
        line = raw.rstrip("\n")
        _, _, rest = line.partition(" ")
        if not rest.startswith("@nix "):
            continue
        try:
            data = json.loads(rest[5:])
        except json.JSONDecodeError:
            continue
        if data.get("action") != "msg":
            continue
        level = data.get("level")
        if level not in (0, 1, 2):
            continue
        msg = (data.get("msg") or data.get("raw") or "").strip()
        if not msg:
            continue
        print(json.dumps({"level": level, "msg": msg}))


if __name__ == "__main__":
    main()
