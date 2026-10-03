# ADR-006: Stalker simulated on the room graph

**Context.** GDD §5.1. A fully simulated 3D stalker in unloaded rooms is expensive and fights fixed-camera framing.

**Decision.** Off-screen, the Man in White is a position on the graph of rooms and exits, advanced by `StalkerDirector`. He's spawned in 3D only when he's in, or entering, the player's room, always after at least 3 s of telegraphing (rule R9). Noise travels in graph hops.

**Consequences.** Cheap to run and easy to test headlessly. Room access flags (`open/scripted/never`) are enforced in the graph step.
