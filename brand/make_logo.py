"""NileSky brand mark generator — original artwork, drawn from scratch with PIL."""
import math, os
from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersampling factor
FONT_B = "/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf"
FONT_M = "/usr/share/fonts/truetype/google-fonts/Poppins-Medium.ttf"
FONT_L = "/usr/share/fonts/truetype/google-fonts/Poppins-Light.ttf"

GOLD       = (212, 168,  67)
GOLD_LIGHT = (240, 201, 106)
GOLD_DEEP  = (176, 130,  38)
NAVY       = ( 12,  22,  38)
NAVY_SOFT  = ( 22,  36,  58)
CREAM      = (245, 238, 224)
NILE       = ( 58, 140, 150)
WHITE      = (255, 255, 255)

# ---------------------------------------------------------------- balloon shape
# The envelope is a circular dome that tapers into the neck: a real balloon is
# about as wide as it is tall, with its widest point just under halfway down.
SHOULDER = 0.46   # where the envelope is widest
NECK     = 0.19   # half-width left at the very bottom

def half_width(t):
    """Half-width fraction (0..1) at vertical fraction t in [0,1]."""
    t = min(max(t, 0.0), 1.0)
    if t <= SHOULDER:
        k = (SHOULDER - t) / SHOULDER
        return math.sqrt(max(0.0, 1.0 - k * k))
    s = (t - SHOULDER) / (1.0 - SHOULDER)
    return NECK + (1.0 - NECK) * math.cos(s * math.pi / 2) ** 0.78

def envelope_points(cx, top, w, h, steps=220):
    """Closed outline of the balloon envelope."""
    right, left = [], []
    for i in range(steps + 1):
        t = i / steps
        hw = half_width(t) * w / 2
        y = top + t * h
        right.append((cx + hw, y))
        left.append((cx - hw, y))
    return right + left[::-1]

