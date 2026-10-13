class_name LevelGenerator extends Resource
@export var theme_set: LevelThemeSet


## rolls a theme, then a tile palette and a terrain generator from that theme[br]
## returns `null` and logs if the theme set is misconfigured.
func generate_level(level_value: int) -> LevelDefinition:
	var rng: RandomNumberGenerator = RunRng.get_stream("level_theme_%d" % level_value)
	var theme: LevelTheme = theme_set.pick(rng)
	if theme == null:
		Log.error("theme set has no usable themes.", true)
		return null
	
	var palette: TilePalette = theme.pick_palette(rng)
	var terrain: TerrainGenerator = theme.pick_terrain_generator(rng)
	if palette == null or terrain == null:
		Log.error("theme '%s' neesd at least one palette and one terrain generator." % theme.theme_name, true)
		return null
	
	var def: LevelDefinition = LevelDefinition.new()
	def.terrain_generator = terrain
	def.ground_type = palette.ground_type
	def.soft_wall_type = palette.soft_wall_type
	def.wall_type = palette.wall_type
	def.indestructible_type = palette.indestructible_type
	def.tag_weight_multipliers = theme.tag_weight_multipliers # shared, read-only
	def.world_size_range = theme.world_size_range
	return def
	
