# Fridge door animation — how v6 was made

Four steps. Each writes the input for the next. Nothing here is hand-tweaked;
re-running the chain reproduces the clip exactly.

```
1_extract_door_from_still.py   ending still  ->  flat door + clean backdrop
2_make_door_texture.py         clean door + logo  ->  door front face
3_render_swing.py              (Blender)  ->  PNG frames
4  ffmpeg                      frames  ->  mp4 + sign-in backdrop
```

## The idea

The door is **real 3D geometry** — a slab with thickness, hinged on its right
edge — sitting in front of a flat backdrop plane. Everything uses emission
shading so the artwork's own baked lighting is preserved; adding lights would
double-light an already-lit render.

The important trick is step 1. The ending still shows the door already open at
an angle, so we un-warp it back to flat and use *that* as the door's inner face.
The animation is therefore made of the designer's own pixels, and its last frame
lands on the still exactly. No cross-fade, no mismatched outlines.

## Running it

```bash
python 1_extract_door_from_still.py ../Use-It-Fresh-Ending-v2/fridge-ending-depth-v2.png
python 2_make_door_texture.py       ../<logo>.png
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python 3_render_swing.py

ffmpeg -framerate 30 -i frames/f%04d.png -c:v libx264 -crf 21 -preset slow \
       -pix_fmt yuv420p -an fridge-opening.mp4
ffmpeg -i frames/<last>.png -q:v 3 signin-bg.jpg
```

## Changing the logo

Only step 2 and onward. Supply any transparent PNG:

```bash
python 2_make_door_texture.py ../my-new-logo.png
```

The cream plate, its bevel and drop shadow are drawn in code, so the logo is the
only input. No new fridge artwork is needed — that's the whole reason
`02-door-front-nologo.png` exists.

## Changing the ending still

Re-measure `QUAD` in step 1 — the door's four corners in the new still, ordered
top-hinge, top-free, bottom-free, bottom-hinge. Also check `CL/CT/CR/CB` (the
cabinet rectangle) and `REST_FREE_X` in step 3. The solver then finds the swing
angle that reproduces the new door position; it prints the angle and its
error in pixels, which should be ~1px.

## Things that bit us, so they don't again

- **Render natively at delivery size.** Rendering at 941 wide and upscaling to
  1290 in ffmpeg visibly softened the badge. Same for pre-shrinking the door
  texture — use it at full resolution and let Blender sample it.
- **h264 needs even dimensions.** 941 wide fails to encode.
- **EEVEE alpha BLEND doesn't write depth**, so the slab's back face drew over
  its front. Use alpha CLIP plus backface culling.
- **Blender 5.x** uses slotted Actions; `action.fcurves` is gone. Set
  `keyframe_new_interpolation_type` before inserting keys instead.
- **Ease with smootherstep, not ease-out.** A quintic ease-out put 97% of the
  rotation in the first half — it snapped open then sat still, which reads as a
  jerk.
- The delivered layer set is **mutually inconsistent** (closed frame 699×1666,
  shell layer 783×1535, door layer 750×1856). Don't trust the layers against
  each other; derive geometry from one still and stick to it.
