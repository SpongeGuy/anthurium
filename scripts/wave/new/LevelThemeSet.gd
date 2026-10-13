class_name LevelThemeSet extends Resource
@export var themes: Array[LevelTheme] = []

func pick(rng: RandomNumberGenerator) -> LevelTheme:
	var weights: PackedFloat32Array = PackedFloat32Array()
	for t in themes:
		weights.append(t.weight)
	var index: int = WeightUtil.pick_index(rng, weights)
	if index < 0:
		return null
	return themes[index]
