class_name LevelDefinition extends Resource

@export var terrain_generator: TerrainGenerator
@export var ground_type: StringName
@export var soft_wall_type: StringName
@export var wall_type: StringName
@export var indestructible_type: StringName
@export var pool_sequences: Dictionary[StringName, WaveSequence] = {}
