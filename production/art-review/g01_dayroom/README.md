# G01 Dayroom — integrated environment pass

Both cameras and their released-chain variants are installed in `game/rooms/g01_dayroom/bg/`. Full-resolution review images are `cam_a.png`, `cam_b.png` and their `_released.png` variants. The material-free `proxy.glb` contains detailed visual occluders. The editable scene is `art-src/g01_dayroom/dayroom.blend`, with downloaded textures packed into it.

## Art and sourcing

Faded sage paint, cracked cream plaster, grey-green linoleum, dark wood, cold south-window light and a warm recorder lamp follow the supplied Dayroom concept. The playable 9×7 metre layout remains more open than that concept. North exit, column, cameras, spawns and interaction anchors retain their existing positions.

The foreground chair is the ready-made **Painted Wooden Chair 01** by Kuutti Siitonen / Poly Haven (CC0), replacing the basic chair. It retains its source texture maps and is scaled uniformly to fit the existing footprint. **Peeling Painted Wall** by Dimitrios Savva / Poly Haven (CC0) supplies the paint damage. Two side tables, effects bin, radio and dictaphone reuse the supplied project kit. The radio now faces west toward the player. Other room details and shared materials are in the builder. No AI paintover is used.

Source links, licences, download URLs and checksums are in [credits](../../credits.md), `material-sources.json` and `prop-sources.json`. Prefer suitable library assets for future props rather than recreating them unnecessarily.

## Runtime geometry

The existing furniture/column boxes are named `col_*`: invisible collision/navigation footprints. Detailed meshes from the same evaluated Blender geometry used for rendering are named `vis_*`: background-sampling visual occluders with no collision bodies. This preserves walkability while allowing the player to appear through chair and table gaps. The floor retains its original shadow/collision proxy.

The new `vis_` convention is handled by `ProxyProcessor` and documented in the background pipeline. Both camera light rigs use the south-window direction, a cool fill and a warm recorder light for the live placeholder character. Lighting remains an approximation of the baked area lights.

## Door-chain states

The locked chain spans two frame anchors. After the radio sets `g01.chain_released`, it hangs from the left anchor with the open padlock at the sill. The door remains closed until the existing room transition runs. These are rendered states, not a falling-chain animation. Camera A shows the change clearly; camera B retains the pillar's natural occlusion of most of the door.

The two `CameraDef` resources select their `state_background` when `state_flag` is true. `CameraDirector` refreshes the shared backdrop/proxy sampler immediately when that flag changes or save data is restored. Camera cuts and room reentry also resolve the saved flag. A memory background, where configured, still takes precedence.

The Blender source keeps `CHAIN_LOCKED` and `CHAIN_RELEASED` in separate collections. Both use the same cameras, lighting and render seed. Common door/frame geometry supplies occlusion: the chains are against that geometry behind the player collision boundary, so they need no movable collision or separate runtime proxy. The old baked chain was removed from the common visual proxy during the rebuild.

## Rebuild

From the project root, with Blender 5.2, Python and Pillow:

```powershell
python tools/blender/fetch_dayroom_materials.py
& tools/blender/fetch_dayroom_props.ps1
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/blender/build_dayroom.py
python tools/blender/package_dayroom.py --install
godot --headless --editor --import --quit
```

`-- --draft --camera cam_b` produces quick second-camera drafts of both chain states without overwriting the runtime proxy. Full builds render both cameras in both states at 1920×1080 using Cycles/160 samples/AgX and export the matching common proxy. The builder refuses to reset an interactive Blender session. Source files stay in ignored `art-src/`; Godot is prevented from importing them by `.gdignore`.

`render-manifest.json` records the exact source-scene hash and camera matrices. `proxy-manifest.json` records mesh counts. `projection-reference.json` records camera projections of sampled geometry. The packaging command checks dimensions and source-scene identity, encodes quality-82 WebP and installs it only with `--install`. It associates runtime validation with the exact background/proxy hashes to avoid accepting stale screenshots.

## Validation

- G01 integration tests: **11 passed**, including every hotspot reachable from both spawns, camera hysteresis, walking across the cut, separate visual/collision meshes, the radio reward selecting both chain states without a camera cut, and saved-state restore/room reentry/new-game reset.
- Act 1 critical-path integration tests: **4 passed**.
- GPU smoke run on Godot 4.7.2 / OpenGL compatibility: **13 screenshots**, both cameras, both chain states, furniture screenshots, debug proxy overlays and a walk to the door with exactly one camera cut. See `runtime/validation.json` and the accompanying PNGs. Compare [locked](runtime/cam_a_chain_locked.png) and [released](runtime/cam_a_chain_released.png).
- Sampled Blender/Godot camera projection discrepancy: **0.0003 pixels**, below the 2-pixel pipeline tolerance.
- Changed GDScript passes the pinned gdtoolkit format/lint checks.

The headless baseline already emitted shutdown resource-leak warnings before integration. The same cleanup warnings remain; they are separate from the passing assertions. These checks do not constitute a browser performance or export-size certification.

## Remaining asset work

Radio close-up artwork and controls are integrated; its sound remains queued. Items, readable documents and shared UI are the next asset groups. Mathieu remains a capsule until the character asset pass. See [the focused queue](../../g01_asset_progress.md).
