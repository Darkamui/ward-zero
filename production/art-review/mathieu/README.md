# Mathieu — supplied Mixamo character

The user replaced the Survival candidate with `mathieu-tpose.fbx` (Mixamo Ch08),
`Walking.fbx`, `Breathing Idle.fbx`, and `Running.fbx`. The runtime model and all
three locomotion clips now use those files. No Survival mesh or procedural gait
remains in the player scene. The Man in White is unchanged.

## Preparation

- 56,258 source triangles reduced to **23,797**, including masked hair/beard.
- Two skinned surfaces/materials; 65-bone skeleton retained.
- Body/clothing atlas: 2048 x 1024, hair: 1024 x 1024. Embedded diffuse/normal/
  gloss maps preserved; glossiness converted to roughness. Texture imports enable
  mipmaps for stable sampling at fixed-camera distances.
- Normalized to 1.75 m with feet at the origin and forward along Godot -Z.
- Without-skin clips have different bind transforms. Rotations are baked into
  the actual character's bind basis, preserving target bone lengths.
- Horizontal travel removed; vertical bob and side-to-side motion retained.
- Controller speed drives clip cadence: 1.6 m/s walk and 3.6 m/s run. The source
  clips measure about 1.664 and 4.425 m/s after character normalization.
- Idle/walk/run loop and crossfade over 0.15 seconds. Existing navigation,
  collision, hiding and room lighting/occlusion remain authoritative.

`conversion.json` records source hashes and the measured conversion results.
The supplied FBXs and Blender intermediates remain local, outside versioned
runtime assets. Rebuild with Blender 5.2:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' -b --python tools/blender/prepare_mixamo_mathieu.py
```

System Python needs Pillow; `WZ_PYTHON` can select its executable. Reimport the
project in Godot after rebuilding. The converter picks up Idle/Breathing Idle
and Running/Run files automatically.

## Review and verification

- `tools/smoke/mathieu_preview.gd`: rendered idle/walk/run asset previews.
- `tools/smoke/mathieu_gameplay.gd`: actual walking/running, arrival to idle,
  fixed-camera transition and pillar occlusion captures.
- `tests/integration/test_mathieu.gd`: imported skin/budget, animation switching,
  actual leg motion and horizontal root-travel regression checks.
- Review PNGs are local, ignored outputs. Run smoke scripts through
  `res://tools/run_tool.tscn -- res://tools/smoke/<script>.gd` with rendering enabled.

Verification uses the installed Godot 4.7.1 Compatibility renderer. The README
pins 4.7.2, which is not installed here. Existing CameraDirector allocates an
unparented backdrop on startup; test/preview shutdown logs report that orphaned
mesh/material/shader. Functional pass/fail checks are recorded separately.

Results: **3 character integration tests passed; 15 existing G01 tests passed;
gameplay smoke passed all movement/camera checks; changed GDScript passes lint.**

Remaining work: interaction-specific clips (reaching/picking up), more detailed
foot-contact polishing, and the separate orderly character. The provided model
wears a light tracksuit; its appearance has not been changed to the earlier
olive-overshirt reference.
