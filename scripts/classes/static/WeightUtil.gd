class_name WeightUtil

## Returns the index chosen by weight, or -1 if no weight is positive.
static func pick_index(rng: RandomNumberGenerator, weights: PackedFloat32Array) -> int:
	var total: float = 0.0
	for i in weights.size():
		total += maxf(weights[i], 0.0)
	if total <= 0.0:
		return -1
 
	var roll: float = rng.randf() * total
	var cursor: float = 0.0
	var last: int = -1
	for i in weights.size():
		var w: float = maxf(weights[i], 0.0)
		if w <= 0.0:
			continue
		cursor += w
		last = i
		if roll < cursor:
			return i
	return last # roll landed exactly on the upper edge
