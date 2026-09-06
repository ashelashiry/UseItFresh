"""Door swing built from the designer's own ending still.

Key difference from v1: the moving door IS the door from
fridge-ending-depth-v2.png, un-warped back to flat. So when the swing reaches
its resting angle the door lands on the still's own pixels -- there is nothing
to cross-fade, and no second artwork to disagree with.

  backdrop  = the still with its door removed
  door back = that door, un-warped (bins, liner, gasket -- all the designer's)
  door front= the approved graphite steel face
"""
import math
import os

import bpy

HERE = r"C:\Users\ashel\AppData\Local\Temp\claude\C--Users-ashel-AppData-Local-FlutterFlow-agent-workspaces-ff-agent-useitfresh-fridge-wise-gvpy0s\23524e45-75c3-44a3-b65f-15fc9df0d2a9\scratchpad"
BACKDROP = os.path.join(HERE, "backdrop_from_still.png")
DOOR_FRONT = os.path.join(HERE, "door_front_hires.png")
DOOR_BACK = os.path.join(HERE, "door_inner_from_still.png")
OUT = os.path.join(HERE, "v2frames", "f")

# Render NATIVELY at delivery size. Rendering at 941 and upscaling to 1290 in
# ffmpeg was softening the badge; so was pre-shrinking the door texture.
SRC_W, SRC_H = 941, 1672          # coordinate space the measurements are in
K = 1290.0 / SRC_W                 # scale to delivery resolution
RES_X, RES_Y = 1290, 2292
FPS = 30
SWING_FRAMES = 52
HOLD_FRAMES = 12

# Cabinet front, measured from the backdrop. The closed door covers exactly this.
CL, CT, CR, CB = [round(v * K) for v in (129, 184, 722, 1413)]
HINGE_X = CR
DOOR_W = CR - CL          # 593
THICKNESS = 0.10

# At rest the still shows the door's free edge at x=920.
REST_FREE_X = 920.0 * K

CAM_D = 10.0
SENSOR = 36.0
FOCAL = 50.0


def solve_rest_angle(scale, cx):
    """Find the rotation whose projected free edge lands on REST_FREE_X."""
    # The still has the door swung PAST perpendicular -- its free edge sits to
    # the RIGHT of the hinge -- so the search must run beyond 90 degrees.
    best, err = 110.0, 1e9
    a = 30.0
    while a < 140.0:
        th = math.radians(a)
        xf = HINGE_X - DOOR_W * math.cos(th)
        z = DOOR_W * math.sin(th) * scale
        s = CAM_D / max(CAM_D - z, 0.1)
        proj = RES_X / 2.0 + (xf - RES_X / 2.0) * s
        if abs(proj - REST_FREE_X) < err:
            err, best = abs(proj - REST_FREE_X), a
        a += 0.25
    return best, err


def emission(name, path, alpha):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path)
    tex.extension = "CLIP"
    nt.links.new(tex.outputs["Color"], emit.inputs["Color"])
    if alpha:
        mix = nt.nodes.new("ShaderNodeMixShader")
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        nt.links.new(tex.outputs["Alpha"], mix.inputs["Fac"])
        nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
        nt.links.new(emit.outputs["Emission"], mix.inputs[2])
        nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    else:
        nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    for k, v in (("blend_method", "CLIP"), ("surface_render_method", "DITHERED"),
                 ("use_backface_culling", True), ("alpha_threshold", 0.5)):
        try:
            setattr(mat, k, v)
        except (AttributeError, TypeError):
            pass
    return mat


def flat(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    e = nt.nodes.new("ShaderNodeEmission")
    e.inputs["Color"].default_value = (*rgb, 1.0)
    nt.links.new(e.outputs["Emission"], out.inputs["Surface"])
    return mat


def ease(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = RES_X, RES_Y
    sc.render.fps = FPS
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = OUT
    sc.view_settings.view_transform = "Standard"
    sc.frame_start, sc.frame_end = 1, SWING_FRAMES + HOLD_FRAMES

    vis_h = 2.0 * CAM_D * ((SENSOR / 2.0) / FOCAL)
    s = vis_h / RES_Y
    vis_w = vis_h * (RES_X / RES_Y)

    cam_d = bpy.data.cameras.new("Cam")
    cam_d.sensor_fit, cam_d.sensor_height, cam_d.lens = "VERTICAL", SENSOR, FOCAL
    cam = bpy.data.objects.new("Cam", cam_d)
    cam.location = (0, 0, CAM_D)
    bpy.context.collection.objects.link(cam)
    sc.camera = cam

    bpy.ops.mesh.primitive_plane_add(size=1.0)
    bg = bpy.context.object
    bg.scale = (vis_w, vis_h, 1)
    bg.data.materials.append(emission("Bg", BACKDROP, False))

    wx = lambda p: (p - RES_X / 2.0) * s
    wy = lambda p: (RES_Y / 2.0 - p) * s
    xl, xr, yt, yb = wx(CL), wx(CR), wy(CT), wy(CB)
    dw, dh = xr - xl, yt - yb

    rest, err = solve_rest_angle(s, RES_X / 2.0)
    print(f"REST_ANGLE {rest:.2f} deg (free-edge error {err:.1f}px)")

    bpy.ops.mesh.primitive_cube_add(size=1.0)
    door = bpy.context.object
    door.scale = (dw, dh, THICKNESS)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    m = door.data
    for v in m.vertices:
        v.co.x -= dw / 2.0
        v.co.y += (yt + yb) / 2.0
        v.co.z += THICKNESS / 2.0 + 0.01
    door.location = (xr, 0, 0)
    m.update()

    m.materials.append(emission("Front", DOOR_FRONT, True))
    m.materials.append(flat("Edge", (0.05, 0.055, 0.055)))
    m.materials.append(emission("Back", DOOR_BACK, False))
    for p in m.polygons:
        p.material_index = 0 if p.normal.z > 0.5 else (2 if p.normal.z < -0.5 else 1)

    m.uv_layers.new(name="UVMap")
    uv = m.uv_layers.active.data
    for p in m.polygons:
        if p.material_index == 1:
            continue
        for li in p.loop_indices:
            co = m.vertices[m.loops[li].vertex_index].co
            uv[li].uv = ((co.x + dw) / dw, (co.y - yb) / dh)

    try:
        bpy.context.preferences.edit.keyframe_new_interpolation_type = "LINEAR"
    except Exception:
        pass
    for f in range(1, SWING_FRAMES + HOLD_FRAMES + 1):
        t = min((f - 1) / (SWING_FRAMES - 1), 1.0)
        door.rotation_euler = (0, math.radians(rest * ease(t)), 0)
        door.keyframe_insert("rotation_euler", frame=f)

    print("SCENE_OK")
    bpy.ops.render.render(animation=True)
    print("RENDER_DONE")


main()
