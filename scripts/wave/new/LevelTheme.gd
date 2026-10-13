class_name LevelTheme extends Resource
## level flavorr[br]
## which terrain algorithms and tile palettes the generator can use and which entity tags it favors.[br]
## the [LevelGenerator] rolls one of each at random

@export var theme_name: StringName
@export var weight: float = 1.0
## one is picked at random (uniformly) per level
@export var terrain_generators: Array[TerrainGenerator]
## one is picked at random (by weight) per level
@export var palettes: Array[TilePalette] = []
@export var world_size_range: Vector2i = Vector2i(8, 32)
## tag -> spawn weight multiplier for entities with that tag. [br]
## 1.0 = unchanged, 0 = never spawns, 3.0 = three times likely. missing tags = 1.0
@export var tag_weight_multipliers: Dictionary[StringName, float] = {}
@export var level_modifiers: Array[Resource] = []


func pick_palette(rng: RandomNumberGenerator) -> TilePalette:
	var weights: PackedFloat32Array = PackedFloat32Array()
	for p in palettes:
		weights.append(p.weight)
	var index: int = WeightUtil.pick_index(rng, weights)
	if index < 0:
		return null
	return palettes[index]

func pick_terrain_generator(rng: RandomNumberGenerator) -> TerrainGenerator:
	if terrain_generators.is_empty():
		return null
	return terrain_generators[rng.randi_range(0, terrain_generators.size() - 1)]
