"""Trace following: time-unit grid fit and per-unit value sampling."""

from panel import PanelError, band_columns


class TraceError(PanelError):
    pass


def find_edges(cols, band_h):
    """X centers of vertical waveform edges (orange spans most of the band)."""
    xs = sorted(x for x, (ymin, ymax, _) in cols.items()
                if ymax - ymin > 0.6 * band_h)
    groups = []
    for x in xs:
        if groups and x <= groups[-1][-1] + 2:
            groups[-1][-1] = x
        else:
            groups.append([x, x])
    return [(a + b) // 2 for a, b in groups]


def fit_grid(all_edges, trace_x0):
    """Fit (time0, unit_width) from pooled edge positions.

    Edges land on time-unit boundaries; the smallest edge spacing family is
    the unit width, refined by least squares over integer unit indices, then
    the origin is snapped to the unit boundary nearest the trace start.
    """
    edges = sorted(set(all_edges))
    diffs = [b - a for a, b in zip(edges, edges[1:]) if 8 <= b - a <= 400]
    if not diffs:
        raise TraceError("cannot fit time grid: fewer than two waveform edges")
    d_min = min(diffs)
    base = [d for d in diffs if d <= d_min + 3]
    u = sum(base) / len(base)
    u = sum(diffs) / sum(round(d / u) for d in diffs)

    ref = edges[0]
    ks = [round((e - ref) / u) for e in edges]
    n = len(edges)
    mean_k = sum(ks) / n
    mean_e = sum(edges) / n
    var = sum((k - mean_k) ** 2 for k in ks)
    if var > 0:
        u = sum((k - mean_k) * (e - mean_e) for k, e in zip(ks, edges)) / var
        ref = mean_e - u * mean_k
    if not 8 <= u <= 400:
        raise TraceError(f"implausible time-unit width {u:.2f}px")

    time0 = ref - round((ref - trace_x0) / u) * u
    return time0, u


def sample_band(im, y0, y1, time0, unit, n_units, klass):
    """One value per time unit for a band: binary -> 0/100, analog -> 0..100."""
    cols = band_columns(im, y0, y1)
    band_h = y1 - y0
    mid = (y0 + y1) / 2
    values = []
    for k in range(n_units):
        xc = time0 + (k + 0.5) * unit
        centers = []
        for x in (round(xc) - 1, round(xc), round(xc) + 1):
            if x in cols:
                ymin, ymax, _ = cols[x]
                if ymax - ymin <= 0.6 * band_h:  # skip edge columns
                    centers.append((ymin + ymax) / 2)
        if not centers:
            raise TraceError(f"no trace pixels at time unit {k} (x~{xc:.0f})")
        y = sorted(centers)[len(centers) // 2]
        if klass == "binary":
            values.append(100 if y < mid else 0)
        else:  # analog: linear map of height, band top = 100, bottom = 0
            v = (y1 - 1 - y) / (band_h - 2) * 100
            values.append(max(0, min(100, round(v))))
    return values


def band_brightness(cols):
    vals = [b for (_, _, b) in cols.values()]
    return sum(vals) / len(vals) if vals else 0.0


def extract_traces(im, bands, trace_defs):
    """Extract per-unit values for every band. Returns (results, n_units, warnings).

    results: list of dicts {name, direction, class, values} in band order.
    """
    if len(bands) != len(trace_defs):
        raise TraceError(
            f"panel has {len(bands)} trace bands but mapping config defines "
            f"{len(trace_defs)} traces")

    per_band = []
    all_edges = []
    x0 = None
    x1 = None
    for (y0, y1), tdef in zip(bands, trace_defs):
        cols = band_columns(im, y0, y1)
        if not cols:
            raise TraceError(f"band y{y0}-{y1} has no trace pixels")
        per_band.append((cols, y0, y1, tdef))
        all_edges.extend(find_edges(cols, y1 - y0))
        # contiguous extent: the waveform is a connected polyline, so a gap
        # of more than a few px means stray pixels (panel border bits), not data
        xs = sorted(cols)
        lo = xs[0]
        hi = lo
        for x in xs[1:]:
            if x - hi > 6:
                break
            hi = x
        x0 = lo if x0 is None else min(x0, lo)
        x1 = hi if x1 is None else min(x1, hi)

    time0, unit = fit_grid(all_edges, x0)
    n_units = int((x1 + 1 - time0) / unit)
    if n_units < 2:
        raise TraceError("fewer than two full time units visible")

    warnings = []
    brightness = [(band_brightness(cols), tdef) for cols, _, _, tdef in per_band]
    dimmest_input = min((b for b, t in brightness if t["direction"] == "input"),
                        default=None)
    brightest_output = max((b for b, t in brightness if t["direction"] == "output"),
                           default=None)
    if (dimmest_input is not None and brightest_output is not None
            and dimmest_input < brightest_output + 10):
        warnings.append(
            "brightness lint: input traces are not clearly brighter than "
            f"outputs (input {dimmest_input:.0f} vs output {brightest_output:.0f}); "
            "check trace directions in the mapping config")

    results = []
    for cols, y0, y1, tdef in per_band:
        if tdef["class"] == "xbus":
            results.append(dict(tdef, values=None))
            warnings.append(f"trace '{tdef['name']}': xbus not extracted (out of scope)")
            continue
        values = sample_band(im, y0, y1, time0, unit, n_units, tdef["class"])
        results.append(dict(tdef, values=values))
    return results, n_units, warnings
