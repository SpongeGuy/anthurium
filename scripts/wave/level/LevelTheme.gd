class_name LevelTheme extends Resource
@export var theme_name: StringName
@export var weight: float = 1.0
@export var terrain_generator: TerrainGenerator
@export var ground_type: StringName
@export var soft_wall_type: StringName
@export var wall_type: StringName
@export var indestructible_type: StringName
@export var pool_generators: Dictionary[StringName, WaveGenerator]
@export var level_modifiers: Array[Resource] = []
