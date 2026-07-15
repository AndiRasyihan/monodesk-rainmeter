# -*- coding: utf-8 -*-
"""
MonoDesk - generator wallpaper "organized boxes" hitam-putih 1920x1080.
Meniru gaya referensi Pinterest: latar hitam + streak diagonal abu lembut,
bingkai kotak putih berlabel untuk mengorganisir ikon desktop, plus bintang.
Jalankan: python make_wallpaper.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "wallpaper-monodesk-1920x1080.png"
)


def load_font(size):
    for name in ("segoeuib.ttf", "segoeui.ttf", "arialbd.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


# ---------- 1. Latar hitam + streak diagonal lembut ----------
img = Image.new("RGB", (W, H), (5, 5, 5))

streak = Image.new("L", (W, H), 0)
sd = ImageDraw.Draw(streak)
for off, width, alpha in (
    (-350, 150, 26),
    (-60, 90, 16),
    (280, 190, 24),
    (640, 110, 13),
    (1000, 160, 20),
    (1350, 120, 12),
):
    sd.line([(off, H + 250), (off + 1500, -250)], fill=alpha, width=width)
streak = streak.filter(ImageFilter.GaussianBlur(70))
white = Image.new("RGB", (W, H), (255, 255, 255))
img = Image.composite(white, img, streak)

draw = ImageDraw.Draw(img)
font_label = load_font(24)


# ---------- 2. Bingkai kotak berlabel ----------
def frame(x1, y1, x2, y2, label=None, heart=False):
    draw.rounded_rectangle(
        [x1, y1, x2, y2], radius=16, fill=(8, 8, 8), outline=(242, 242, 242), width=3
    )
    tab_x = x1 + 28
    content_w = 0
    if label:
        content_w += draw.textlength(label, font=font_label)
    if heart:
        content_w += (30 if label else 24)
    tab_w = content_w + 40
    draw.rounded_rectangle(
        [tab_x, y1 - 20, tab_x + tab_w, y1 + 20],
        radius=10,
        fill=(8, 8, 8),
        outline=(242, 242, 242),
        width=3,
    )
    cx = tab_x + 20
    if label:
        draw.text((cx, y1 - 16), label, font=font_label, fill=(245, 245, 245))
        cx += draw.textlength(label, font=font_label) + 8
    if heart:
        draw_heart(cx + 10, y1 + 1, 11, (245, 245, 245))


def draw_heart(cx, cy, s, color):
    draw.ellipse([cx - s, cy - s, cx, cy], fill=color)
    draw.ellipse([cx, cy - s, cx + s, cy], fill=color)
    draw.polygon(
        [(cx - s, cy - s * 0.3), (cx + s, cy - s * 0.3), (cx, cy + s)], fill=color
    )


frame(90, 140, 640, 540, "APPS")
frame(720, 140, 1240, 540, "GAMES")
frame(90, 640, 860, 950, "WORK")
frame(940, 640, 1240, 950, "MY", heart=True)


# ---------- 3. Bintang berkilau di area kanan (tempat widget) ----------
def star_points(cx, cy, r):
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.32
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    return pts


stars = [(1500, 190, 30), (1620, 120, 15), (1680, 250, 20), (1420, 300, 12)]

glow = Image.new("L", (W, H), 0)
gd = ImageDraw.Draw(glow)
for cx, cy, r in stars:
    gd.polygon(star_points(cx, cy, r * 1.6), fill=90)
glow = glow.filter(ImageFilter.GaussianBlur(14))
img = Image.composite(white, img, glow)

draw = ImageDraw.Draw(img)
for cx, cy, r in stars:
    draw.polygon(star_points(cx, cy, r), fill=(255, 255, 255))

img.save(OUT)
print("OK: " + OUT)
