"""Convert the supplied Mixamo Ch08 character and matching clips to runtime GLB.

Blender --background --python tools/blender/prepare_mixamo_mathieu.py
Requires system Python with Pillow (override with WZ_PYTHON).
Source FBXs are untouched; animation compatibility is checked before transfer.
"""

import hashlib
import json
import math
import os
from pathlib import Path
import struct
import subprocess

import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/character/mathieu"
WORK = ROOT / "art-src/characters/mathieu/mixamo"
OUT = ROOT / "game/characters/mathieu"
REVIEW = ROOT / "production/art-review/mathieu"
BUDGETS = {"Ch08_Body": 7000, "Ch08_Pants": 3500, "Ch08_Hoodie": 6000,
           "Ch08_Hair": 4000, "Ch08_Beard": 1500, "Ch08_Sneakers": 1800}


def triangle_count(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def make_material(name, hair=False):
    mat = bpy.data.materials.new(name)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")

    def texture(filename, noncolor=False):
        node = nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(str(WORK / filename), check_existing=True)
        if noncolor:
            node.image.colorspace_settings.name = "Non-Color"
        return node

    color = texture("hair.png" if hair else "body_Diffuse.png")
    links.new(color.outputs["Color"], shader.inputs["Base Color"])
    shader.inputs["Metallic"].default_value = 0
    if hair:
        links.new(color.outputs["Alpha"], shader.inputs["Alpha"])
        shader.inputs["Roughness"].default_value = 0.85
        mat.use_backface_culling = False
    else:
        rough = texture("body_Glossiness.png", True)
        links.new(rough.outputs["Color"], shader.inputs["Roughness"])
        normal = texture("body_Normal.png", True)
        normal_map = nodes.new("ShaderNodeNormalMap")
        links.new(normal.outputs["Color"], normal_map.inputs["Color"])
        links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
        mat.use_backface_culling = True
    return mat


def attach_clip(armature, filename, name, scale):
    old_objects = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(filename))
    imported = set(bpy.data.objects) - old_objects
    source_arm = next(o for o in imported if o.type == "ARMATURE")
    if set(source_arm.data.bones.keys()) != set(armature.data.bones.keys()):
        raise ValueError(f"{filename.name}: skeleton differs; download on the same Mixamo character")
    # Mixamo's Without Skin downloads can have different rest transforms even
    # on the same character. Bake source joint rotations into the target's bind
    # basis rather than blindly copying f-curves (which twists fingers/feet).
    source_action = source_arm.animation_data.action
    first, last = source_action.frame_range
    action = bpy.data.actions.new(name)
    armature.animation_data.action = action
    hips = next(b for b in source_arm.pose.bones if b.name.endswith(":Hips"))
    bpy.context.scene.frame_set(int(first))
    start = source_arm.matrix_world @ hips.head
    bpy.context.scene.frame_set(int(last))
    finish = source_arm.matrix_world @ hips.head
    displacement = finish - start
    displacement.z = 0
    duration = (last - first) / bpy.context.scene.render.fps
    speed = displacement.length * scale / duration if duration else 0
    rest = {}
    for bone in armature.data.bones:
        source_bone = source_arm.data.bones[bone.name]
        if (bone.parent.name if bone.parent else None) != (source_bone.parent.name if source_bone.parent else None):
            raise ValueError(f"{filename.name}: hierarchy differs at {bone.name}")
        local = bone.parent.matrix_local.inverted() @ bone.matrix_local if bone.parent else bone.matrix_local
        rest[bone.name] = local.to_quaternion()
    for frame in range(int(first), int(last) + 1):
        bpy.context.scene.frame_set(frame)
        for bone in armature.pose.bones:
            original = source_arm.pose.bones[bone.name]
            parent_rotation = original.parent.matrix.to_quaternion() if original.parent else Quaternion()
            bone.rotation_mode = "QUATERNION"
            bone.rotation_quaternion = rest[bone.name].inverted() @ parent_rotation.inverted() @ original.matrix.to_quaternion()
            bone.location = (0, 0, 0)
            bone.scale = (1, 1, 1)
            if bone.name == hips.name:
                offset = original.head - original.bone.head_local
                horizontal = displacement * (frame - first) / max(1, last - first)
                offset -= source_arm.matrix_world.to_3x3().inverted() @ horizontal
                bone.location = bone.bone.matrix_local.to_3x3().inverted() @ offset
                bone.keyframe_insert("location", frame=frame, group=bone.name)
            bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone.name)
    track = armature.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)
    track.mute = True
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    return {"file": filename.name, "duration": duration, "native_speed": speed,
            "horizontal_travel_removed_m": displacement.length * scale}


def patch_glb(path):
    data = path.read_bytes()
    length = struct.unpack_from("<I", data, 12)[0]
    document = json.loads(data[20:20 + length])
    for image in document.get("images", []):
        image["name"] = "mixamo_" + image.get("name", "texture").lower()
    for mat in document.get("materials", []):
        if mat.get("name") == "Mathieu_Hair":
            mat.update(alphaMode="MASK", alphaCutoff=0.4, doubleSided=True)
    payload = json.dumps(document, separators=(",", ":")).encode()
    payload += b" " * (-len(payload) % 4)
    tail = data[20 + length:]
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, 20 + len(payload) + len(tail))
                     + struct.pack("<I4s", len(payload), b"JSON") + payload + tail)


