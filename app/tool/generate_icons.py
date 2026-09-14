"""Regenerates assets/icon/*.png (the source images flutter_launcher_icons
reads). Run with `python3 tool/generate_icons.py` from the app/ directory,
then `dart run flutter_launcher_icons` to rebuild the actual per-platform
icon files. Requires Pillow (`pip install pillow`).

Edit TOP_COLOR/BOTTOM_COLOR below to re-theme the icon.
"""

import os

from PIL import Image, ImageDraw

SUPERSAMPLE = 4
BASE_SIZE = 1024
RENDER_SIZE = BASE_SIZE * SUPERSAMPLE

TOP_COLOR = (124, 137, 255)     # lighter indigo
BOTTOM_COLOR = (58, 47, 196)    # deep indigo/violet

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")


def _lerp(a, b, t):
    return a + (b - a) * t


def gradient_square(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        row = (
            round(_lerp(TOP_COLOR[0], BOTTOM_COLOR[0], t)),
            round(_lerp(TOP_COLOR[1], BOTTOM_COLOR[1], t)),
            round(_lerp(TOP_COLOR[2], BOTTOM_COLOR[2], t)),
        )
        for x in range(size):
            px[x, y] = row
    return img


def hourglass_glyph(size, glyph_scale):
    """A white hourglass silhouette on a transparent canvas of size x size."""
    glyph = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glyph)
    white = (255, 255, 255, 255)

    box = size * glyph_scale
    margin = (size - box) / 2
    left, right = margin, margin + box
    top, bottom = margin, margin + box
    cx, cy = size / 2, size / 2
    cap_h = box * 0.09
    inset = box * 0.06  # triangle bases sit slightly inside the cap width

    draw.rounded_rectangle([left, top, right, top + cap_h], radius=cap_h * 0.4, fill=white)
    draw.rounded_rectangle([left, bottom - cap_h, right, bottom], radius=cap_h * 0.4, fill=white)
    draw.polygon([(left + inset, top + cap_h), (right - inset, top + cap_h), (cx, cy)], fill=white)
    draw.polygon([(left + inset, bottom - cap_h), (right - inset, bottom - cap_h), (cx, cy)], fill=white)

    return glyph


def build_master():
    bg = gradient_square(RENDER_SIZE).convert("RGBA")
    glyph = hourglass_glyph(RENDER_SIZE, glyph_scale=0.5)
    return Image.alpha_composite(bg, glyph).convert("RGB").resize((BASE_SIZE, BASE_SIZE), Image.LANCZOS)


def build_adaptive_background():
    return gradient_square(RENDER_SIZE).resize((BASE_SIZE, BASE_SIZE), Image.LANCZOS)


def build_adaptive_foreground():
    # Android only guarantees the inner ~66% "safe zone" survives the OEM mask,
    # so the glyph is smaller here than in the full-bleed master icon.
    canvas = Image.new("RGBA", (RENDER_SIZE, RENDER_SIZE), (0, 0, 0, 0))
    glyph = hourglass_glyph(RENDER_SIZE, glyph_scale=0.34)
    canvas = Image.alpha_composite(canvas, glyph)
    return canvas.resize((BASE_SIZE, BASE_SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    build_master().save(os.path.join(OUT_DIR, "icon.png"))
    build_adaptive_background().save(os.path.join(OUT_DIR, "icon_background.png"))
    build_adaptive_foreground().save(os.path.join(OUT_DIR, "icon_foreground.png"))
    print(f"Wrote icon.png, icon_background.png, icon_foreground.png to {os.path.abspath(OUT_DIR)}")


if __name__ == "__main__":
    main()
