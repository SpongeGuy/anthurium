extends Node
# GameInterface autoload

## While [AppController] orchestrates the greater systems of the game (user interface [UIStage]s etc), GameInterface orchestrates the game world and its levels.
## As long as a [member level_sequence] is defined, [method start_new_run] is able to be called safely from [AppController].
## Takes in a [LevelSequence] to pull [LevelDefinition]s for each [member current_level], set in [method start_level].[br]

const MAIN_POOL: StringName = &"main"

var active_spawn_cfg: SpawnDirectorConfig
var active_level_gen: LevelGenerator
var spawn_directors: Dictionary[StringName, SpawnDirector] = {}

var current_level: int = 0
var time: float = 0.0
var run_active: bool = false
## Used in level generation to choose what kind of creatures are spawned. The higher the escalation, the more likely harder/weirder creatures will spawn.

var background_mode: bool = true
var process_paused: bool = true

const SPAWN_FX_TIME: float = 2.5
var _saved_players: Dictionary[int, Entity] = {}
var _transitioning: bool = false


func _process(delta: float) -> void:
	if process_paused:
		return
	for d: SpawnDirector in spawn_directors.values():
		d.process(delta)
	
	_tick_flower_quest_runtime(delta)
	
	if run_active:
		time += delta


## A "run" is essentially just a collection of levels which play one after another.
## This function starts the player at a [param level] with an [member escalation] value of 0.
## If [member level_sequence] is null, this will error within [method start_level].
func start_new_run(at_level: int, seed: int) -> void:
	run_active = true
	time = 0
	current_level = at_level
	RunRng.start_run(seed)
	start_level(current_level)
	EventBus.gate_activated.connect(_on_gate_activated)

func start_daily_run() -> void:
	start_new_run(0, daily_seed())

func daily_seed() -> int:
	# use utc here so its global time
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return d.year * 10000 + d.month * 100 + d.day









func finish_run() -> void:
	run_active = false
	EventBus.gate_activated.disconnect(_on_gate_activated)

## Starts the next level at [param value]. if [member background_mode] is `true`, then this function will also spawn a player entity with a visual effect before doing any processes.
## [member process_paused] is turned on when this function first starts and turned off when the function ends so that the player animation can play.
func start_level(value: int) -> void:
	process_paused = true
	current_level = value
	_teardown_current_level()
	reset_flower_quest()
	RunRng.start_level(current_level)
	
	if not active_level_gen or not active_spawn_cfg:
		Log.error("Game mode not set properly! See AppController to fix issue.", true)
	
	var level_def: LevelDefinition = active_level_gen.generate_level(current_level)
	_reset_appstate_for_new_level(level_def)
	var ground_tile_count: int = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND).size()


	_create_new_spawn_director("main", level_def, current_level, ground_tile_count)
	EntityManager.simple_spawn_tile("key", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))
	spawn_flowers()
		
	process_paused = false






	


## This used to change the camera mode, but i think that the camera mode should only be changed within [AppController]
func spawn_player(slot: int, entity_id: StringName = &"") -> void:
	var carried: Entity = _saved_players.get(slot)
	var id: StringName = carried.basename if carried else entity_id
	
	UiController.hud.set_state(UIHUD.State.INACTIVE)
	var spawn_pos: Vector2i = WorldGrid.random_spawn_tile(RunRng.get_stream("players"))
	WorldGrid.reveal_from(spawn_pos)
	var fx: ScriptableSprite = ScriptableSprite.new(id, WorldGrid.tile_to_world(spawn_pos), SpatialUtil.get_random_offscreen_position(CameraController.camera), 2.5, 0)
	AppController.container_2d.add_child(fx)
	CameraController.go_instantly_to(WorldGrid.tile_to_world(spawn_pos))
	await fx.finished_animating
	
	var e: Entity = carried if carried else EntityManager.create_entity(id)
	_saved_players.erase(slot)
	UiController.hud.set_state(UIHUD.State.BAR)
	EntityManager.spawn_entity_at_tile(e, spawn_pos, 1, true, 0)
	PlayerManager.set_player(slot, e)



