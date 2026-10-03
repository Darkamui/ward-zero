# ADR-004: A memory variant is a state of the same room scene

**Context.** GDD §9.3 step 7: memory variants share geometry and cameras with the present-day room; only renders, props and lighting differ. GDD §9.2 lists a "memory variant scene" field.

**Decision.** No separate scene. A room switches timeline by swapping each camera's background to `CameraDef.memory_background`, toggling nodes in the `present_only` / `memory_only` groups, and swapping ambience. `GameState.memory` holds the current timeline.

**Consequences.** Proxies, navmesh, camera triggers and spawns are shared automatically, halving scene maintenance. A memory variant that needs different walkable space toggles collision bodies through the same groups.
