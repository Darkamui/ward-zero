"""Export evaluated render geometry as material-free, visual-only Godot proxies."""
import json

import bpy
from bpy_extras.object_utils import world_to_camera_view


def write_projection_reference(root, meshes):
    references = {}
    for name in ("cam_a", "cam_b"):
        camera = bpy.data.objects[name]
        samples = []
        for obj in meshes:
            vertices = obj.data.vertices
            for i in range(0, len(vertices), max(1, len(vertices)//12)):
                world = obj.matrix_world @ vertices[i].co
                uv = world_to_camera_view(bpy.context.scene, camera, world)
                if uv.z > 0 and 0 < uv.x < 1 and 0 < uv.y < 1:
                    samples.append(dict(mesh=obj.name, world=[world.x,world.z,-world.y],
                                        pixel=[uv.x*1920,(1-uv.y)*1080]))
        references[name] = samples
    (root / "production/art-review/g01_dayroom/projection-reference.json").write_text(
        json.dumps(references, indent=2)+"\n", encoding="utf-8")


def export_proxy(root, collections):
    proxy = bpy.data.collections.new("PROXY")
    bpy.context.scene.collection.children.link(proxy)
    # Walls lie outside player movement. The floor retains its existing shadow mesh.
    # Include every opaque furniture part, plus small dressing that could overlap a player.
    # CHAIN_LOCKED/CHAIN_RELEASED stay out: both sit against the closed door/frame,
    # behind the walkable boundary, whose common geometry supplies their occlusion.
    skip = ("art_wall_", "art_dado_", "art_skirt_", "art_ceiling", "art_floor_",
            "art_south_", "art_window_", "art_north_cornice", "art_west_cornice", "floor_")
    groups = {}
    graph = bpy.context.evaluated_depsgraph_get()
    for obj in list(collections["ART"].objects):
        if obj.type not in ("MESH", "CURVE") or obj.name.startswith(skip):
            continue
        group = "details"
        for prefix in ("pillar", "chair", "couch", "table_radio", "table_recorder", "bin"):
            if obj.name.startswith("occ_"+prefix):
                group = prefix
                break
        evaluated = obj.evaluated_get(graph)
        mesh = bpy.data.meshes.new_from_object(evaluated, depsgraph=graph)
        mesh.materials.clear()
        clone = bpy.data.objects.new("proxy_part", mesh)
        proxy.objects.link(clone)
        clone.matrix_world = obj.matrix_world.copy()
        groups.setdefault(group, []).append(clone)
    merged = []
    counts = {}
    for group, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = "vis_"+group
        obj.data.name = obj.name
        obj.data.calc_loop_triangles()
        counts[obj.name] = len(obj.data.loop_triangles)
        merged.append(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in merged:
        obj.select_set(True)
    path = root / "game/rooms/g01_dayroom/proxy.glb"
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                             export_materials="NONE", export_cameras=False,
                             export_animations=False, export_texcoords=False,
                             export_normals=True, export_yup=True)
    write_projection_reference(root, merged)
    # Exported proxies must never appear in the beauty render.
    proxy.hide_render = True
    proxy.hide_viewport = True
    (root / "production/art-review/g01_dayroom/proxy-manifest.json").write_text(
        json.dumps(dict(path=str(path.relative_to(root)), triangles=counts,
                        total_triangles=sum(counts.values()),
                        collision="Existing room col_ boxes; vis_ meshes have no collision"), indent=2)+"\n",
        encoding="utf-8")
