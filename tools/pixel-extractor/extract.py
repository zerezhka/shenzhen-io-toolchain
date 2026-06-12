#!/usr/bin/env python3
"""Extract behavioral test data from verification-tab screenshots.

Usage:
    python3 tools/pixel-extractor/extract.py <level> [--dump] [--out-dir DIR]
    python3 tools/pixel-extractor/extract.py --batch [--out-dir DIR]

<level> names a mapping config in tools/pixel-extractor/levels/<level>.yaml.
--dump prints per-time-unit values to stdout instead of writing files (for
human spot-checks against the zoomed screenshot).

Exit code is non-zero if any requested level fails to extract.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image

from panel import PanelError, find_bands
from traces import extract_traces
from emit import emit_yaml

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(TOOL_DIR, "..", ".."))
LEVELS_DIR = os.path.join(TOOL_DIR, "levels")


def load_config(path):
    """Parse the mapping-config YAML subset (flat keys, one list of flat maps,
    one flat nested map). Not a general YAML parser by design."""
    cfg = {"screenshots": [], "traces": [], "ports": {}}
    key = None
    with open(path) as f:
        for raw in f:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip())
            text = line.strip()
            if indent == 0:
                k, _, v = text.partition(":")
                key = k.strip()
                v = v.strip().strip('"')
                if v:
                    cfg[key] = v
                    key = None
                elif key not in cfg:
                    cfg[key] = {}
            elif text.startswith("- "):
                item = text[2:].strip()
                if ":" in item:
                    k, _, v = item.partition(":")
                    cfg[key].append({k.strip(): v.strip().strip('"')})
                else:
                    cfg[key].append(item.strip('"'))
            else:
                k, _, v = text.partition(":")
                k, v = k.strip(), v.strip().strip('"')
                if isinstance(cfg[key], list):
                    cfg[key][-1][k] = v
                else:
                    cfg[key][k] = v
    for t in cfg["traces"]:
        for field in ("name", "direction", "class"):
            if field not in t:
                raise PanelError(f"{path}: trace missing '{field}'")
    return cfg


def extract_level(name, out_dir, dump=False):
    """Returns list of (screenshot, status, detail). Raises nothing."""
    cfg_path = os.path.join(LEVELS_DIR, name + ".yaml")
    if not os.path.exists(cfg_path):
        return [(name, "skipped", "no mapping config (needs mapping)")]
    results = []
    try:
        cfg = load_config(cfg_path)
    except Exception as exc:  # config is hand-written; report, don't crash
        return [(name, "failed", f"bad mapping config: {exc}")]

    for shot in cfg["screenshots"]:
        shot_abs = os.path.join(REPO_ROOT, shot)
        try:
            im = Image.open(shot_abs).convert("RGB")
            if im.size != (1920, 1080):
                raise PanelError(f"unsupported resolution {im.size}")
            bands = find_bands(im)
            if not bands:
                results.append((shot, "skipped", "no verification panel visible"))
                continue
            traces, n_units, warnings = extract_traces(im, bands, cfg["traces"])
            for w in warnings:
                print(f"  warning [{shot}]: {w}", file=sys.stderr)
            if dump:
                print(f"{shot}: {n_units} time units")
                for t in traces:
                    vals = t["values"]
                    print(f"  {t['name']:>12} ({t['direction']:>6}): "
                          + ("<xbus skipped>" if vals is None else " ".join(
                              f"{v:3d}" for v in vals)))
                results.append((shot, "extracted", "(dump only)"))
                continue
            out_path = os.path.join(
                out_dir, cfg["level"],
                os.path.splitext(os.path.basename(shot))[0] + ".yaml")
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            text = emit_yaml(cfg["level"], shot, os.path.relpath(cfg_path, REPO_ROOT),
                             os.path.join(REPO_ROOT, cfg["program"]), traces,
                             n_units, out_path)
            with open(out_path, "w") as f:
                f.write(text)
            partial = any(t["values"] is None for t in traces)
            results.append((shot, "extracted",
                            os.path.relpath(out_path, REPO_ROOT)
                            + (" [partial: xbus skipped]" if partial else "")))
        except PanelError as exc:
            results.append((shot, "failed", str(exc)))
        except OSError as exc:
            results.append((shot, "failed", f"cannot read image: {exc}"))
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("level", nargs="?", help="level name (mapping config stem)")
    ap.add_argument("--batch", action="store_true",
                    help="process every level dir in the shiawasenahikari set")
    ap.add_argument("--dump", action="store_true", help="print values, write nothing")
    ap.add_argument("--out-dir", default=os.path.join(REPO_ROOT, "examples", "extracted"))
    args = ap.parse_args()

    if args.batch:
        shots_root = os.path.join(REPO_ROOT, "third_party", "solutions-shiawasenahikari")
        levels = sorted(d for d in os.listdir(shots_root)
                        if os.path.isdir(os.path.join(shots_root, d)) and d[0].isdigit())
    elif args.level:
        levels = [args.level]
    else:
        ap.error("give a level name or --batch")

    counts = {"extracted": 0, "skipped": 0, "failed": 0}
    for level in levels:
        for shot, status, detail in extract_level(level, args.out_dir, args.dump):
            counts[status] += 1
            print(f"{status:>9}  {shot}  {detail}")
    print(f"\ntotal: {counts['extracted']} extracted, "
          f"{counts['skipped']} skipped, {counts['failed']} failed")
    sys.exit(1 if counts["failed"] else 0)


if __name__ == "__main__":
    main()
