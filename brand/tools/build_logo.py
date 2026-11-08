"""Generator logo RIVORA "Ombak". Semua bentuk dihitung jadi path murni (tanpa clipPath/mask),
jadi aman di Flutter, Figma, Canva, PPT, dan Android VectorDrawable.

  python3 brand/tools/build_logo.py brand/logo                  # semua SVG
  python3 brand/tools/build_logo.py brand/logo --android RES    # + vector drawable launcher
  python3 brand/tools/build_logo.py brand/logo --dart           # cetak path untuk Flutter
"""
import math, os, sys

SAMUDRA, LAUT, TIRTA, BUIH, PUTIH = "#04214B", "#0361C3", "#35C1F4", "#DFF2FE", "#FFFFFF"
GRAD = ("#22B2F2", "#0347A8")  # gradien ikon aplikasi (kiri atas -> kanan bawah)


def f(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def P(p):
    return f"{f(p[0])} {f(p[1])}"


# ---------------------------------------------------------------- geometri dasar
def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def bez(s, t):
    a, b, c, d = s
    ab, bc, cd = lerp(a, b, t), lerp(b, c, t), lerp(c, d, t)
    return lerp(lerp(ab, bc, t), lerp(bc, cd, t), t)


def split(s, t):
    a, b, c, d = s
    ab, bc, cd = lerp(a, b, t), lerp(b, c, t), lerp(c, d, t)
    abc, bcd = lerp(ab, bc, t), lerp(bc, cd, t)
    m = lerp(abc, bcd, t)
    return (a, ab, abc, m), (m, bcd, cd, d)


def line_seg(a, b):
    return (a, lerp(a, b, 1 / 3), lerp(a, b, 2 / 3), b)


# ---------------------------------------------------------------- muka ombak (kotak 100)
# Garis muka air dari kiri ke kanan: naik jadi puncak, menggulung ke dalam (tabung),
# lalu dasar tabung keluar ke kanan. Air selalu di sisi kanan arah jalan garis.
START = (-5, 74)
CURVE = [
    ((12, 74), (22, 64), (28, 50)),          # muka ombak naik
    ((36, 32), (50, 22), (64, 24)),          # menuju puncak
    ((78, 26), (88, 38), (86, 52)),          # puncak turun di kanan
    ((85.5, 58.5), (81, 63.5), (75.5, 63.5)),  # bibir ombak
    ((71.5, 63.5), (70.3, 59), (72.8, 56.6)),  # ujung bibir membulat
    ((76.3, 53.3), (76, 47), (70, 44)),      # sisi dalam bibir
    ((62, 40), (50, 42), (48, 52)),          # atap-belakang tabung
    ((46, 62), (56, 71), (68, 71)),          # dasar tabung
    ((80, 71), (92, 69), (105, 67)),         # keluar ke kanan
]


def wave_segments(T=lambda p: p, extend=True):
    segs, p0 = [], START
    for c1, c2, p3 in CURVE:
        segs.append((p0, c1, c2, p3))
        p0 = p3
    if extend:  # perpanjang lurus supaya selalu menembus batas bentuk mana pun
        segs.insert(0, line_seg((-60, 74), START))
        segs.append(line_seg(p0, (p0[0] + 60, p0[1] - 60 * 2 / 13)))
    return [tuple(T(q) for q in s) for s in segs]


def crossings(segs, inside, n=600):
    out = []
    for i, s in enumerate(segs):
        prev = inside(*bez(s, 0))
        for k in range(1, n + 1):
            t = k / n
            cur = inside(*bez(s, t))
            if cur != prev:
                a, b = (k - 1) / n, t
                for _ in range(60):
                    m = (a + b) / 2
                    if inside(*bez(s, m)) == prev:
                        a = m
                    else:
                        b = m
                out.append((i, (a + b) / 2, cur))
            prev = cur
    return out


def sub_chain(segs, i0, t0, i1, t1):
    """Potongan rantai bezier dari (i0,t0) sampai (i1,t1)."""
    res = []
    for i in range(i0, i1 + 1):
        s = segs[i]
        a = t0 if i == i0 else 0.0
        b = t1 if i == i1 else 1.0
        if b < 1:
            s = split(s, b)[0]
            if a > 0:
                s = split(s, a / b)[1]
        elif a > 0:
            s = split(s, a)[1]
        res.append(s)
    return res


def chain_d(chain, move=True):
    d = f"M{P(chain[0][0])}" if move else ""
    for s in chain:
        d += f"C{P(s[1])} {P(s[2])} {P(s[3])}"
    return d


def clipped_surface(segs, inside):
    c = crossings(segs, inside)
    assert len(c) == 2 and c[0][2] and not c[1][2], c
    (i0, t0, _), (i1, t1, _) = c
    return sub_chain(segs, i0, t0, i1, t1)


# ---------------------------------------------------------------- simbol (lingkaran)
CX = CY = 50.0
R = 46.0


def in_circle(x, y):
    return (x - CX) ** 2 + (y - CY) ** 2 < R * R


def circle_d(cx=CX, cy=CY, r=R, cw=True):
    s = 1 if cw else 0
    return (f"M{f(cx + r)} {f(cy)}A{f(r)} {f(r)} 0 1 {s} {f(cx - r)} {f(cy)}"
            f"A{f(r)} {f(r)} 0 1 {s} {f(cx + r)} {f(cy)}Z")


def ang(p):
    return math.atan2(p[1] - CY, p[0] - CX)


def water_d():
    ch = clipped_surface(wave_segments(), in_circle)
    a, b = ch[-1][3], ch[0][0]  # keluar kanan -> masuk kiri, lewat bawah (searah jarum jam)
    sweep_ang = (ang(b) - ang(a)) % (2 * math.pi)
    large = 1 if sweep_ang > math.pi else 0
    return chain_d(ch) + f"A{f(R)} {f(R)} 0 {large} 1 {P(b)}Z"


# --- versi satu warna: langit dan air dipisah celah selebar GAP
GAP = 3.4


def sample_chain(segs, step=0.25):
    pts = []
    for s in segs:
        L = sum(math.dist(bez(s, k / 40), bez(s, (k + 1) / 40)) for k in range(40))
        n = max(4, int(L / step))
        for k in range(n):
            pts.append(bez(s, k / n))
    pts.append(segs[-1][3])
    return pts


def offset_pts(pts, g, win=6):
    out = []
    for i, p in enumerate(pts):
        a, b = pts[max(0, i - win)], pts[min(len(pts) - 1, i + win)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1
        out.append((p[0] + g * dy / L, p[1] - g * dx / L))  # normal kiri = sisi langit
    return out


def resample(pts, step):
    out, acc = [pts[0]], 0.0
    for a, b in zip(pts, pts[1:]):
        d = math.dist(a, b)
        acc += d
        if acc >= step:
            out.append(b)
            acc = 0.0
    if out[-1] != pts[-1]:
        out[-1] = pts[-1]
    return out


def catmull(pts):
    segs = []
    for i in range(len(pts) - 1):
        p0, p1, p2 = pts[max(0, i - 1)], pts[i], pts[i + 1]
        p3 = pts[min(len(pts) - 1, i + 2)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        segs.append((p1, c1, c2, p2))
    return segs


def sky_mono_d():
    pts = offset_pts(sample_chain(wave_segments()), GAP)
    ins = [in_circle(*p) for p in pts]
    i0 = ins.index(True)
    i1 = len(ins) - 1 - ins[::-1].index(True)
    seg = pts[i0:i1 + 1]
    # tempel titik potong tepat di lingkaran
    def to_circle(p):
        a = ang(p)
        return (CX + R * math.cos(a), CY + R * math.sin(a))
    seg = [to_circle(pts[i0 - 1])] + seg + [to_circle(pts[i1 + 1])]
    ch = catmull(resample(seg, 1.1))
    a, b = ch[-1][3], ch[0][0]  # kanan -> kiri lewat atas (berlawanan jarum jam)
    sweep_ang = (ang(a) - ang(b)) % (2 * math.pi)
    large = 1 if sweep_ang > math.pi else 0
    return chain_d(ch) + f"A{f(R)} {f(R)} 0 {large} 0 {P(b)}Z"


# ---------------------------------------------------------------- ikon aplikasi
RX = 22.3  # sudut kotak membulat (rasio sama dengan ikon 1024: 228 px)
ICON_T = lambda p: (p[0] * 1.12 - 6, p[1] * 1.12 + 8)  # ombak penuh di dalam ikon


def in_rrect(x, y, r=RX):
    if not (0 < x < 100 and 0 < y < 100):
        return False
    cx = min(max(x, r), 100 - r)
    cy = min(max(y, r), 100 - r)
    return (x - cx) ** 2 + (y - cy) ** 2 < r * r


def icon_wave_d(rounded=True):
    r = RX if rounded else 0.0
    ch = clipped_surface(wave_segments(ICON_T), lambda x, y: in_rrect(x, y, r) if r else 0 < x < 100 and 0 < y < 100)
    a, b = ch[-1][3], ch[0][0]
    d = chain_d(ch)
    if not r:
        return d + f"L100 100L0 100Z"
    # keluar di sisi kanan
    if a[1] < 100 - r:
        d += f"L100 {f(100 - r)}"
    d += f"A{f(r)} {f(r)} 0 0 1 {f(100 - r)} 100L{f(r)} 100"
    if b[1] < 100 - r:
        d += f"A{f(r)} {f(r)} 0 0 1 0 {f(100 - r)}Z"
    else:
        d += f"A{f(r)} {f(r)} 0 0 1 {P(b)}Z"
    return d


def rrect_d(r=RX):
    k = 100 - r
    return (f"M{f(r)} 0H{f(k)}A{f(r)} {f(r)} 0 0 1 100 {f(r)}V{f(k)}A{f(r)} {f(r)} 0 0 1 {f(k)} 100"
            f"H{f(r)}A{f(r)} {f(r)} 0 0 1 0 {f(k)}V{f(r)}A{f(r)} {f(r)} 0 0 1 {f(r)} 0Z")


def fg_wave_d(T):
    """Ombak untuk lapisan foreground adaptive icon (tanpa potong; launcher yang memotong)."""
    segs = wave_segments(T)
    a, b = segs[-1][3], segs[0][0]
    return chain_d(segs) + f"L{P((a[0], 200))}L{P((b[0], 200))}Z"


# ---------------------------------------------------------------- wordmark (garis membulat)
W = 18.0  # tebal garis, tinggi huruf 100
HW = W / 2


def area(poly):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1]))