func start_debug_platform() -> void:
	run_active = true
	time = 0
	current_level = 0
	RunRng.start_run(0)
	current_level = 1
	_teardown_current_level()
	var l: LevelDefinition = LevelDefinition.new()
	l.ground_type = "ground_castle"
	l.wall_type = "wall_castle"
	l.indestructible_type = "wall_indestructible"
	l.soft_wall_type = "wall_blick_block"
	l.terrain_generator = EmptyTerrainGenerator.new()
	l.world_size_range = Vector2i(40, 22)
	_reset_appstate_for_new_level(l)
	






# ----------------------------------------------
# utility
# ---------------------------------------------

## Spawns in a [ScriptableSprite] of the player and spins them toward the spawn point. Purely a visual effect.
func _sprite_effect_player(slot: int, to: Vector2, from: Vector2, duration: float) -> void:
	UiController.hud.set_state(UIHUD.State.INACTIVE)
	var scriptsprite: ScriptableSprite = ScriptableSprite.new(_saved_players[slot].basename, to, from, duration, 1)
	PlayerManager.slots[slot].entity.queue_free()
	AppController.container_2d.add_child(scriptsprite)
	await scriptsprite.finished_animating


func _reset_appstate_for_new_level(level_def: LevelDefinition) -> void:
	EntityManager.destroy_all_entities()
	CameraController.target = null
	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % current_level)
	WorldGrid.init_grid(level_rng.randi_range(level_def.world_size_range.x, level_def.world_size_range.y), level_rng.randi_range(level_def.world_size_range.x, level_def.world_size_range.y))
	TerrainManager.generate(level_def.terrain_generator, level_rng, level_def.ground_type, level_def.wall_type, level_def.indestructible_type, level_def.soft_wall_type)
	WorldGrid.hide_map()
	UiController.hud.update_level_text()




func _create_new_spawn_director(id: StringName, l_def: LevelDefinition, l_value: int, n_ground_tiles: int) -> void:
	var director: SpawnDirector = SpawnDirector.new(active_spawn_cfg, l_def, l_value, n_ground_tiles, "level_%d_%s" % [current_level, id])
	spawn_directors[id] = director
	director.start()


func _teardown_current_level() -> void:
	spawn_directors.clear()
	EntityManager.destroy_all_entities()







func _on_gate_activated(position: Vector2) -> void:
	if _transitioning:
		return
	_transitioning = true
	_saved_players.clear()
	for slot in PlayerManager.slots.keys():
		var e: Entity = PlayerManager.slots[slot].entity
		_saved_players[slot] = e
		PlayerManager.slots.erase(slot) # stop polling input into a detached entity
		_sprite_effect_player(slot, position, _saved_players[slot].global_position, 1.0)
		EntityManager.detach_entity(e)
	await get_tree().create_timer(1.0).timeout
	await start_level(current_level + 1)
	_transitioning = false


# ---------------------------------------------
# FLOWER QUEST
# --------------------------------------------
var total_flowers: int = 0
var current_flowers: int = 0
var flower_quest_complete: bool = false
var flower_quest_ratio: float = 0.1
var flowers: Array[Entity]

func reset_flower_quest() -> void:
	total_flowers = 0
	current_flowers = 0
	flower_quest_complete = false
	for f in range(flowers.size() - 1, -1, -1):
		flowers[f].queue_free()
	flowers.clear()

func spawn_flowers() -> void:
	var coordinates: Array[Vector2i] = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND)
	for c in coordinates:
		#if SpatialUtil.is_tile_occupied(AppController.world_2d.get_world_2d().direct_space_state, c, SpatialUtil.PhysicsLayers.PLANTS):
			#continue
		var flower: Entity = EntityManager.simple_spawn_tile("collectible_flower", c)
		var comp: FlowerComponent = flower.get_component(FlowerComponent)
		flowers.append(flower)
		current_flowers += 1
		total_flowers += 1
		comp.collected.connect(collect_flower, CONNECT_ONE_SHOT)

func collect_flower(flower: Entity) -> void:
	flowers.erase(flower)
	current_flowers -= 1

func _tick_flower_quest_runtime(_delta: float) -> void:
	if flower_quest_complete:
		return
	if float(current_flowers) / float(total_flowers) <= flower_quest_ratio:
		complete_flower_quest()

func complete_flower_quest() -> void:
	EntityManager.simple_spawn_tile("gate", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))
	flower_quest_complete = true