def gore(cx, top, w, h, k, steps=160):
    """A seam line running down the envelope at horizontal fraction k (-1..1)."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        hw = half_width(t) * w / 2
        pts.append((cx + k * hw, top + t * h))
    return pts

def draw_balloon(d, cx, top, w, h, *, bands, outline=None, lw=0):
    """Envelope filled with alternating vertical gore bands."""
    edges = [-1.0, -0.62, -0.28, 0.0, 0.28, 0.62, 1.0]
    for i in range(len(edges) - 1):
        a, b = edges[i], edges[i + 1]
        left = gore(cx, top, w, h, a)
        right = gore(cx, top, w, h, b)
        d.polygon(left + right[::-1], fill=bands[i % len(bands)])
    if outline and lw:
        d.line(envelope_points(cx, top, w, h) + [envelope_points(cx, top, w, h)[0]],
               fill=outline, width=lw, joint="curve")

def draw_basket(d, cx, y, w, h, color, rope_color, rope_w, neck_y, neck_hw):
    """Ropes from the envelope neck plus a tapered basket."""
    for sx in (-1, 1):
        d.line([(cx + sx * neck_hw * 0.75, neck_y), (cx + sx * w / 2, y)],
               fill=rope_color, width=rope_w)
    d.polygon([(cx - w / 2, y), (cx + w / 2, y),
               (cx + w / 2 * 0.78, y + h), (cx - w / 2 * 0.78, y + h)], fill=color)

def wave(d, cx, y, width, amp, color, lw, phase=0.0):
    pts = []
    for i in range(161):
        t = i / 160
        x = cx - width / 2 + t * width
        pts.append((x, y + math.sin(t * math.pi * 2 + phase) * amp))
    d.line(pts, fill=color, width=lw, joint="curve")

# ------------------------------------------------------------------- concepts
def concept_a(size):
    """Badge: a gold ring, a gored balloon, the Nile running underneath."""
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r, c = S * 0.47, S / 2
    d.ellipse([c - r, c - r, c + r, c + r], fill=NAVY)
    d.ellipse([c - r, c - r, c + r, c + r], outline=GOLD, width=int(S * 0.020))

    bw, bh = S * 0.46, S * 0.46
    top = S * 0.155
    draw_balloon(d, c, top, bw, bh, bands=[GOLD_DEEP, GOLD, GOLD_LIGHT])
    neck_y = top + bh
    neck_hw = half_width(1.0) * bw / 2
    draw_basket(d, c, neck_y + S * 0.045, S * 0.085, S * 0.048,
                CREAM, GOLD_LIGHT, int(S * 0.008), neck_y, neck_hw)

    for i, (dy, alpha, amp) in enumerate([(0.0, 255, 0.015), (0.050, 150, 0.012)]):
        wave(d, c, S * (0.755 + dy), S * 0.50, S * amp,
             NILE + (alpha,), int(S * 0.017), phase=i * 1.1)
    return img.resize((size, size), Image.LANCZOS)

def concept_b(size):
    """Sunrise: the balloon lifting out of a Luxor sun, over the river."""
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    sun_c = S * 0.560
    sun_r = S * 0.300

    # the sun sits behind everything
    d.ellipse([c - sun_r, sun_c - sun_r, c + sun_r, sun_c + sun_r], fill=GOLD_DEEP)
    for i in range(13):
        a = math.pi + i * math.pi / 12
        d.line([(c + math.cos(a) * sun_r * 1.16, sun_c + math.sin(a) * sun_r * 1.16),
                (c + math.cos(a) * sun_r * 1.38, sun_c + math.sin(a) * sun_r * 1.38)],
               fill=GOLD + (200,), width=int(S * 0.015))

    bw, bh = S * 0.42, S * 0.42
    top = S * 0.105
    draw_balloon(d, c, top, bw, bh, bands=[CREAM, GOLD_LIGHT, GOLD])
    d.line(envelope_points(c, top, bw, bh)[:1] +
           envelope_points(c, top, bw, bh), fill=NAVY, width=int(S * 0.012),
           joint="curve")
    neck_y = top + bh
    draw_basket(d, c, neck_y + S * 0.048, S * 0.085, S * 0.048,
                NAVY, NAVY, int(S * 0.009), neck_y, half_width(1.0) * bw / 2)

    for i, (dy, alpha) in enumerate([(0.0, 255), (0.055, 140)]):
        wave(d, c, S * (0.815 + dy), S * 0.66, S * 0.016,
             NILE + (alpha,), int(S * 0.019), phase=i * 1.1)
    return img.resize((size, size), Image.LANCZOS)

def concept_c(size):
    """Rounded tile: a clean single-colour balloon and two lines of river."""
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, S, S], radius=int(S * 0.23), fill=NAVY)

    c = S / 2
    bw, bh = S * 0.50, S * 0.50
    top = S * 0.145
    draw_balloon(d, c, top, bw, bh,
                 bands=[GOLD_DEEP, GOLD, GOLD_LIGHT, GOLD_LIGHT, GOLD, GOLD_DEEP])
    neck_y = top + bh
    draw_basket(d, c, neck_y + S * 0.048, S * 0.09, S * 0.05,
                CREAM, GOLD_LIGHT, int(S * 0.008), neck_y, half_width(1.0) * bw / 2)
    wave(d, c, S * 0.845, S * 0.60, S * 0.016, NILE, int(S * 0.019))
    wave(d, c, S * 0.900, S * 0.60, S * 0.013, NILE + (140,), int(S * 0.016), phase=1.1)
    return img.resize((size, size), Image.LANCZOS)

CONCEPTS = {"a": concept_a, "b": concept_b, "c": concept_c}

# ------------------------------------------------------------------- wordmark
def tracked(d, text, font, x, y, fill, tracking):
    for ch in text:
        d.text((x, y), ch, font=font, fill=fill)
        x += d.textlength(ch, font=font) + tracking
    return x

def lockup(mark, width=1200, dark=True):
    h = int(width * 0.30)
    bg = NAVY if dark else CREAM
    img = Image.new("RGB", (width, h), bg)
    d = ImageDraw.Draw(img)
    m = mark(int(h * 0.80))
    img.paste(m, (int(h * 0.16), int(h * 0.10)), m)

    x = int(h * 0.16) + m.width + int(h * 0.20)
    f1 = ImageFont.truetype(FONT_B, int(h * 0.31))
    fg = CREAM if dark else NAVY
    end = tracked(d, "NILE", f1, x, int(h * 0.22), fg, h * 0.010)
    tracked(d, "SKY", f1, end, int(h * 0.22), GOLD, h * 0.010)

    tag, room = "LUXOR  ·  HOT AIR BALLOONS", width - x - int(h * 0.16)
    size, track = int(h * 0.115), h * 0.026
    while size > 8:
        f2 = ImageFont.truetype(FONT_L, size)
        w = sum(d.textlength(ch, font=f2) + track for ch in tag) - track
        if w <= room:
            break
        size -= 1
        track = size * 0.22
    tracked(d, tag, f2, x + 2, int(h * 0.64), GOLD if dark else GOLD_DEEP, track)
    return img

if __name__ == "__main__":
    out = os.path.dirname(os.path.abspath(__file__))
    sheet_w = 1240
    rows = []
    for key in ("a", "b", "c"):
        rows.append(lockup(CONCEPTS[key], sheet_w - 80, dark=True))
    gap, pad, label = 26, 40, 46
    H = pad * 2 + sum(r.height for r in rows) + gap * 2 + label * 3 + 70 + 120
    sheet = Image.new("RGB", (sheet_w, H), (8, 14, 24))
    sd = ImageDraw.Draw(sheet)
    ft = ImageFont.truetype(FONT_M, 26)
    fh = ImageFont.truetype(FONT_B, 34)
    sd.text((pad, 24), "NileSky — three logo directions", font=fh, fill=CREAM)
    y = 78
    names = {"a": "1 — Badge  ·  balloon + the Nile inside a gold ring",
             "b": "2 — Sunrise  ·  balloon lifting off a Luxor sun",
             "c": "3 — Tile  ·  the plainest mark, best for an app icon"}
    for key, r in zip(("a", "b", "c"), rows):
        sd.text((pad, y), names[key], font=ft, fill=GOLD)
        y += label
        sheet.paste(r, (pad, y))
        y += r.height + gap
    # how each mark holds up at real icon sizes
    sd.text((pad, y + 6), "at app-icon size", font=ft, fill=GOLD)
    x = pad + 260
    for key in ("a", "b", "c"):
        for px in (96, 64, 44):
            tile = Image.new("RGB", (px, px), (8, 14, 24))
            mk = CONCEPTS[key](px)
            tile.paste(mk, (0, 0), mk)
            sheet.paste(tile, (x, y + 6))
            x += px + 14
        x += 34
    sheet.save(os.path.join(out, "concepts.png"))
    for key in CONCEPTS:
        CONCEPTS[key](512).save(os.path.join(out, f"mark_{key}.png"))
    print("written:", os.listdir(out))