def stadium(a, b, r=HW):
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(dx, dy)
    ux, uy = dx / L, dy / L
    n = (-uy, ux)
    poly = [(a[0] + n[0] * r, a[1] + n[1] * r), (b[0] + n[0] * r, b[1] + n[1] * r),
            (b[0] - n[0] * r, b[1] - n[1] * r), (a[0] - n[0] * r, a[1] - n[1] * r)]
    if area(poly) < 0:
        n = (-n[0], -n[1])
        poly = [(a[0] + n[0] * r, a[1] + n[1] * r), (b[0] + n[0] * r, b[1] + n[1] * r),
                (b[0] - n[0] * r, b[1] - n[1] * r), (a[0] - n[0] * r, a[1] - n[1] * r)]
    cross = n[0] * uy - n[1] * ux
    s = 1 if cross > 0 else 0
    s2 = 1 if (-n[0]) * (-uy) - (-n[1]) * (-ux) > 0 else 0
    rr = f(r)
    return (f"M{P(poly[0])}L{P(poly[1])}A{rr} {rr} 0 0 {s} {P(poly[2])}"
            f"L{P(poly[3])}A{rr} {rr} 0 0 {s2} {P(poly[0])}Z")


def half_ring(cx, cy, r):  # setengah cincin di kanan (mangkuk huruf R)
    o, i = r + HW, r - HW
    return (f"M{f(cx)} {f(cy - o)}A{f(o)} {f(o)} 0 0 1 {f(cx)} {f(cy + o)}"
            f"L{f(cx)} {f(cy + i)}A{f(i)} {f(i)} 0 0 0 {f(cx)} {f(cy - i)}Z")


