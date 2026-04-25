#!/usr/bin/env python3
"""Parse a timestamped internal-json nix build log into TSV: drv_path<TAB>seconds.

Input lines look like:
    1729800123 @nix {"action":"start","id":7,"type":105,"fields":["/nix/store/...drv",...],...}
    1729800180 @nix {"action":"stop","id":7}

Only actBuild (type=105) start/stop pairs are emitted.
"""
import json
import sys


def main() -> None:
    start_times: dict[int, int] = {}
    drvs: dict[int, str] = {}
    results: list[tuple[str, int]] = []

    for raw in sys.stdin:
        line = raw.rstrip("\n")
        ts_str, _, rest = line.partition(" ")
        if not rest.startswith("@nix "):
            continue
        try:
            ts = int(ts_str)
            data = json.loads(rest[5:])
        except (ValueError, json.JSONDecodeError):
            continue

        action = data.get("action")
        nid = data.get("id")
        if nid is None:
            continue

        if action == "start" and data.get("type") == 105:
            start_times[nid] = ts
            fields = data.get("fields") or []
            if fields:
                drvs[nid] = fields[0]
        elif action == "stop" and nid in start_times:
            duration = ts - start_times.pop(nid)
            drv = drvs.pop(nid, None)
            if drv:
                results.append((drv, duration))

    results.sort(key=lambda x: -x[1])
    for drv, dur in results:
        print(f"{drv}\t{dur}")


if __name__ == "__main__":
    main()
