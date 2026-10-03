# Background Pipeline

How a room goes from layout to a playable pre-rendered scene. Conventions here are enforced by `ProxyProcessor` and the room tests.

## Two routes, one contract

| Route | Used for | Geometry source | Background source |
|---|---|---|---|
| **Greybox** | Layout, puzzles, pacing (M1 phase B) | `tools/greybox/build_<room>.gd` (code) | `tools/greybox/render_room.gd` clay render in Godot |
| **Final** | Shipping art (M1 phase D onward) | Blender `PROXY` + `CAMS` collections → `proxy.glb` | Blender beauty render → AI paintover → WebP |

Both produce the same room layout, so the game code doesn't care which one made it:

```
<Room id> (Room)
  Geometry      floor_*, occ_*, col_*, shadow_*, art_* meshes (or instanced proxy.glb)
  Navigation    NavigationRegion3D (baked at load)
  Cameras       Camera3D per CameraDef id; each has a LightRig (Key directional + Fill omni)
  Triggers      CameraTrigger boxes (overlap 0.5 m or more between neighbours)
  Spawns        Marker3D spawn_*  (spawn_from_<room id> for each incoming exit)
  Hotspots      Interactable areas, each with an Approach marker on the navmesh
  RenderLights  lights for renders only (hidden in game)
```

## Node prefixes

| Prefix | In game | In renders |
|---|---|---|
| `floor_` | invisible proxy (draws the background), collision `floor`, navmesh source, receives shadow | clay |
| `occ_` | invisible proxy, collision `walls`, hides the character behind it | clay |
| `col_` | hidden, collision `walls` | clay |
| `shadow_` | invisible proxy, shadow only | clay |
| `art_` | hidden | clay |

## Greybox steps

See `tools/greybox/README.md`. In short: `tools/greybox/greybox.sh G01 build_g01 [--memory]`.

## Final art steps

1. **Blender scene.** Meters, +Y forward in Blender = −Z in Godot (glTF handles it). Collections `ART`, `PROXY`, `CAMS`, `LIGHTS`. Name proxies with the prefixes above. Cameras `cam_a…`, sensor fit **Vertical**, 1920×1080, no lens shift.
2. **Match lighting.** The room's game `LightRig/Key` must point the same way as the render's main light, or the character's shadow will disagree with the painted shadows.
3. **Render** one beauty pass per camera at 1920×1080. Keep EXR depth in `art-src/` (only for the depth-shader fallback).
4. **Paintover.** Low strength (record it in `art-src/<room>/paintover.json`). Mask a ~12 px band around every foreground silhouette the character can pass behind. Never add new foreground objects in paintover.
5. **Export** `cwebp -q 82` (tune to 200–400 KB) to `game/rooms/<id>/bg/<cam>.webp`. Memory variants go in `bg_mem/`. Import settings: lossless, no mipmaps, no 3D detection (project default).
6. **Proxy** `PROXY` + `CAMS` → `proxy.glb` in the room folder. Instance it under `Geometry`.
7. **RoomData** `room_data.tres`: one `CameraDef` per camera with `background` (and `memory_background`).
8. **Check:** run the tests (content + reachability), then the occlusion check below.

## Occlusion check (every camera, every room)

1. In game, press **F9**: proxies get a magenta tint.
2. Any offset over 2 px between tint and painted silhouette fails.
3. Walk behind every occluder: no popping, halos or floating feet.
4. Save a half-occluded screenshot per camera to `production/occlusion/<room>_<cam>.png`.

`tools/smoke/m0_screens.gd` automates steps 1 and 4 for G01. Copy it for new rooms.

## How the occlusion works

The current camera's background is a global shader texture (`wz_background`). The backdrop quad behind everything and every proxy mesh sample it at `SCREEN_UV`, so a proxy is invisible but writes depth: the character is hidden wherever a proxy is in front of it. Proxies also take the character's shadow from the rig's directional Key light, through a custom `light()` that only multiplies the background by the shadow term.
