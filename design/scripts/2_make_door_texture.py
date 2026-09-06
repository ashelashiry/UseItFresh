"""Build the fridge door texture from a clean door + a swappable logo.

This is the whole point of decoupling: to change the logo you replace LOGO and
re-run. No new fridge artwork, no re-modelling -- just this script and a render.

  python make_door_texture.py [path/to/logo.png]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

SP = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(SP, "logopack", "Use-It-Fresh-Logo-01")

DOOR_CLEAN = os.path.join(PACK, "07-Fridge", "02-door-front-nologo.png")
LOGO = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    PACK, "02-Transparent-PNG", "stacked-color-2048px.png")
OUT = os.path.join(SP, "door_front_composited.png")

# Where the magnet sits on the 1080x1920 door canvas, measured from the original
# artwork before the logo was removed.
PLATE = (472, 330, 630, 516)
PLATE_FILL = (233, 231, 219)
PLATE_RADIUS = 22
LOGO_INSET = 0.80          # logo occupies this much of the plate


def main():
    door = Image.open(DOOR_CLEAN).convert("RGBA")
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.getchannel("A").getbbox())

    x0, y0, x1, y1 = PLATE
    pw, ph = x1 - x0, y1 - y0

    # --- the cream magnet plate, with a soft drop shadow so it sits ON the door
    shadow = Image.new("RGBA", door.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x0 + 3, y0 + 5, x1 + 3, y1 + 7], radius=PLATE_RADIUS, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(7))
    door = Image.alpha_composite(door, shadow)

    plate = Image.new("RGBA", door.size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(plate)
    pd.rounded_rectangle([x0, y0, x1, y1], radius=PLATE_RADIUS,
                         fill=(*PLATE_FILL, 255))
    # Bevel: a bright rim plus a soft inner line, so the badge reads as an
    # object sitting on the door rather than a flat sticker.
    pd.rounded_rectangle([x0, y0, x1, y1], radius=PLATE_RADIUS,
                         outline=(255, 253, 246, 235), width=3)
    inner = Image.new("RGBA", door.size, (0, 0, 0, 0))
    ImageDraw.Draw(inner).rounded_rectangle(
        [x0 + 4, y0 + 4, x1 - 4, y1 - 4], radius=PLATE_RADIUS - 4,
        outline=(196, 191, 176, 120), width=2)
    plate = Image.alpha_composite(plate, inner.filter(ImageFilter.GaussianBlur(1.1)))
    door = Image.alpha_composite(door, plate)

    # --- the logo, scaled to fit inside the plate without distortion
    avail_w, avail_h = pw * LOGO_INSET, ph * LOGO_INSET
    k = min(avail_w / logo.width, avail_h / logo.height)
    lw, lh = max(1, round(logo.width * k)), max(1, round(logo.height * k))
    logo = logo.resize((lw, lh), Image.LANCZOS)

    layer = Image.new("RGBA", door.size, (0, 0, 0, 0))
    layer.paste(logo, (x0 + (pw - lw) // 2, y0 + (ph - lh) // 2), logo)
    door = Image.alpha_composite(door, layer)

    door.save(OUT)
    print(f"logo:  {os.path.relpath(LOGO, SP)}")
    print(f"plate: {pw}x{ph} at ({x0},{y0})   logo fitted to {lw}x{lh}")
    print(f"wrote: {OUT}")


if __name__ == "__main__":
    main()
