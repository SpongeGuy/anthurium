class_name LevelDefinition

## IMPORTANT, MIRRORS LevelTheme
## this is a RefCounted that is created by LevelGenerator / LevelTheme, so everything here must match LevelTheme

var terrain_generator: TerrainGenerator
var ground_type: StringName
var soft_wall_type: StringName
var wall_type: StringName
var indestructible_type: StringName
var tag_weight_multipliers: Dictionary[StringName, float] = {}
var world_size_x_range: Vector2i
var world_size_y_range: Vector2i

var quest_scripts: Array[Script] = [GhostQuest, FlowerQuest]
var spawn_random_key: bool = true
var prefab: Prefab