def main():
    for folder in (WORK / "embedded", OUT, REVIEW):
        folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(SOURCE / "mathieu-tpose.fbx"))
    scene = bpy.context.scene
    scene.render.fps = 30
    armature = next(o for o in scene.objects if o.type == "ARMATURE")
    armature.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    bpy.context.view_layer.update()
    corners = [o.matrix_world @ Vector(v) for o in scene.objects if o.type == "MESH" for v in o.bound_box]
    bottom, top = min(v.z for v in corners), max(v.z for v in corners)
    scale = 1.75 / (top - bottom)
    source_triangles = sum(triangle_count(o) for o in scene.objects if o.type == "MESH")
    for image in bpy.data.images:
        if image.packed_file:
            name = image.filepath.replace("\\", "/").split("/")[-1]
            (WORK / "embedded" / name).write_bytes(image.packed_file.data)
    subprocess.run([os.environ.get("WZ_PYTHON", "python"), str(ROOT / "tools/prepare_mixamo_textures.py")], check=True)
    body, hair = make_material("Mathieu_Body"), make_material("Mathieu_Hair", True)
    counts = {}
    for obj in list(scene.objects):
        if obj.type != "MESH":
            continue
        if obj.name == "Ch08_Eyelashes":
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        if obj.data.shape_keys:
            obj.shape_key_clear()
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        tris = triangle_count(obj)
        if tris > BUDGETS[obj.name]:
            decimate = obj.modifiers.new("BrowserBudget", "DECIMATE")
            decimate.ratio = BUDGETS[obj.name] / tris
            bpy.ops.object.modifier_move_up(modifier=decimate.name)
            bpy.ops.object.modifier_apply(modifier=decimate.name)
        counts[obj.name] = triangle_count(obj)
        hair_mesh = obj.data.materials[0].name == "Ch08_hair"
        tile = 0 if obj.data.materials[0].name == "Ch08_body" else 1
        obj.data.uv_layers.active.name = "UVMap"
        if not hair_mesh:
            for uv in obj.data.uv_layers.active.data:
                u, v = uv.uv
                uv.uv = ((tile + (8 + u * 1008) / 1024) / 2, (8 + v * 1008) / 1024)
        obj.data.materials.clear()
        obj.data.materials.append(hair if hair_mesh else body)
    for name, mat in [("MathieuBody", body), ("MathieuHair", hair)]:
        bpy.ops.object.select_all(action="DESELECT")
        objects = [o for o in scene.objects if o.type == "MESH" and o.data.materials[0] == mat]
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        objects[0].name = name
    armature.animation_data_create()
    clips = {}
    for name, candidates in [("walk", ["Walking.fbx"]), ("idle", ["Idle.fbx", "Breathing Idle.fbx"]),
                             ("run", ["Running.fbx", "Run.fbx"])]:
        filename = next((SOURCE / f for f in candidates if (SOURCE / f).exists()), None)
        if filename:
            clips[name] = attach_clip(armature, filename, name, scale)
    missing = {"idle", "walk", "run"} - clips.keys()
    if missing:
        raise ValueError(f"Missing required Mixamo clips: {sorted(missing)}")
    # Remove unassigned source-import actions so only named runtime clips export.
    for action in list(bpy.data.actions):
        if action.name not in clips:
            bpy.data.actions.remove(action)
    container = bpy.data.objects.new("Mathieu", None)
    scene.collection.objects.link(container)
    for obj in list(scene.objects):
        if obj != container and obj.parent is None:
            matrix = obj.matrix_world.copy()
            obj.parent = container
            obj.matrix_world = matrix
    container.rotation_euler.z = math.pi
    container.scale = (scale,) * 3
    container.location.z = -bottom * scale
    armature.animation_data.action = bpy.data.actions["idle"]
    armature.animation_data.action_slot = bpy.data.actions["idle"].slots[0]
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK / "mathieu.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT / "mathieu.glb"), export_format="GLB",
                             export_animations=True, export_animation_mode="ACTIONS",
                             export_skins=True, export_morph=False, export_yup=True)
    patch_glb(OUT / "mathieu.glb")
    report = {"source": "User-supplied Mixamo Ch08 character", "source_triangles": source_triangles,
              "runtime_triangles": sum(counts.values()), "components": counts, "materials": 2,
              "height_m": 1.75, "bones": len(armature.data.bones), "clips": clips,
              "sources": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.glob("*.fbx")}}
    (REVIEW / "conversion.json").write_text(json.dumps(report, indent=2))
    (OUT / "animation_info.json").write_text(json.dumps(clips, indent=2))
    (OUT / "animation_info.tres").write_text(
        '[gd_resource type="Resource" format=3]\n\n[resource]\n'
        f'metadata/walk_speed = {clips["walk"]["native_speed"]:.6f}\n'
        f'metadata/run_speed = {clips.get("run", {}).get("native_speed", 0):.6f}\n'
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
