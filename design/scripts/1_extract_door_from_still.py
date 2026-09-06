"""Step 1 — take the designer's ENDING still and split it into two things:

  * the door, un-warped back to flat (used as the door's inner face)
  * the backdrop, with the door removed (the stationary cabinet)

Why: the ending still shows the door already open at an angle. To animate it we
need it flat, so it can be rotated back to closed and swung forward again. That
way the moving door is the designer's own pixels, and the animation's last frame
lands on the still exactly -- nothing to cross-fade, nothing to mismatch.

QUAD below is the door's four corners IN THE STILL, in this order:
    top-hinge, top-free, bottom-free, bottom-hinge
Re-measure it whenever a new ending still arrives (draw it on the image and
eyeball it -- the corners move every time the art is regenerated).

  python 1_extract_door_from_still.py <ending-still.png>
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
STILL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    HERE, "..", "Use-It-Fresh-Ending-v2", "fridge-ending-depth-v2.png")

# Door corners in the still. MEASURE THESE AGAIN FOR A NEW STILL.
QUAD = [(722, 190), (920, 92), (920, 1512), (722, 1385)]
# Everything right of this is door, and gets blanked out of the backdrop.
CABINET_RIGHT = 717

FLAT_W, FLAT_H = 460, 1320
OUT_DOOR = os.path.join(HERE, "door_inner_from_still.png")
OUT_BACK = os.path.join(HERE, "backdrop_from_still.png")


def solve8(dst, src):
    """8 perspective coefficients mapping OUTPUT -> INPUT, for Image.transform."""
    A, B = [], []
    for (x, y), (u, v) in zip(dst, src):
        A.append([x, y, 1, 0, 0, 0, -x * u, -y * u]); B.append(u)
        A.append([0, 0, 0, x, y, 1, -x * v, -y * v]); B.append(v)
    n = 8
    M = [r[:] + [B[i]] for i, r in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        if abs(M[p][c]) < 1e-12:
            raise ValueError("degenerate quad -- check QUAD")
        M[c], M[p] = M[p], M[c]
        pv = M[c][c]
        M[c] = [v / pv for v in M[c]]
        for r in range(n):
            if r != c and M[r][c]:
                f = M[r][c]
                M[r] = [a - f * b for a, b in zip(M[r], M[c])]
    return [M[i][n] for i in range(n)]


def main():
    im = Image.open(STILL).convert("RGB")
    print(f"still: {os.path.basename(STILL)}  {im.size}")

    flat = [(0, 0), (FLAT_W, 0), (FLAT_W, FLAT_H), (0, FLAT_H)]
    door = im.transform((FLAT_W, FLAT_H), Image.PERSPECTIVE,
                        solve8(flat, QUAD), Image.BICUBIC)
    door.save(OUT_DOOR)
    print(f"door un-warped to flat -> {os.path.basename(OUT_DOOR)}  {door.size}")

    back = im.copy()
    ImageDraw.Draw(back).rectangle(
        [CABINET_RIGHT, 0, back.width, back.height], fill=im.getpixel((8, 8)))
    back.save(OUT_BACK)
    print(f"backdrop, door removed -> {os.path.basename(OUT_BACK)}")


if __name__ == "__main__":
    main()
