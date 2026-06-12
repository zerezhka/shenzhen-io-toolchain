"""Verification-panel location and trace-band detection.

Operates on the uniform 1920x1080 shiawasenahikari screenshots: the
verification panel sits in the bottom third, waveforms are orange polylines
over a dark checkered grid, one horizontal band per signal.
"""

from collections import Counter


def is_orange(r, g, b):
    return r > 100 and r > g * 1.4 and g > b * 1.2 and g > 40


class PanelError(Exception):
    """Layout/detection failure — the screenshot cannot be extracted."""


def find_bands(im, min_height=15, min_columns=80):
    """Return trace bands as (y0, y1) tuples, top to bottom.

    A band is a contiguous run of rows in the bottom third of the image with
    a wide spread of orange pixels. Board chips, buttons, and scrollbars also
    contain orange but never span enough distinct columns to qualify.
    """
    w, h = im.size
    px = im.load()
    y_start = int(h * 0.66)
    row_cols = {}
    for y in range(y_start, h):
        cols = [x for x in range(200, w - 10) if is_orange(*px[x, y][:3])]
        if len(cols) >= 4:
            row_cols[y] = cols

    bands, run = [], None
    for y in range(y_start, h + 1):
        if y in row_cols:
            run = [run[0], y] if run else [y, y]
        elif run:
            bands.append(tuple(run))
            run = None

    result = []
    for y0, y1 in bands:
        if y1 - y0 + 1 < min_height:
            continue
        distinct = set()
        for y in range(y0, y1 + 1):
            distinct.update(row_cols.get(y, ()))
        if len(distinct) >= min_columns:
            result.append((y0, y1))
    return result


def band_columns(im, y0, y1):
    """Per-column orange extent within a band: {x: (ymin, ymax, brightness)}.

    Columns belonging to the panel's right border (orange runs continuing
    outside the band) are excluded so the border is never read as an edge.
    """
    w, h = im.size
    px = im.load()
    cols = {}
    for x in range(200, w - 5):
        ys, bright = [], []
        for y in range(y0, y1 + 1):
            r, g, b = px[x, y][:3]
            if is_orange(r, g, b):
                ys.append(y)
                bright.append(r + g + b)
        if not ys:
            continue
        # border test: orange continues well above/below the band at this x
        outside = 0
        for y in (y0 - 6, y0 - 9, y1 + 6, y1 + 9):
            if 0 <= y < h and is_orange(*px[x, y][:3]):
                outside += 1
        if outside >= 2:
            continue
        cols[x] = (min(ys), max(ys), sum(bright) / len(bright))
    return cols
