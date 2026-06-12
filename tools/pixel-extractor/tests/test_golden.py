"""Golden tests: extracted traces must match the human-verified transcription.

The expected sequences below were verified on 2026-06-12 by overlaying the
extracted per-unit values back onto the source screenshots (green-dot overlay)
and checking every dot sits on the trace. They pin the extractor's behavior;
a change here needs the same overlay re-verification.

Skips when third_party screenshots are not present (they are vendored, but
keep CI without them working).
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SHOTS = os.path.join(REPO, "third_party", "solutions-shiawasenahikari")

CAMERA_ACTIVE = ([0] * 6 + [100] * 6) * 3 + [0] * 6 + [100] * 4
CAMERA_NETWORK = ([0, 0, 0, 0, 100, 100, 0, 100] * 6)[:46]
PULSE_BUTTON = [0, 0, 0] + [100] * 8 + [0] * 4 + [100] * 6 + [0] * 5 + [100] * 11 \
    + [0] * 6 + [100] * 8 + [0] * 5 + [100] * 4
# pulse toggles 100/0 each unit while button is held, starting on the press unit
PULSE_PULSE = [0, 0, 0, 100, 0, 100, 0, 100, 0, 100, 0, 0, 0, 0, 0,
               100, 0, 100, 0, 100, 0, 0, 0, 0, 0, 0,
               100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 100, 0, 0, 0, 0, 0, 0,
               100, 0, 100, 0, 100, 0, 100, 0, 0, 0, 0, 0, 0,
               100, 0, 100, 0]


def extract(level_dir, shot, defs):
    from PIL import Image
    from panel import find_bands
    from traces import extract_traces
    im = Image.open(os.path.join(SHOTS, level_dir, shot)).convert("RGB")
    bands = find_bands(im)
    traces, n_units, warnings = extract_traces(im, bands, defs)
    return {t["name"]: t["values"] for t in traces}, n_units, warnings


@unittest.skipUnless(os.path.isdir(SHOTS), "third_party screenshots not present")
class GoldenTraces(unittest.TestCase):
    def test_camera(self):
        values, n, _ = extract(
            "001-fake-surveillance-camera", "screenshot0.png",
            [{"name": "active", "direction": "output", "class": "binary"},
             {"name": "network", "direction": "output", "class": "binary"}])
        self.assertEqual(n, 46)
        self.assertEqual(values["active"], CAMERA_ACTIVE)
        self.assertEqual(values["network"], CAMERA_NETWORK)

    def test_pulse_generator(self):
        values, n, warnings = extract(
            "003-diagnostic-pulse-generator", "screenshot0.png",
            [{"name": "button", "direction": "input", "class": "binary"},
             {"name": "pulse", "direction": "output", "class": "binary"}])
        self.assertEqual(n, 60)
        self.assertEqual(values["button"], PULSE_BUTTON)
        self.assertEqual(values["pulse"], PULSE_PULSE)
        # input is brighter than output: lint must stay silent
        self.assertEqual(warnings, [])

    def test_direction_lint_fires_when_swapped(self):
        _, _, warnings = extract(
            "003-diagnostic-pulse-generator", "screenshot0.png",
            [{"name": "button", "direction": "output", "class": "binary"},
             {"name": "pulse", "direction": "input", "class": "binary"}])
        self.assertTrue(any("brightness lint" in w for w in warnings))


if __name__ == "__main__":
    unittest.main()
