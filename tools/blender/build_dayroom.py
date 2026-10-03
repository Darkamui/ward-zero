"""Build the first G01 art study around the shipped Godot camera/layout.

Run with Blender --background --python tools/blender/build_dayroom.py -- --draft
Omit --draft for both 1920x1080 review renders. Exports a matching runtime proxy.
Coordinates in the helpers are Godot metres (X right, Y up, -Z forward).
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import re
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "game/rooms/g01_dayroom/g01_dayroom.tscn"
OUT = ROOT / "art-src/g01_dayroom"
REVIEW = ROOT / "production/art-review/g01_dayroom"
OUT.mkdir(parents=True, exist_ok=True)
(ROOT / "art-src/.gdignore").touch()
REVIEW.mkdir(parents=True, exist_ok=True)
args = argparse.ArgumentParser()
args.add_argument("--draft", action="store_true")
args.add_argument("--camera", choices=("cam_a", "cam_b", "both"), default="both")
opts = args.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
random.seed(1976)

# This script runs in a separate background Blender process, never the user's UI.
if not bpy.app.background:
    raise RuntimeError("Run this builder with blender --background; it creates a new scene.")
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
collections = {}
for name in ("ART", "CAMS", "LIGHTS", "CHAIN_LOCKED", "CHAIN_RELEASED"):
    collections[name] = bpy.data.collections.new(name)
    scene.collection.children.link(collections[name])


def move_to(obj, collection="ART"):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collections[collection].objects.link(obj)
    return obj


def gv(p):
    return Vector((p[0], -p[2], p[1]))


def material(name, dark, light, scale=5, roughness=.75, metal=0, grain=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metal
    coord = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 5
    noise.inputs["Roughness"].default_value = .72
    vector = coord.outputs["Object"]
    if grain:
        stretch = nodes.new("ShaderNodeVectorMath")
        stretch.operation = "MULTIPLY"
        stretch.inputs[1].default_value = grain
        links.new(vector, stretch.inputs[0])
        vector = stretch.outputs[0]
    links.new(vector, noise.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = .22
    ramp.color_ramp.elements[0].color = (*dark, 1)
    ramp.color_ramp.elements[1].position = .78
    ramp.color_ramp.elements[1].color = (*light, 1)
    links.new(noise.outputs["Fac"], ramp.inputs[0])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .24
    bump.inputs["Distance"].default_value = .008 if not grain else .002
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs[0], bsdf.inputs["Normal"])
    fine = nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value = 180
    links.new(coord.outputs["Object"], fine.inputs["Vector"])
    fine_bump = nodes.new("ShaderNodeBump")
    fine_bump.inputs["Strength"].default_value = .18
    fine_bump.inputs["Distance"].default_value = .0015
    links.new(fine.outputs["Fac"], fine_bump.inputs["Height"])
    links.new(bump.outputs[0], fine_bump.inputs["Normal"])
    links.new(fine_bump.outputs[0], bsdf.inputs["Normal"])
    return mat


plaster = material("WZ / stained chalk plaster", (.19, .17, .135), (.47, .43, .34), 3)
green = material("WZ / worn institutional sage", (.055, .082, .073), (.17, .22, .18), 4, .62)
trim = material("WZ / old cream enamel", (.20, .19, .15), (.42, .40, .32), 7, .52)
wood = material("WZ / dark walnut grain", (.018, .007, .003), (.085, .031, .011), 5, .42, grain=(1, 28, 8))
wood_edge = material("WZ / dark endgrain", (.015, .010, .007), (.065, .035, .014), 9, .54, grain=(1, 14, 5))
steel = material("WZ / oxidized steel", (.055, .065, .058), (.20, .23, .20), 12, .5, .7)
brass = material("WZ / tarnished brass", (.10, .055, .016), (.31, .21, .075), 9, .38, .75)
dark = material("WZ / black bakelite", (.008, .011, .010), (.028, .035, .03), 24, .38)
paper = material("WZ / unprinted aged paper", (.39, .34, .24), (.69, .62, .45), 20, .94)
fabric = material("WZ / faded moss upholstery", (.055, .065, .042), (.19, .20, .12), 14, .94, grain=(1, 1, 2))
red = material("WZ / oxblood paint", (.10, .015, .01), (.23, .045, .025), 8, .7)
glass = material("WZ / clouded glass", (.055, .095, .105), (.12, .21, .24), 4, .24, .15)
rust = material("WZ / dark water marks", (.055, .035, .02), (.17, .11, .065), 4)
MATS = dict(wood=wood, wood_edge=wood_edge, steel=steel, brass=brass, dark=dark,
            ivory=paper, fabric=fabric, red=red, glass=glass, yellow=brass)


def scanned_paint(mat, color):
    """Recolor CC0 peeling paint in the shader; keep the scan unmodified."""
    base = ROOT / "art-src/shared/materials/peeling_painted_wall"
    if not (base / "diff.jpg").exists():
        raise FileNotFoundError("Fetch the textures with tools/blender/fetch_dayroom_materials.py first")
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    geo = nodes.new("ShaderNodeNewGeometry")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "SCALE"
    scale.inputs[3].default_value = .40
    links.new(geo.outputs["Position"], scale.inputs[0])
    textures = {}
    for key in ("diff", "disp", "rough"):
        image = bpy.data.images.load(str(base / (key+".jpg")), check_existing=True)
        if key != "diff":
            image.colorspace_settings.name = "Non-Color"
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.projection = "BOX"
        tex.projection_blend = .15
        links.new(scale.outputs[0], tex.inputs[0])
        textures[key] = tex
    split = nodes.new("ShaderNodeSeparateColor")
    links.new(textures["diff"].outputs[0], split.inputs[0])
    difference = nodes.new("ShaderNodeMath")
    difference.operation = "SUBTRACT"
    links.new(split.outputs[0], difference.inputs[0])
    links.new(split.outputs[1], difference.inputs[1])
    mask = nodes.new("ShaderNodeMapRange")
    mask.inputs["From Min"].default_value = .025
    mask.inputs["From Max"].default_value = .07
    links.new(difference.outputs[0], mask.inputs[0])
    paint = nodes.new("ShaderNodeMixRGB")
    paint.inputs[1].default_value = (.145,.125,.087,1)
    paint.inputs[2].default_value = (*color,1)
    links.new(mask.outputs[0], paint.inputs[0])
    links.new(paint.outputs[0], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .6
    bump.inputs["Distance"].default_value = .035
    links.new(textures["disp"].outputs[0], bump.inputs["Height"])
    links.new(bump.outputs[0], bsdf.inputs["Normal"])
    links.new(textures["rough"].outputs[0], bsdf.inputs["Roughness"])


scanned_paint(plaster, (.37,.335,.26))
scanned_paint(green, (.09,.135,.092))


def box(name, size, pos, mat, bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=gv(pos))
    obj = move_to(bpy.context.object)
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft worn edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def cylinder(name, radius, a, b, mat):
    va, vb = gv(a), gv(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=(vb-va).length,
                                      location=(va+vb)/2)
    obj = move_to(bpy.context.object)
    obj.name = name
    obj.rotation_euler = (vb-va).to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth = True
    bevel = obj.modifiers.new("Rim", "BEVEL")
    bevel.width = min(.004, radius*.15)
    bevel.segments = 2
    return obj


def curve(name, points, radius, mat):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth = radius
    data.bevel_resolution = 3
    spline = data.splines.new("POLY")
    spline.points.add(len(points)-1)
    for p, co in zip(spline.points, points):
        p.co = (*gv(co), 1)
    obj = bpy.data.objects.new(name, data)
    collections["ART"].objects.link(obj)
    data.materials.append(mat)
    return obj


def import_prop(asset, name, pos, size=None, yaw=0, external=False):
    before = set(bpy.data.objects)
    path = (ROOT / "art-src/shared/models" / asset / (asset+"_2k.gltf")
            if external else ROOT / "assets/models" / (asset+".glb"))
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects = set(bpy.data.objects)-before
    meshes = [o for o in objects if o.type == "MESH"]
    bpy.context.view_layer.update()
    points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lower = Vector([min(v[i] for v in points) for i in range(3)])
    upper = Vector([max(v[i] for v in points) for i in range(3)])
    center = Vector(((lower.x+upper.x)/2, (lower.y+upper.y)/2, lower.z))
    scale = Vector((1, 1, 1))
    if size:
        target = Vector((size[0], size[2], size[1]))
        scale = Vector([target[i]/(upper[i]-lower[i]) for i in range(3)])
        if external:
            scale = Vector((min(scale),)*3)
    transform = Matrix.Translation(gv(pos)) @ Matrix.Rotation(math.radians(yaw), 4, "Z") @ Matrix.Diagonal((*scale, 1)) @ Matrix.Translation(-center)
    for obj in meshes:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = transform @ world
        obj.name = name + " / " + obj.name
        move_to(obj)
        for slot in obj.material_slots:
            if slot.material and not external:
                key = slot.material.name.split(".")[0]
                slot.material = MATS.get(key, wood)
    for obj in objects:
        if obj.type != "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)
    return meshes


# Shell matches the collision planes of the shipped scene, including north door.
box("art_ceiling", (9, .1, 7), (0, 3.25, 0), plaster)
for name, size, pos in [
    ("west", (.2, 3.2, 7), (-4.6, 1.6, 0)),
    ("east", (.2, 3.2, 7), (4.6, 1.6, 0)),
    ("north_left", (6.4, 3.2, .2), (-1.3, 1.6, -3.6)),
    ("north_right", (1.4, 3.2, .2), (3.8, 1.6, -3.6)),
    ("lintel", (1.2, 1, .2), (2.5, 2.7, -3.6)),
]:
    box("art_wall_"+name, size, pos, plaster, 0)
    if name != "lintel":
        box("art_dado_"+name, (size[0]+.004, 1.25, size[2]+.004), (pos[0], .625, pos[2]), green, 0)
        box("art_skirt_"+name, (size[0]+.028, .13, size[2]+.028), (pos[0], .065, pos[2]), wood_edge, .004)
        box("art_dado_lip_"+name, (size[0]+.014, .028, size[2]+.014), (pos[0], 1.25, pos[2]), green, .003)

# South wall is behind cam_a; its real window opening supplies the cold key light.
box("art_south_left", (4.8, 3.2, .2), (-2.1, 1.6, 3.6), plaster, 0)
box("art_south_right", (1.8, 3.2, .2), (3.6, 1.6, 3.6), plaster, 0)
box("art_south_below_window", (2.4, 1.3, .2), (1.5, .65, 3.6), green, 0)
box("art_south_above_window", (2.4, .7, .2), (1.5, 2.85, 3.6), plaster, 0)
for x in (.3, 1.1, 1.9, 2.7):
    box("art_window_mullion", (.055, 1.23, .10), (x, 1.9, 3.55), trim)
for y in (1.3, 1.9, 2.5):
    box("art_window_rail", (2.45, .05, .1), (1.5, y, 3.55), trim)
box("art_window_sill", (2.58, .075, .32), (1.5, 1.27, 3.49), trim)

# Actual tile geometry gives small worn edges and restrained reflections.
grout = material("WZ / floor grout", (.07, .063, .045), (.11, .105, .085), 45)
box("floor_main", (9, .1, 7), (0, -.059, 0), grout, 0)
tiles = []
for i in range(8):
    value = .80 + i*.065
    tiles.append(material("WZ / linoleum %02d" % i,
                          tuple(v*value for v in (.10, .115, .10)),
                          tuple(v*value for v in (.24, .235, .18)), 18, .46))
tile_objects = []
for ix in range(30):
    for iz in range(24):
        z0 = -3.5 + iz*.3
        depth = min(.3, 3.5-z0)
        if depth <= 0:
            continue
        tile_objects.append(box("art_floor_tile", (.297, .012, depth-.003),
                                (-4.35+ix*.3, -.004, z0+depth/2), random.choice(tiles), .0015))

# Structural column retains the exact existing silhouette.
box("occ_pillar", (.4, 3.2, .4), (-1.3, 1.6, .5), plaster, .001)
box("art_pillar_dado", (.401, 1.25, .401), (-1.3, .625, .5), green, 0)
box("art_north_cornice", (9,.065,.06), (0,3.155,-3.46), trim, .01)
box("art_west_cornice", (.06,.065,7), (-4.46,3.155,0), trim, .01)

# Refine the supplied prop kit at the current gameplay anchors.
import_prop("painted_wooden_chair_01", "occ_chair", (1.6, 0, 1.4), (.5, .9, .5), external=True)
import_prop("side_table", "occ_table_recorder", (-3.7, 0, -2.8), (.9, .75, .6))
import_prop("side_table", "occ_table_radio", (4, 0, -1.4), (.7, .75, 1.2), yaw=0)
import_prop("table_radio", "art_radio", (4.05, .75, -1.4), (.45, .30, .25), yaw=-90)
import_prop("dictaphone", "art_recorder", (-3.7, .758, -2.8))
import_prop("effects_bin", "occ_bin", (-4, 0, -.4), (.6, .6, 1))

# A low upholstered couch fills the greybox's 2.2 x .8 x .9 envelope.
box("occ_couch_plinth", (2.12, .16, .83), (-2.6, .19, 2.3), wood_edge, .025)
box("occ_couch_back", (1.82, .53, .19), (-2.6, .535, 2.655), fabric, .045)
for x in (-3.60, -1.60):
    box("occ_couch_arm", (.2, .46, .9), (x, .47, 2.3), fabric, .045)
for x in (-3.24, -2.6, -1.96):
    box("occ_couch_seat", (.62, .17, .66), (x, .38, 2.245), fabric, .05)
    box("occ_couch_back_cushion", (.62, .35, .16), (x, .60, 2.51), fabric, .04)
    curve("art_cushion_piping", [(x-.285,.451,1.953),(x+.285,.451,1.953)], .002, wood_edge)
for x in (-3.50, -1.70):
    for z in (1.97, 2.61):
        box("occ_couch_foot", (.10, .15, .10), (x, .075, z), wood, .012)

# North door with separate locked/released chain collections.
box("art_door", (1.2, 2.2, .08), (2.5, 1.1, -3.52), wood, .004)
for x in (1.86, 3.14):
    box("art_door_casing", (.10, 2.28, .085), (x, 1.14, -3.45), wood_edge)
box("art_door_header", (1.38, .10, .085), (2.5, 2.28, -3.45), wood_edge)
for x in (2.23, 2.77):
    for y, h in ((.54, .65), (1.55, 1.04)):
        box("art_door_panel", (.43, h, .017), (x, y, -3.469), wood_edge, .008)
        box("art_door_panel_inset", (.37, h-.065, .02), (x, y, -3.455), wood, .005)
box("art_latch_plate", (.055, .21, .025), (2.96, 1.05, -3.455), brass)
cylinder("art_door_handle", .018, (2.96, 1.05, -3.42), (2.82, 1.05, -3.42), brass)
for x in (1.86, 3.14):
    box("art_chain_anchor", (.085, .14, .025), (x, 1.24, -3.385), steel, .009)
    for y in (1.195, 1.285):
        cylinder("art_chain_anchor_bolt", .010, (x, y, -3.37), (x, y, -3.35), brass)


def chain_path(t, released):
    if not released:
        return Vector((1.86 + 1.28*t, 1.24 - .14*math.sin(math.pi*t), -3.34))
    # Same chain hangs from the left anchor, with its free end resting near the sill.
    if t < .88:
        return Vector((1.86 + .025*math.sin(t*5), 1.24 - 1.20*t/.88, -3.34 + .018*t))
    u = (t-.88)/.12
    return Vector((1.86 + .15*u, .04, -3.324 + .045*math.sin(u*math.pi)))


for released in (False, True):
    state_collection = "CHAIN_RELEASED" if released else "CHAIN_LOCKED"
    for i in range(47):
        t = i/46
        p = chain_path(t, released)
        tangent = (gv(chain_path(min(1, t+.002), released)) -
                   gv(chain_path(max(0, t-.002), released))).normalized()
        normal = Vector((0, -1, 0))
        side = normal.cross(tangent).normalized()
        normal = tangent.cross(side).normalized()
        basis = Matrix((tangent, side, normal)).transposed().to_4x4()
        bpy.ops.mesh.primitive_torus_add(major_radius=.018, minor_radius=.0045,
                                        major_segments=20, minor_segments=8)
        obj = move_to(bpy.context.object, state_collection)
        obj.name = "chain_released_link" if released else "chain_locked_link"
        obj.matrix_world = (Matrix.Translation(gv(p)) @ basis @
                            Matrix.Rotation(math.radians(70 if i%2 else 0), 4, "X") @
                            Matrix.Diagonal((1.35, 1, 1, 1)))
        obj.data.materials.append(steel)
        for poly in obj.data.polygons:
            poly.use_smooth = True
    # Padlock hangs at the right anchor when locked, and lies with the free end when released.
    x, y, z = (2.02, .065, -3.32) if released else (3.10, 1.18, -3.32)
    move_to(box("chain_padlock", (.075, .085, .038), (x, y, z), brass, .009), state_collection)
    shackle = [(x-.024, y+.035, z), (x-.024, y+.077, z),
               (x, y+.091, z), (x+.024, y+.077, z),
               (x+.024, y+(.055 if released else .035), z)]
    move_to(curve("chain_padlock_shackle", shackle, .006, steel), state_collection)
collections["CHAIN_RELEASED"].hide_render = True

# Wall-bound dressing does not obstruct any gameplay approach route.
box("art_notice_board", (.66, .86, .033), (.5, 1.6, -3.46), wood_edge)
box("art_notice_paper", (.59, .78, .006), (.5, 1.6, -3.438), paper, .002)
for x in (.24, .76):
    cylinder("art_notice_pin", .008, (x, 1.95, -3.43), (x, 1.95, -3.423), brass)
for y in (1.41, 1.51, 1.61, 1.71):
    box("art_notice_rule", (.40, .002, .001), (.5, y, -3.434), wood_edge, 0)

# Wall frames use abstract aged-paper inserts: no baked localized/puzzle text.
for x, y, w, h in [(-2.7, 2.10, .62, .80), (-.9, 2.12, .47, .60)]:
    box("art_wall_frame", (w, h, .045), (x, y, -3.46), wood_edge, .012)
    box("art_frame_mat", (w-.055, h-.055, .006), (x, y, -3.432), paper, .003)
    box("art_faded_print", (w-.15, h-.16, .005), (x, y, -3.425), green, .002)
    for j in range(5):
        box("art_print_line", (w-.22, .018, .003), (x, y-.12+j*.06, -3.420), plaster, 0)

for z in (-2.1, -2.0):
    cylinder("art_vertical_pipe", .022, (-4.43,.15,z), (-4.43,3.2,z), trim)
    for y in (.3,1.3,2.8):
        cylinder("art_pipe_collar", .03, (-4.43,y-.025,z), (-4.43,y+.025,z), steel)
for i in range(11):
    z = .05+i*.075
    box("art_radiator_fin", (.17,.61,.048), (-4.38,.40,z), trim, .021)
cylinder("art_radiator_pipe", .027, (-4.37,.18,-.04), (-4.37,.18,.90), steel)

# Small paper stack and task lamp around the recorder draw the eye to interaction.
for i in range(4):
    obj = box("art_desk_paper", (.21,.0018,.16), (-3.47,.755+i*.003,-2.65), paper, .001)
    obj.rotation_euler.z = math.radians(-8+i*3)
cylinder("art_lamp_base", .085, (-3.98,.751,-2.99), (-3.98,.78,-2.99), dark)
curve("art_lamp_stem", [(-3.98,.78,-2.99),(-3.98,1.15,-2.99),(-3.83,1.26,-2.95),(-3.75,1.22,-2.93)], .011, brass)
bpy.ops.mesh.primitive_cone_add(vertices=40, radius1=.125, radius2=.045, depth=.12,
                                location=gv((-3.75,1.17,-2.93)))
obj = move_to(bpy.context.object)
obj.name = "art_lamp_shade"
obj.data.materials.append(green)
curve("art_lamp_cord", [(-3.98,.76,-3.01),(-4.10,.70,-3.04),(-4.12,.07,-3.04),(-4.40,.05,-3.1)], .005, dark)

# Small contact details and litter at the room edges, outside approach paths.
for x in (-3.9,-.2,3.6):
    box("art_socket_plate", (.075,.12,.012), (x,.35,-3.488), trim, .007)
    for dx in (-.015,.015):
        box("art_socket_hole", (.005,.013,.002), (x+dx,.36,-3.48), dark, 0)
for i in range(55):
    x = random.uniform(-4.35,1.6)
    z = random.uniform(-3.43,-3.12)
    flake = box("art_plaster_flake", (random.uniform(.009,.05),.002,random.uniform(.008,.045)),
                (x,.004,z), plaster if i%2 else paper, .001)
    flake.rotation_euler.z = random.uniform(0,math.tau)
for i in range(4):
    sheet = box("art_discarded_paper", (.15,.001,.21), (-3.6+i*.11,.007,-2.98+i*.045), paper, .001)
    sheet.rotation_euler.z = random.uniform(-.7,.7)
# Conduit and a disconnected ceiling light support the institutional setting.
cylinder("art_ceiling_conduit", .012, (-4.3,3.17,-2.1), (0,3.17,-2.1), trim)
box("art_ceiling_light_base", (1.1,.07,.23), (-.3,3.135,-2.1), steel)
box("art_ceiling_light_diffuser", (1.02,.04,.18), (-.3,3.08,-2.1), paper)


def area(name, pos, target, energy, color, size, size_y=None):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "RECTANGLE"
    data.size = size
    data.size_y = size_y or size
    obj = bpy.data.objects.new(name, data)
    collections["LIGHTS"].objects.link(obj)
    obj.location = gv(pos)
    obj.rotation_euler = (gv(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj


area("Cold south window", (1.5,2.15,3.72), (-2, .4, -1.5), 450, (.56,.69,1), 2.4, 1.2)
area("Soft overcast window fill", (1.5,2.3,3.25), (-2,1,-2), 45, (.61,.73,1), 2.2, 1.0)
area("Recorder task lamp", (-3.75,1.10,-2.93), (-3.6,.74,-2.65), 40, (1,.61,.28), .16)
area("Ceiling bounced fill", (0,3.05,.3), (0,0,0), 8, (.65,.72,1), 3.5)
scene.world = bpy.data.worlds.new("Cold exterior")
scene.world.use_nodes = True
background = next(n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND")
background.inputs["Color"].default_value = (.21,.29,.42,1)
background.inputs["Strength"].default_value = .12

# Use the serialized camera matrix, not a hand-adjusted look-at approximation.
source = SOURCE.read_text(encoding="utf-8")
C = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
camera_manifest = {}
for name in ("cam_a", "cam_b"):
    block = re.search(r'\[node name="'+name+r'"[^\n]+\]\n(.*?)(?=\n\[)', source, re.S).group(1)
    values = [float(v.strip()) for v in re.search(r'Transform3D\(([^)]+)\)',block).group(1).split(',')]
    # Transform3D text serializes the 3x3 basis row by row.
    g = Matrix(((values[0],values[1],values[2],values[9]),
                (values[3],values[4],values[5],values[10]),
                (values[6],values[7],values[8],values[11]),(0,0,0,1)))
    fov = float(re.search(r'fov = ([\d.]+)',block).group(1))
    data = bpy.data.cameras.new(name)
    data.sensor_fit = "VERTICAL"
    data.sensor_height = 24
    data.lens = 12 / math.tan(math.radians(fov)/2)
    data.clip_start = .05
    data.clip_end = 60
    obj = bpy.data.objects.new(name, data)
    collections["CAMS"].objects.link(obj)
    obj.matrix_world = C @ g
    target = gv((-2.0,.5,-1.2) if name == "cam_a" else (2.2,.5,-1.4))
    forward = -(obj.matrix_world.to_3x3().col[2])
    assert forward.normalized().dot((target-obj.location).normalized()) > .999999
    camera_manifest[name] = dict(godot_transform=values, vertical_fov=fov,
                                 blender_matrix=[list(row) for row in obj.matrix_world])
scene.camera = bpy.data.objects["cam_a"]

scene.render.engine = "CYCLES"
scene.cycles.samples = 32 if opts.draft else 160
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 8
scene.cycles.seed = 1976
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "OPTIX"
    prefs.get_devices()
    devices = [d for d in prefs.devices if d.type == "OPTIX"]
    if devices:
        for d in prefs.devices:
            d.use = d in devices
        scene.cycles.device = "GPU"
except Exception as exc:
    print("GPU unavailable; using CPU:", exc)
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.resolution_percentage = 50 if opts.draft else 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGB"
scene.render.image_settings.color_depth = "8"
scene.view_settings.view_transform = "AgX"
scene.view_settings.exposure = -.6
selected_cameras = ("cam_a", "cam_b") if opts.camera == "both" else (opts.camera,)

manifest = dict(room="G01", stage="camera-matched room art with detailed visual proxies",
                source_scene=str(SOURCE.relative_to(ROOT)),
                source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                cameras=camera_manifest, resolution=[1920,1080],
                renderer="Cycles", samples=scene.cycles.samples,
                materials=[m.name for m in bpy.data.materials if m.name.startswith("WZ /")],
                rendered_cameras=list(selected_cameras),
                rendered_states=["locked", "released"],
                external_models=["painted_wooden_chair_01"],
                note="No AI paintover. Existing gameplay anchors retained. Detailed visual occluders exported separately from collision footprints.")
(REVIEW / "render-manifest.json").write_text(json.dumps(manifest, indent=2)+"\n",encoding="utf-8")
sys.path.insert(0, str(Path(__file__).parent))
from export_dayroom_proxy import export_proxy
if not opts.draft:
    export_proxy(ROOT, collections)
bpy.ops.file.pack_all()
for released in (False, True):
    collections["CHAIN_LOCKED"].hide_render = released
    collections["CHAIN_RELEASED"].hide_render = not released
    for camera_name in selected_cameras:
        scene.camera = bpy.data.objects[camera_name]
        suffix = "_released" if released else ""
        scene.render.filepath = str(REVIEW / (camera_name + suffix + ("_draft.png" if opts.draft else ".png")))
        bpy.ops.render.render(write_still=True)
        print("DAYROOM_RENDER_COMPLETE", scene.render.filepath)
collections["CHAIN_LOCKED"].hide_render = False
collections["CHAIN_RELEASED"].hide_render = True
scene.camera = bpy.data.objects["cam_a"]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "dayroom.blend"))