def ring(cx, cy, r):
    return circle_d(cx, cy, r + HW, True) + circle_d(cx, cy, r - HW, False)


def glyph_R(x):
    t, b, mid = HW, 100 - HW, 51
    return [stadium((x + HW, t), (x + HW, b)), stadium((x + HW, t), (x + 38, t)),
            half_ring(x + 38, (t + mid) / 2, (mid - t) / 2), stadium((x + HW, mid), (x + 38, mid)),
            stadium((x + 33, mid), (x + 60, b))], 69


def glyph_I(x):
    return [stadium((x + HW, HW), (x + HW, 100 - HW))], 18


def glyph_V(x):
    return [stadium((x + HW, HW), (x + 40, 100 - HW)), stadium((x + 40, 100 - HW), (x + 71, HW))], 80


def glyph_O(x):
    return [ring(x + 51, 50, 42)], 102


def glyph_A(x):
    return [stadium((x + HW, 100 - HW), (x + 40, HW)), stadium((x + 40, HW), (x + 71, 100 - HW)),
            stadium((x + 21, 67), (x + 59, 67))], 80


def wordmark_d():
    parts, x = [], 0.0
    for g, adv in ((glyph_R, 15), (glyph_I, 13), (glyph_V, 6), (glyph_O, 12), (glyph_R, 6), (glyph_A, 0)):
        ps, w = g(x)
        parts += ps
        x += w + adv
    return "".join(parts), x  # lebar 470


