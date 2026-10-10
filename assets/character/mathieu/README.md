# Mathieu source files

User-selected Mixamo Ch08 character, replacing the earlier Survival candidate.
Keep downloads here; .gdignore prevents source FBXs from importing or shipping.
These vendor source files are intentionally not versioned.

- `mathieu-tpose.fbx`: character with skin and embedded textures.
- `Walking.fbx`: walking motion (currently also contains skin).
- `Breathing Idle.fbx`: idle animation without skin.
- `Running.fbx`: running animation without skin.

For subsequent downloads, keep this same character selected in Mixamo. Use FBX
Binary, Without Skin, 30 FPS, no keyframe reduction. Use In Place where offered.
The converter also removes net horizontal travel from moving clips.

Rebuild: run `tools/blender/prepare_mixamo_mathieu.py` with Blender in background
mode. System Python with Pillow is required; set WZ_PYTHON if needed.
