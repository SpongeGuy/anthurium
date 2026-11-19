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

signal run_started
 
const MAIN_POOL: StringName = &"main"
const SPAWN_FX_TIME: float = 2.5
const WARP_FX_TIME: float = 1.0

const SHOP_INTERVAL: int = 5
enum LevelMode { QUEST, ONBOARDING, SHOP }
var current_level_mode: LevelMode = LevelMode.QUEST
var next_level_mode: LevelMode = LevelMode.QUEST



var active_spawn_cfg: SpawnDirectorConfig
var active_level_gen: LevelGenerator
var onboarding_level_gen: LevelGenerator
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

# quest stuff
var quests: Array[Quest]
var _gate_spawned: bool = false







func _process(delta: float) -> void:
	if process_paused:
		return
	for d: SpawnDirector in spawn_directors.values():
		d.process(delta)
	tick_quests(delta)
	if run_active:
		time += delta
 
func register_effects_container(node: Node) -> void:
	effects_container = node

# ----------------------------------------------
# runs and levels
# ----------------------------------------------
 
## A "run" is a sequence of levels that play one after another.
## Needs [member active_level_gen] and [member active_spawn_cfg] (set by AppController.switch_game_mode).
func start_new_run(at_level: int, seed_value: int, first_mode: LevelMode = LevelMode.QUEST) -> void:
	if run_active:
		finish_run()
	run_active = true
	time = 0.0
	current_level = at_level

	next_level_mode = first_mode

	PlayerManager.reset_run_records()
	RunRng.start_run(seed_value)
	run_started.emit()
	if not EventBus.gate_activated.is_connected(_on_gate_activated):
		EventBus.gate_activated.connect(_on_gate_activated)
	
	continue_with_new_board()


func continue_with_new_board() -> void:
	clear_quests()
	current_level_mode = next_level_mode
	# only quest boards advance the level number
	var level: int = current_level + 1 if current_level_mode == LevelMode.QUEST else current_level
	next_level_mode = _mode_after(current_level, level)
	start_level(level, current_level_mode)

func _mode_after(mode: LevelMode, level: int) -> LevelMode:
	if mode == LevelMode.QUEST and level % SHOP_INTERVAL == 0 and level != 0:
		return LevelMode.SHOP
	return LevelMode.QUEST

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
func start_level(value: int, mode: LevelMode) -> void:
	process_paused = true
	current_level = value
	_teardown_current_level()
	_gate_spawned = false
	RunRng.start_level(current_level)
 
 
	# -------- level generator -------------

	var gen: LevelGenerator
	match mode:
		LevelMode.ONBOARDING:
			gen = onboarding_level_gen
		_:
			gen = active_level_gen
	
	if not gen:
		Log.error("Game mode not set properly! See AppController to fix issue; generator must be set there.", true)
		return

	var level_def: LevelDefinition = gen.generate_level(current_level)
	_reset_world_for_new_level(level_def, current_level)
	if level_def.prefab:
		var p: Prefab = level_def.prefab
		var origin: Vector2i = Vector2i((level_def.world_size_x_range.x - p.width) / 2, (level_def.world_size_y_range.x - p.height) / 2)
		p.stamp(origin)
	
	var ground_tile_count: int = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND).size()

	# ---------- level entities ----------------
 
	if mode == LevelMode.QUEST:
		_create_new_spawn_director(MAIN_POOL, level_def, current_level, ground_tile_count)

	# ------------ level definition configuration -------------------

	if level_def.spawn_random_key:
		EntityManager.simple_spawn_tile("key", WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")))
	var ctx: Dictionary = {ground_tile_count = ground_tile_count, level_value = current_level}
	for s in level_def.quest_scripts:
		start_quest(s.new(), ctx)

	process_paused = false


func _reset_world_for_new_level(level_def: LevelDefinition, level: int) -> void:
	EntityManager.destroy_all_entities()
	CameraController.target = null
	var level_rng: RandomNumberGenerator = RunRng.get_stream("level_%d" % level)
	WorldGrid.init_grid(level_rng.randi_range(level_def.world_size_x_range.x, level_def.world_size_x_range.y), level_rng.randi_range(level_def.world_size_y_range.x, level_def.world_size_y_range.y))
	TerrainManager.generate(level_def.terrain_generator, level_rng, level_def.ground_type, level_def.wall_type, level_def.indestructible_type, level_def.soft_wall_type)
	WorldGrid.hide_map()
	CameraController.center_on_arena()
	level_loaded.emit(level)
 
func _teardown_current_level() -> void:
	spawn_directors.clear()
	for q in quests:
		q.shutdown()
	quests.clear()
	EntityManager.destroy_all_entities()
 
func _create_new_spawn_director(id: StringName, l_def: LevelDefinition, l_value: int, n_ground_tiles: int) -> void:
	var director: SpawnDirector = SpawnDirector.new(active_spawn_cfg, l_def, l_value, n_ground_tiles, "level_%d_%s" % [current_level, id])
	spawn_directors[id] = director
	director.start()





 
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

	l.world_size_x_range = Vector2i(40, 40)
	l.world_size_y_range = Vector2i(22, 22)
	_reset_world_for_new_level(l, current_level)
 







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
	var fx: ScriptableSprite = ScriptableSprite.new(id, world_pos, SpatialUtil.get_random_offscreen_position(CameraController.camera, RunRng.get_stream("players")), SPAWN_FX_TIME, 0)
	effects_container.add_child(fx)
	#if PlayerManager.slots.is_empty():
		#CameraController.go_instantly_to(world_pos) # first player in snaps the camera; late joiners must not yank it
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
	e.set_visibility(true)
	player_spawned.emit(slot, e)
 
# gate has been activated, so transport players and start new level
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
	continue_with_new_board()
	for slot in _carried_players.keys():
		spawn_player(slot) # not awaited on purpose: all carried players fly in together
	_transitioning = false
	transition_finished.emit()
 
## Visual only: spins the entity toward the gate, then detaches it so it can be carried over.
func _warp_out(e: Entity, to: Vector2) -> void:
	var fx: ScriptableSprite = ScriptableSprite.new(e.basename, to, e.global_position, WARP_FX_TIME, 1)
	effects_container.add_child(fx)
	EntityManager.detach_entity(e)
	
func spawn_gate(tile: Vector2i = Vector2i(-1, -1)) -> void:
	_gate_spawned = true
	if tile == Vector2i(-1, -1):
		tile = WorldGrid.random_spawn_tile(RunRng.get_stream("dungeon")) 
	EntityManager.simple_spawn_tile("gate", tile)

# --------------------------------------------------------------------------------------
# quest
# -------------------------------------------------------------------------------------



func start_quest(quest: Quest, context: Dictionary) -> void:
	quests.append(quest)
	quest.start(context)
	quest.completed.connect(_on_quest_completed)

func tick_quests(delta: float) -> void:
	for i in range(quests.size() - 1, -1, -1):
	# 	if quests[i].is_complete:
	# 		quests.remove_at(i)
	# 		continue
	#
		quests[i].tick(delta)

func _on_quest_completed(q: Quest) -> void:
	if _gate_spawned:
		return
	match q.get_script():
		GhostQuest, OnboardingQuest:
			if q.result == Quest.QuestResult.SUCCESS:
				spawn_gate()

func clear_quests() -> void:
	for q in quests:
		q.shutdown()
	quests.clear()
