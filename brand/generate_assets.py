"""Render every icon and logo file both apps need from the chosen mark."""
import os, sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_logo import (concept_a, SS, NAVY, GOLD, GOLD_LIGHT, CREAM,
                       FONT_B, FONT_L, tracked)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MARK = concept_a          # the chosen direction: badge

def mark(size):
    return MARK(size)

def square_icon(size, *, inset=0.92, radius=None, bg=NAVY):
    """The badge centred on a solid tile — what launchers and stores want."""
    S = size * SS
    img = Image.new("RGB", (S, S), bg)
    if radius:
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(img).rounded_rectangle([0, 0, S, S],
                                             radius=int(S * radius), fill=bg)
    m = mark(int(S * inset))
    img.paste(m, ((S - m.width) // 2, (S - m.height) // 2), m)
    return img.resize((size, size), Image.LANCZOS)

def wordmark(width=1600, height=None, transparent=True):
    """Mark + NILESKY lockup, stacked, for splash and login screens."""
    W = width * 2
    H = (height or int(width * 0.42)) * 2
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0) if transparent else NAVY + (255,))
    d = ImageDraw.Draw(img)
    m = mark(int(H * 0.52))
    img.paste(m, ((W - m.width) // 2, int(H * 0.04)), m)

    f1 = ImageFont.truetype(FONT_B, int(H * 0.19))
    track = H * 0.010
    w = sum(d.textlength(c, font=f1) + track for c in "NILESKY") - track
    x = (W - w) / 2
    y = int(H * 0.60)
    x = tracked(d, "NILE", f1, x, y, CREAM, track)
    tracked(d, "SKY", f1, x, y, GOLD, track)

    tag = "LUXOR  ·  HOT AIR BALLOONS"
    f2 = ImageFont.truetype(FONT_L, int(H * 0.062))
    t2 = H * 0.030
    w2 = sum(d.textlength(c, font=f2) + t2 for c in tag) - t2
    tracked(d, tag, f2, (W - w2) / 2, int(H * 0.855), GOLD, t2)
    return img.resize((W // 2, H // 2), Image.LANCZOS)

def save(img, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("  ", os.path.relpath(path, ROOT))

written = []
for app in ("customer_app", "admin_panel"):
    print(app)
    save(mark(1024), app, "assets", "images", "logo.png")
    save(wordmark(1200), app, "assets", "images", "logo_wordmark.png")

    # Android launcher
    for folder, px in [("mipmap-mdpi", 48), ("mipmap-hdpi", 72),
                       ("mipmap-xhdpi", 96), ("mipmap-xxhdpi", 144),
                       ("mipmap-xxxhdpi", 192)]:
        save(square_icon(px), app, "android", "app", "src", "main", "res",
             folder, "ic_launcher.png")

    # web
    save(square_icon(192, radius=0.20), app, "web", "icons", "Icon-192.png")
    save(square_icon(512, radius=0.20), app, "web", "icons", "Icon-512.png")
    save(square_icon(192, inset=0.72), app, "web", "icons", "Icon-maskable-192.png")
    save(square_icon(512, inset=0.72), app, "web", "icons", "Icon-maskable-512.png")
    save(square_icon(64, radius=0.20), app, "web", "favicon.png")

# iOS — every size Contents.json lists, opaque, square (iOS applies the mask)
ios = os.path.join(ROOT, "customer_app", "ios", "Runner",
                   "Assets.xcassets", "AppIcon.appiconset")
if os.path.isdir(ios):
    print("customer_app/ios")
    for name in sorted(os.listdir(ios)):
        if not name.endswith(".png"):
            continue
        px = Image.open(os.path.join(ios, name)).size[0]
        square_icon(px).save(os.path.join(ios, name))
    print("   %d iOS icons" % len([n for n in os.listdir(ios) if n.endswith('.png')]))

# macOS
mac = os.path.join(ROOT, "customer_app", "macos", "Runner",
                   "Assets.xcassets", "AppIcon.appiconset")
if os.path.isdir(mac):
    print("customer_app/macos")
    for name in sorted(os.listdir(mac)):
        if name.endswith(".png"):
            px = Image.open(os.path.join(mac, name)).size[0]
            square_icon(px).save(os.path.join(mac, name))
    print("   done")

# Windows desktop icon for the admin panel
for app in ("admin_panel", "customer_app"):
    ico_dir = os.path.join(ROOT, app, "windows", "runner", "resources")
    if os.path.isdir(ico_dir):
        sizes = [16, 24, 32, 48, 64, 128, 256]
        base = square_icon(256, radius=0.18).convert("RGBA")
        base.save(os.path.join(ico_dir, "app_icon.ico"),
                  sizes=[(s, s) for s in sizes])
        print(app, "-> windows/runner/resources/app_icon.ico")

# a preview of the final pack
prev = Image.new("RGB", (1240, 560), (8, 14, 24))
pd = ImageDraw.Draw(prev)
pd.text((40, 26), "NileSky — final brand pack",
        font=ImageFont.truetype(FONT_B, 32), fill=CREAM)
wm = wordmark(700)
prev.paste(wm, (40, 90), wm)
x = 800
for px in (160, 96, 64, 44):
    ic = square_icon(px, radius=0.20)
    prev.paste(ic, (x, 120), ic)
    x += px + 16
pd.text((800, 92), "app icon", font=ImageFont.truetype(FONT_L, 22), fill=GOLD)
pd.text((800, 330), "on light backgrounds", font=ImageFont.truetype(FONT_L, 22), fill=GOLD)
light = Image.new("RGB", (400, 170), (245, 238, 224))
m = mark(130)
light.paste(m, (24, 20), m)
prev.paste(light, (800, 360))
prev.save(os.path.join(os.path.dirname(__file__), "final_pack.png"))
print("preview -> brand/final_pack.png")
