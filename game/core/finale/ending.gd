class_name Ending
extends RefCounted
## The three endings (GDD §2.4). P21's score (fragments placed correctly) and the choice
## in Ward Zero decide which one plays.

const RELAPSE := "relapse"
const DISCHARGE := "discharge"
const CLAIRE := "claire"
const DISCHARGE_SCORE := 9
const FULL_SCORE := 12


## `stayed`: the player let him reach them in Ward Zero instead of taking the exit.
static func compute(score: int, stayed: bool) -> String:
	if stayed:
		return CLAIRE if score >= FULL_SCORE else RELAPSE
	return DISCHARGE if score >= DISCHARGE_SCORE else RELAPSE
