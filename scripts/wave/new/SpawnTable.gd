class_name SpawnTable
extends Resource

@export var entries: Array[SpawnEntry] = []


## picks one entry by weight at the given escalation.[br]
## tag_multipliers: tag -> multiplier from the current level (1.0 = unchanged, 0 = never, 3 = triple).[br]
## an entry with several tags gets every matching multiplier applied.
## returns null when nothing has positive weight.
func pick(rng: RandomNumberGenerator, escalation: float, tag_multipliers: Dictionary = {}) -> SpawnEntry:
	var weights: PackedFloat32Array = PackedFloat32Array()
	weights.resize(entries.size())
	for i in entries.size():
		var e: SpawnEntry = entries[i]
		weights[i] = e.weight_at(escalation) * _tag_multiplier(e, tag_multipliers)

	var index: int = WeightUtil.pick_index(rng, weights)
	if index < 0:
		return null
	return entries[index]


func _tag_multiplier(entry: SpawnEntry, tag_multipliers: Dictionary) -> float:
	if tag_multipliers.is_empty():
		return 1.0
	var m: float = 1.0
	for t in entry.tags:
		m *= float(tag_multipliers.get(t, 1.0))
	return m
