class_name LevelThemeSet extends Resource
@export var themes: Array[LevelTheme] = []

func pick(rng: RandomNumberGenerator) -> LevelTheme:
	var total_weight: float = 0.0
	for t in themes:
		total_weight += t.weight
	var roll: float = rng.randf() * total_weight
	var cursor: float = 0.0
	for t in themes:
		cursor += t.weight
		if roll <= cursor:
			return t
	return themes[-1]
