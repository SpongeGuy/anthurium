extends Node
# GameInterface autoload
##
## Orchestrates the game world and its levels: level generation, terrain, spawning, the flower quest,
## and getting players into / between levels. Sits directly below AppController and above
## EntityManager / PlayerManager / TerrainManager / WorldGrid.
##
## Rules:
##  - Never calls AppController or UiController. It reports through signals instead.
##  - Players become players ONLY through [method spawn_player] -> PlayerManager.bind_entity().


## Emitted once the new level's terrain exists (UI uses this to refresh level text).
signal level_loaded(level: int)
## A player's spawn animation started / finished.
signal player_spawn_started(slot: int)
signal player_spawned(slot: int, entity: Entity)
## Emitted when a gate transition has finished and the new level is live.
signal transition_finished
 
const MAIN_POOL: StringName = &"main"
const SPAWN_FX_TIME: float = 2.5
const WARP_FX_TIME: float = 1.0

var active_spawn_cfg: SpawnDirectorConfig
var active_level_gen: LevelGenerator
var spawn_directors: Dictionary[StringName, SpawnDirector] = {}

var current_level: int = 0
var time: float = 0.0
var run_active: bool = false
var background_mode: bool = true
var process_paused: bool = true
 
## Where spawn/warp sprites are parented. Registered by AppController when the world is built.
var effects_container: Node
 
var _carried_players: Dictionary[int, Entity] = {}
var _transitioning: bool = false


func _process(delta: float) -> void:
	if process_paused:
		return
	for d: SpawnDirector in spawn_directors.values():
		d.process(delta)
	_tick_flower_quest_runtime(delta)
	if run_active:
		time += delta
 
func register_effects_container(node: Node) -> void:
	effects_container = node



# ----------------------------------------------
# runs and levels
# ----------------------------------------------
 
## A "run" is a sequence of levels that play one after another.
## Needs [member active_level_gen] and [member active_spawn_cfg] (set by AppController.switch_game_mode).
func start_new_run(at_level: int, seed: int) -> void:
	if run_active:
		finish_run()
	run_active = true
	time = 0.0
	current_level = at_level
	PlayerManager.reset_run_records()
	RunRng.start_run(seed)
	if not EventBus.gate_activated.is_connected(_on_gate_activated):
		EventBus.gate_activated.connect(_on_gate_activated)
	start_level(current_level)



func start_daily_run() -> void:
	start_new_run(0, daily_seed())
 
func daily_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system(true) # utc so it's global
	return d.year * 10000 + d.month * 100 + d.day
 
func finish_run() -> void:
	run_active = false
	if EventBus.gate_activated.is_connected(_on_gate_activated):
		EventBus.gate_activated.disconnect(_on_gate_activated)


## Builds level [param value]. Gameplay processing is paused while it builds.
func start_level(value: int) -> void:
	process_paused = true
	current_level = value
	_teardown_current_level()
	reset_flower_quest()
	RunRng.start_level(current_level)
 
	if not active_level_gen or not active_spawn_cfg:
		Log.error("Game mode not set properly! See AppController to fix issue.", true)
		return
 
	var level_def: LevelDefinition = active_level_gen.generate_level(current_level)
	_reset_world_for_new_level(level_def)
 
	var ground_tile_count: int = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND).size()
	_create_new_spawn_director(MAIN_POOL, level_def, current_level, ground_tile_count)
	EntityManager.simple_spawn_tile("key", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))
	spawn_flowers()
	process_paused = false
 
func start_debug_platform() -> void:
	run_active = true
	time = 0.0
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
	_reset_world_for_new_level(l)
 
func _reset_world_for_new_level(level_def: LevelDefinition) -> void:
	EntityManager.destroy_all_entities()
	CameraController.target = null
	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % current_level)
	WorldGrid.init_grid(level_rng.randi_range(level_def.world_size_range.x, level_def.world_size_range.y), level_rng.randi_range(level_def.world_size_range.x, level_def.world_size_range.y))
	TerrainManager.generate(level_def.terrain_generator, level_rng, level_def.ground_type, level_def.wall_type, level_def.indestructible_type, level_def.soft_wall_type)
	WorldGrid.hide_map()
	level_loaded.emit(current_level)
 
