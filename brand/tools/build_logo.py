"""Generator logo RIVORA. Semua bentuk dihitung jadi path murni (tanpa clipPath/mask)."""
import math, os, sys
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

MALAM, ARUS, BENING, EMBUN, KABUT, PUTIH = "#0B1F2A", "#0B6E79", "#5FC3CF", "#D3ECEE", "#F3F6F5", "#FFFFFF"
f = lambda v: f"{v:.2f}".rstrip("0").rstrip(".")

# ---------- MARK (viewBox 0 0 120 84) ----------
ALMOND = "M4 42C21 13 43 4 60 4S99 13 116 42C99 71 77 80 60 80S21 71 4 42Z"
CX, CY, R_IRIS = 60, 42, 25
GLINT = "M50.5 21.5c0 0-4.8 5.4-4.8 8.6a4.8 4.8 0 0 0 9.6 0c0-3.2-4.8-8.6-4.8-8.6Z"

OFFSET = 0.0
def wave_y(x):  # garis muka air: puncak kiri, lembah kanan
    return 44.5 + OFFSET - 3.8 * math.sin(2 * math.pi * (x - 32.5) / 50)

def circle_hit(r, side):
    # cari x di mana gelombang memotong lingkaran iris radius r
    g = lambda x: (x - CX) ** 2 + (wave_y(x) - CY) ** 2 - r * r
    a, b = (CX - r - 1, CX) if side < 0 else (CX, CX + r + 1)
    if side < 0:
        a, b = b, a
    for _ in range(80):
        m = (a + b) / 2
        if (g(m) < 0) == (g(a) < 0):
            a = m
        else:
            b = m
    return (a + b) / 2

def water_path(r, offset=0.0, top=False):
    global OFFSET
    OFFSET = offset
    try:
        return _water_path(r, top)
    finally:
        OFFSET = 0.0

def _water_path(r, top):
    xl, xr = circle_hit(r, -1), circle_hit(r, +1)
    n = 10
    pts = [(xl + (xr - xl) * i / n, wave_y(xl + (xr - xl) * i / n)) for i in range(n + 1)]
    # Catmull-Rom -> Bezier
    d = f"M{f(pts[0][0])} {f(pts[0][1])}"
    ext = [(2 * pts[0][0] - pts[1][0], 2 * pts[0][1] - pts[1][1])] + pts + [(2 * pts[-1][0] - pts[-2][0], 2 * pts[-1][1] - pts[-2][1])]
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f"C{f(c1[0])} {f(c1[1])} {f(c2[0])} {f(c2[1])} {f(p2[0])} {f(p2[1])}"
    # busur bawah iris dari kanan kembali ke kiri (searah jarum jam di layar)
    a_r = math.atan2(wave_y(xr) - CY, xr - CX)
    a_l = math.atan2(wave_y(xl) - CY, xl - CX)
    span = (a_l - a_r) % (2 * math.pi)
    if top:  # busur atas: kanan -> kiri berlawanan jarum jam
        span = 2 * math.pi - span
    large = 1 if span > math.pi else 0
    d += f"A{r} {r} 0 {large} {0 if top else 1} {f(pts[0][0])} {f(pts[0][1])}Z"
    return d

WATER = water_path(R_IRIS)
R_MONO = R_IRIS - 4
GAP = 1.9
MONO_TOP = water_path(R_MONO, -GAP, top=True)
MONO_WATER = water_path(R_MONO, +GAP)
def circ(r):
    return f"M{f(CX - r)} {CY}a{r} {r} 0 1 0 {2*r} 0a{r} {r} 0 1 0 {-2*r} 0Z"

def mark_layers(almond=MALAM, iris=ARUS, water=BENING, glint=PUTIH):
    return (f'<path fill="{almond}" d="{ALMOND}"/>'
            f'<circle fill="{iris}" cx="{CX}" cy="{CY}" r="{R_IRIS}"/>'
            f'<path fill="{water}" d="{WATER}"/>'
            f'<path fill="{glint}" d="{GLINT}"/>')

def mark_mono(color):
    # almond berlubang iris, iris dibelah celah garis air, kilau tetes jadi lubang
    return (f'<path fill="{color}" fill-rule="evenodd" d="{ALMOND}{circ(R_IRIS)}"/>'
            f'<path fill="{color}" fill-rule="evenodd" d="{MONO_TOP}{GLINT}"/>'
            f'<path fill="{color}" d="{MONO_WATER}"/>')

# ---------- WORDMARK (cap 0..100, stroke 17) ----------
def stroke_quad(p, q, w, y0=0.0, y1=100.0):
    """Parallelogram sepanjang garis p->q tebal w, dipotong datar di y0/y1."""
    (x1, y1_), (x2, y2) = p, q
    dx, dy = x2 - x1, y2 - y1_
    L = math.hypot(dx, dy)
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    def at_y(px, py, y):
        t = (y - py) / dy
        return px + dx * t
    edges = [(x1 + nx, y1_ + ny), (x1 - nx, y1_ - ny)]
    ya, yb = max(min(y1_, y2), y0), min(max(y1_, y2), y1)
    out = []
    for (ex, ey), y in [(edges[0], ya), (edges[0], yb), (edges[1], yb), (edges[1], ya)]:
        out.append((at_y(ex, ey, y), y))
    return "M" + "L".join(f"{f(x)} {f(y)}" for x, y in out) + "Z"

def rect(x, y, w, h):
    return f"M{f(x)} {f(y)}h{f(w)}v{f(h)}h{f(-w)}Z"

