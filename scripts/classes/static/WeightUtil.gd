class_name WeightUtil

## picks a random key from [param weights] proportional to its float value.
## returns an empty/null-equivalent if weights is empty or all weights are <= 0.
static func weighted_pick(weights: Dictionary) -> Variant:
	var total: float = 0.0
	for w in weights.values():
		total += w
	if total <= 0.0:
		return null
		
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for key in weights:
		cumulative += weights[key]
		if roll < cumulative:
			return key
			
	return weights.keys().back() # float rounding fallback