# ---------------------------------------------------------------- tulis SVG
def svg(vb, body, title="RIVORA"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" role="img" aria-label="{title}">'
            f"<title>{title}</title>{body}</svg>\n")


def mark_body(variant="warna", T=None):
    g = f' transform="{T}"' if T else ""
    if variant == "warna":
        return f'<g{g}><path fill="{LAUT}" d="{circle_d()}"/><path fill="{TIRTA}" d="{water_d()}"/></g>'
    if variant == "reverse":
        return f'<g{g}><path fill="{PUTIH}" d="{circle_d()}"/><path fill="{LAUT}" d="{water_d()}"/></g>'
    col = SAMUDRA if variant == "mono" else PUTIH
    return f'<g{g} fill="{col}"><path d="{sky_mono_d()}"/><path d="{water_d()}"/></g>'


def build(out):
    os.makedirs(out, exist_ok=True)
    wm, ww = wordmark_d()
    w = lambda name, s: open(os.path.join(out, name), "w").write(s)

    # simbol
    for name, v in (("rivora-mark.svg", "warna"), ("rivora-mark-reverse.svg", "reverse"),
                    ("rivora-mark-mono.svg", "mono"), ("rivora-mark-mono-putih.svg", "mono-putih")):
        w(name, svg("0 0 100 100", mark_body(v)))
    w("favicon.svg", svg("0 0 100 100", mark_body("warna")))

    # wordmark
    w("rivora-wordmark.svg", svg(f"0 0 {f(ww)} 100", f'<path fill="{SAMUDRA}" d="{wm}"/>'))
    w("rivora-wordmark-putih.svg", svg(f"0 0 {f(ww)} 100", f'<path fill="{PUTIH}" d="{wm}"/>'))

    # logo horizontal: simbol 1,45x tinggi huruf, celah 34
    k, gap = 1.45, 34
    mx = -4 * k  # tepi kiri lingkaran di x=0
    my = 50 - 50 * k
    tx = 92 * k + gap
    top = my + 4 * k
    vb = f"0 {f(top)} {f(tx + ww)} {f(92 * k)}"
    for name, v, ink in (("rivora-logo-horizontal.svg", "warna", SAMUDRA),
                         ("rivora-logo-horizontal-reverse.svg", "warna", PUTIH),
                         ("rivora-logo-horizontal-mono.svg", "mono", SAMUDRA)):
        body = mark_body(v, f"translate({f(mx)} {f(my)}) scale({k})")
        body += f'<path fill="{ink}" transform="translate({f(tx)} 0)" d="{wm}"/>'
        w(name, svg(vb, body))

    # logo bertumpuk: simbol 1,9x di atas, celah 30
    k2, gap2 = 1.9, 30
    d2 = 92 * k2
    mx2 = (ww - d2) / 2 - 4 * k2
    my2 = -4 * k2
    ty = d2 + gap2
    vb2 = f"0 0 {f(ww)} {f(ty + 100)}"
    for name, ink in (("rivora-logo-stacked.svg", SAMUDRA), ("rivora-logo-stacked-reverse.svg", PUTIH)):
        body = mark_body("warna", f"translate({f(mx2)} {f(my2)}) scale({k2})")
        body += f'<path fill="{ink}" transform="translate(0 {f(ty)})" d="{wm}"/>'
        w(name, svg(vb2, body))

    # ikon aplikasi
    grad = (f'<defs><linearGradient id="rv-g" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{GRAD[0]}"/><stop offset="1" stop-color="{GRAD[1]}"/></linearGradient></defs>')
    w("rivora-app-icon.svg", svg("0 0 100 100", grad + f'<path fill="url(#rv-g)" d="{rrect_d()}"/>'
                                 f'<path fill="{PUTIH}" d="{icon_wave_d(True)}"/>'))
    w("rivora-app-icon-square.svg", svg("0 0 100 100", grad + '<path fill="url(#rv-g)" d="M0 0H100V100H0Z"/>'
                                        f'<path fill="{PUTIH}" d="{icon_wave_d(False)}"/>'))