def letter_R(ox):
    bowl = (f"M{ox} 0H{ox+34}A31 31 0 0 1 {ox+34} 62H{ox}Z"
            f"M{ox+17} 17H{ox+34}A14 14 0 0 1 {ox+34} 45H{ox+17}Z")
    return [(bowl, True), (rect(ox, 0, 17, 100), False),
            (stroke_quad((ox + 30, 50), (ox + 64, 108), 17, 46, 100), False)]

def letter_I(ox):
    return [(rect(ox, 0, 17, 100), False)]

def letter_V(ox):
    return [(stroke_quad((ox + 6, -12), (ox + 38, 108), 17), False),
            (stroke_quad((ox + 70, -12), (ox + 38, 108), 17), False)]

def letter_A(ox):
    return [(stroke_quad((ox + 6, 112), (ox + 38, -8), 17), False),
            (stroke_quad((ox + 70, 112), (ox + 38, -8), 17), False),
            (rect(ox + 18, 62, 40, 14), False)]

def letter_O(ox):
    c = ox + 50.5
    return [(f"M{f(c-50.5)} 50a50.5 50.5 0 1 0 101 0a50.5 50.5 0 1 0 -101 0Z"
             f"M{f(c-33.5)} 50a33.5 33.5 0 1 0 67 0a33.5 33.5 0 1 0 -67 0Z", True)]

LETTERS = letter_R(0) + letter_I(91) + letter_V(126) + letter_O(220) + letter_R(341) + letter_A(422)
WM_W, WM_VB = 498, "0 -1 498 102"

def wordmark_paths(color):
    return "".join(f'<path fill="{color}"{" fill-rule=\"evenodd\"" if eo else ""} d="{d}"/>' for d, eo in LETTERS)

def svg(vb, body, title="RIVORA"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" role="img" aria-label="{title}">'
            f'<title>{title}</title>{body}</svg>\n')

def write(name, content):
    with open(os.path.join(OUT, name), "w") as fh:
        fh.write(content)

# Mark
write("rivora-mark.svg", svg("0 0 120 84", mark_layers()))
write("rivora-mark-reverse.svg", svg("0 0 120 84", mark_layers(almond=KABUT)))
write("rivora-mark-mono-malam.svg", svg("0 0 120 84", mark_mono(MALAM)))
write("rivora-mark-mono-putih.svg", svg("0 0 120 84", mark_mono(PUTIH)))
# Wordmark
write("rivora-wordmark.svg", svg(WM_VB, wordmark_paths(MALAM)))
write("rivora-wordmark-putih.svg", svg(WM_VB, wordmark_paths(PUTIH)))

# Horizontal lockup: mark tinggi 112 (1,12 x cap), jarak 34
def lockup_h(mark_body, wm_color):
    s = 112 / 84
    mw = 120 * s
    gap = 36
    wm_y = (112 - 100) / 2
    body = (f'<g transform="scale({f(s)})">{mark_body}</g>'
            f'<g transform="translate({f(mw + gap)} {f(wm_y)})">{wordmark_paths(wm_color)}</g>')
    return svg(f"0 -1 {f(mw + gap + WM_W)} 114", body)
write("rivora-logo-horizontal.svg", lockup_h(mark_layers(), MALAM))
write("rivora-logo-horizontal-reverse.svg", lockup_h(mark_layers(almond=KABUT), PUTIH))
write("rivora-logo-horizontal-mono.svg", lockup_h(mark_mono(MALAM), MALAM))

# Stacked lockup
def lockup_v(mark_body, wm_color):
    W = WM_W
    s = 2.2
    mw, mh = 120 * s, 84 * s
    wm_s = 0.62
    body = (f'<g transform="translate({f((W - mw) / 2)} 0) scale({s})">{mark_body}</g>'
            f'<g transform="translate({f(W * (1 - wm_s) / 2)} {f(mh + 34)}) scale({wm_s})">{wordmark_paths(wm_color)}</g>')
    return svg(f"0 0 {W} {f(mh + 34 + 100 * wm_s + 2)}", body)
write("rivora-logo-stacked.svg", lockup_v(mark_layers(), MALAM))
write("rivora-logo-stacked-reverse.svg", lockup_v(mark_layers(almond=KABUT), PUTIH))

# App icon 1024 (rounded square, gradien Arus) + foreground/background terpisah untuk adaptive icon
GRAD = ('<defs><linearGradient id="rv-bg" x1="0" y1="0" x2="1" y2="1">'
        '<stop offset="0" stop-color="#11808C"/><stop offset="1" stop-color="#0A4E57"/></linearGradient></defs>')
def icon(radius):
    s = 640 / 120
    body = (GRAD + f'<rect width="1024" height="1024" rx="{radius}" fill="url(#rv-bg)"/>'
            f'<g transform="translate({f((1024 - 640) / 2)} {f((1024 - 84 * s) / 2)}) scale({f(s)})">{mark_layers()}</g>')
    return svg("0 0 1024 1024", body)
write("rivora-app-icon.svg", icon(228))
write("rivora-app-icon-square.svg", icon(0))
write("favicon.svg", svg("0 0 120 84", mark_layers()))

# ekspor data path untuk VectorDrawable
with open(os.path.join(OUT, "_paths.txt"), "w") as fh:
    fh.write(f"ALMOND={ALMOND}\nWATER={WATER}\nGLINT={GLINT}\nIRIS_HOLE={circ(R_IRIS)}\nMONO_TOP={MONO_TOP}\nMONO_WATER={MONO_WATER}\n")
print("ok", WATER)
