class_name LevelGenerator extends Resource
@export var theme_set: LevelThemeSet
@export var world_size_range: Vector2i = Vector2i(8, 32)

func generate_level(level_value: int, escalation: int) -> LevelDefinition:
	var rng: RandomNumberGenerator = RunRng.get_stream("level_theme_%d" % level_value)
	var theme: LevelTheme = theme_set.pick(rng)
	
	var def: LevelDefinition = LevelDefinition.new()
	def.terrain_generator = theme.terrain_generator
	def.ground_type = theme.ground_type
	def.soft_wall_type = theme.soft_wall_type
	def.wall_type = theme.wall_type
	def.indestructible_type = theme.indestructible_type
	def.pool_sequences = {}
	for pool_id: StringName in theme.pool_generators:
		var seq: WaveSequence = WaveSequence.new()
		seq.generator = theme.pool_generators[pool_id]
		seq.endless = true
		def.pool_sequences[pool_id] = seq
	return def
	