# ---------------------------------------------------------------- Android adaptive icon
def android(res):
    # desain ikon 100 unit dipetakan ke 72 dp tengah dari kanvas 108 dp
    T = lambda p: ((p[0] * 1.12 - 6) * 0.72 + 18, (p[1] * 1.12 + 8) * 0.72 + 18)
    fg = fg_wave_d(T)
    head = ('<?xml version="1.0" encoding="utf-8"?>\n<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp" android:height="108dp"\n    android:viewportWidth="108" android:viewportHeight="108">\n')
    os.makedirs(os.path.join(res, "drawable"), exist_ok=True)
    open(os.path.join(res, "drawable", "ic_launcher_foreground.xml"), "w").write(
        head + f'    <!-- Logo RIVORA "Ombak" (brand/tools/build_logo.py) -->\n'
        f'    <path android:fillColor="#FFFFFFFF" android:pathData="{fg}" />\n</vector>\n')
    open(os.path.join(res, "drawable", "ic_launcher_monochrome.xml"), "w").write(
        head + f'    <!-- Ikon bertema Android 13+: launcher mewarnai ulang bentuk ini -->\n'
        f'    <path android:fillColor="#FFFFFFFF" android:pathData="{fg}" />\n</vector>\n')
    bg = ('<?xml version="1.0" encoding="utf-8"?>\n<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
          '    xmlns:aapt="http://schemas.android.com/aapt"\n'
          '    android:width="108dp" android:height="108dp"\n    android:viewportWidth="108" android:viewportHeight="108">\n'
          '    <!-- Gradien ikon RIVORA: biru muda ke biru laut -->\n'
          '    <path android:pathData="M0,0h108v108h-108z">\n        <aapt:attr name="android:fillColor">\n'
          '            <gradient android:type="linear"\n'
          '                android:startX="0" android:startY="0" android:endX="108" android:endY="108">\n'
          f'                <item android:offset="0" android:color="#FF{GRAD[0][1:]}" />\n'
          f'                <item android:offset="1" android:color="#FF{GRAD[1][1:]}" />\n'
          '            </gradient>\n        </aapt:attr>\n    </path>\n</vector>\n')
    open(os.path.join(res, "drawable", "ic_launcher_background.xml"), "w").write(bg)


# ---------------------------------------------------------------- Flutter
def dart_path(d_chain, name):
    """Cetak perintah Path Dart dari rantai bezier."""
    lines = [f"    final {name} = Path()", f"      ..moveTo({f(d_chain[0][0][0])}, {f(d_chain[0][0][1])})"]
    for s in d_chain:
        lines.append(f"      ..cubicTo({f(s[1][0])}, {f(s[1][1])}, {f(s[2][0])}, {f(s[2][1])}, {f(s[3][0])}, {f(s[3][1])})")
    return "\n".join(lines)


if __name__ == "__main__":
    build(sys.argv[1])
    if "--android" in sys.argv:
        android(sys.argv[sys.argv.index("--android") + 1])
    if "--dart" in sys.argv:
        ch = clipped_surface(wave_segments(), in_circle)
        print("// simbol (kotak 100): air dalam lingkaran, tutup dengan arcToPoint ke titik awal")
        print(dart_path(ch, "air"))
        print("// ombak (kotak 100, belum ditransformasi), perpanjangan lurus kiri-kanan")
        print(dart_path(wave_segments(), "ombak"))