func _teardown_current_level() -> void:
	spawn_directors.clear()
	EntityManager.destroy_all_entities()
 
func _create_new_spawn_director(id: StringName, l_def: LevelDefinition, l_value: int, n_ground_tiles: int) -> void:
	var director: SpawnDirector = SpawnDirector.new(active_spawn_cfg, l_def, l_value, n_ground_tiles, "level_%d_%s" % [current_level, id])
	spawn_directors[id] = director
	director.start()





# ----------------------------------------------
# players
# ----------------------------------------------
 
## Spawns the player for [param slot] with the "fly in from offscreen" animation, then hands the
## entity to PlayerManager. If the slot has a carried entity (level transition), that entity is
## reused and [param entity_id] is ignored.
## Safe to call mid-run for late joiners; waits out any level transition in progress.
func spawn_player(slot: int, entity_id: StringName = &"") -> void:
	while _transitioning and not _carried_players.has(slot):
		await transition_finished
 
	var carried: Entity = _carried_players.get(slot)
	var id: StringName = carried.basename if carried else entity_id
	var tile: Vector2i = WorldGrid.random_spawn_tile(RunRng.get_stream("players"))
	var world_pos: Vector2 = WorldGrid.tile_to_world(tile)
 
	player_spawn_started.emit(slot)
	WorldGrid.reveal_from(tile)
	var fx: ScriptableSprite = ScriptableSprite.new(id, world_pos, SpatialUtil.get_random_offscreen_position(CameraController.camera), SPAWN_FX_TIME, 0)
	effects_container.add_child(fx)
	if PlayerManager.slots.is_empty():
		CameraController.go_instantly_to(world_pos) # first player in snaps the camera; late joiners must not yank it
	await fx.finished_animating
 
	# the player may have unplugged / been removed while the animation played
	if PlayerManager.slot_states.get(slot) != PlayerManager.SlotState.PLAYING:
		_carried_players.erase(slot)
		if is_instance_valid(carried):
			carried.queue_free()
		return
 
	var e: Entity = carried if carried else EntityManager.create_entity(id)
	_carried_players.erase(slot)
	EntityManager.spawn_entity_at_tile(e, tile, 1, true)
	PlayerManager.bind_entity(slot, e)
	player_spawned.emit(slot, e)
 
func _on_gate_activated(position: Vector2) -> void:
	if _transitioning:
		return
	_transitioning = true
	_carried_players.clear()
	for slot in PlayerManager.slots.keys():
		var e: Entity = PlayerManager.unbind_entity(slot) # stops input polling into a detached entity
		if e == null:
			continue
		_carried_players[slot] = e
		_warp_out(e, position)
	await get_tree().create_timer(WARP_FX_TIME).timeout
	start_level(current_level + 1)
	for slot in _carried_players.keys():
		spawn_player(slot) # not awaited on purpose: all carried players fly in together
	_transitioning = false
	transition_finished.emit()
 
## Visual only: spins the entity toward the gate, then detaches it so it can be carried over.
func _warp_out(e: Entity, to: Vector2) -> void:
	var fx: ScriptableSprite = ScriptableSprite.new(e.basename, to, e.global_position, WARP_FX_TIME, 1)
	effects_container.add_child(fx)
	EntityManager.detach_entity(e)





# ---------------------------------------------
# FLOWER QUEST
# --------------------------------------------
var total_flowers: int = 0
var current_flowers: int = 0
var flower_quest_complete: bool = false
var flower_quest_ratio: float = 0.1
var flowers: Array[Entity] = []
 
func reset_flower_quest() -> void:
	total_flowers = 0
	current_flowers = 0
	flower_quest_complete = false
	for f in flowers:
		if is_instance_valid(f):
			f.queue_free()
	flowers.clear()
 
func spawn_flowers() -> void:
	var coordinates: Array[Vector2i] = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND)
	for c in coordinates:
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
	if flower_quest_complete or total_flowers == 0:
		return
	if float(current_flowers) / float(total_flowers) <= flower_quest_ratio:
		complete_flower_quest()
 
func complete_flower_quest() -> void:
	flower_quest_complete = true
	EntityManager.simple_spawn_tile("gate", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))


	







