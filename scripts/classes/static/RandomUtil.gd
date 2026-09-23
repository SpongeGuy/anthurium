class_name RandomUtil



# -------------------------------------------
# utility functions
# --------------------------------------------

static func randomize_float(rng: RandomNumberGenerator, value: float, offset: float) -> float:
	return value + rng.randf_range(-offset, offset)
	
static func randomize_float_with_personality(rng: RandomNumberGenerator, value: float, offset: float, p_value: float, p_multiplier: float = 1.0) -> float:
	var markiplier: float = p_value * p_multiplier
	return (value + rng.randf_range(-offset, offset)) * markiplier
