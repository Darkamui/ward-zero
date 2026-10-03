extends Node
## Hidden composure meter driving post-processing, audio and hallucinations (GDD §5.4).
## M2. Rule R2: never touches nodes in the "puzzle_critical" group.

enum Band { STEADY, SHAKEN, BREAKING }

const PUZZLE_CRITICAL_GROUP := &"puzzle_critical"
const SHAKEN_BELOW := 0.66
const BREAKING_BELOW := 0.33


func band() -> Band:
	if GameState.composure < BREAKING_BELOW:
		return Band.BREAKING
	if GameState.composure < SHAKEN_BELOW:
		return Band.SHAKEN
	return Band.STEADY
