# ADR-001: Godot 4.7.2, pinned

**Context.** GDD §9.1 picks Godot 4 (≥ 4.3) for its navmesh, animation, localization, audio buses and editor, and because single-threaded web export (4.3+) runs on any static host without COOP/COEP headers.

**Decision.** Use Godot **4.7.2-stable**, the latest stable at project start, with the Compatibility renderer (WebGL 2) and single-threaded web export. CI downloads exactly this version. Upgrade only between milestones, in a dedicated PR that re-runs every test and the M0 performance checks.

**Consequences.** No Forward+/Mobile-only features (SDFGI, volumetric fog, screen-space post-processing stack); post-processing is a CanvasLayer shader. Measured at Foundation: the release engine is 39.5 MB raw and about 10 MB gzipped, leaving about 30 MB of the 40 MB first-download budget for Act 1.
