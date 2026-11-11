class_name SpawnDirector

## continuously spawns entities for one level. every few seconds it picks 1-3 entities by weight, as long as the entity cap isnt reached.
## call [method start] when the level begins and [method process] every simulation frame.

signal entity_spawned(entity: Entity)

var config: SpawnDirectorConfig
var level: LevelDefinition
var level_value: int
var max_entities: int
var elapsed: float = 0.0

var _running: bool = false
var _next_spawn_timer: float = 0.0
## director spawned entities, including ones still waiting inside a portal.
## untyped on purpose (holds freed instances until the next prune)
var _tracked: Array = []
var _timing_rng: RandomNumberGenerator
var _pick_rng: RandomNumberGenerator
var _modifier_rng: RandomNumberGenerator
var _warned_empty: bool = false


func _init(p_config: SpawnDirectorConfig, p_level: LevelDefinition, p_level_value: int, ground_tile_count: int, rng_stream_key: String) -> void:
	config = p_config
	level = p_level
	level_value = p_level_value
	max_entities = config.max_entities_for(ground_tile_count, level_value)
	# separate streams so tuning one system does not reshuffle the others
	_timing_rng = RunRng.get_stream("%s_timing" % rng_stream_key)
	_pick_rng = RunRng.get_stream("%s_pick" % rng_stream_key)
	_modifier_rng = RunRng.get_stream("%s_mods" % rng_stream_key)

func start() -> void:
	_running = true
	_queue_next_spawn()

func stop() -> void:
	_running = false
	
	
## difficulty driver: time in this level plus the level number
func escalation() -> float:
	return elapsed / maxf(config.seconds_per_escalation, 0.001) + level_value

func alive_count() -> int:
	_prune()
	return _tracked.size()

func process(delta: float) -> void:
	if not _running:
		return
	elapsed += delta
	_next_spawn_timer -= delta
	if _next_spawn_timer > 0.0:
		return
	_queue_next_spawn()
	_spawn_batch()


func _queue_next_spawn() -> void:
	_next_spawn_timer = _timing_rng.randi_range(config.batch_range.x, config.batch_range.y)

func _spawn_batch() -> void:
	_prune()
	var picks: int = _timing_rng.randi_range(config.batch_range.x, config.batch_range.y)
	for i in picks:
		if _tracked.size() >= max_entities:
			return
		_spawn_one()

func _spawn_one() -> void:
	var esc: float = escalation()
	var entry: SpawnEntry = config.spawn_table.pick(_pick_rng, esc, level.tag_weight_multipliers)
	if entry == null:
		if not _warned_empty:
			_warned_empty = true
			Log.warn("no entity has spawn weight at escalation %.lf (check unlock_at values and tag multipliers)" % esc)
		return
	
	var request: SpawnRequest = SpawnRequest.new()
	request.entity_type = entry.entity_type
	request.tags = entry.tags
	_apply_modifiers(request, esc)
	# modifiers may raise count; never overshoot the cap
	request.count = mini(request.count, max_entities - _tracked.size())
	if request.count <= 0:
		return
	
	var portal: Entity = EntityManager.create_entity(&"portal")
	if portal == null:
		return
	EntityManager.spawn_entity_at_tile(portal, WorldGrid.random_spawn_tile(RunRng.get_stream(&"dungeon")), request.z)
 
	var p_component: PortalComponent = portal.get_component(PortalComponent)
	if p_component == null:
		Log.error("Spawned portal has no PortalComponent.")
		return
 
	for i in request.count:
		var e: Entity = EntityManager.create_entity(request.entity_type)
		if e == null:
			continue
		for effect in request.status_effects:
			e.apply_status(effect)
		p_component.add_entity(e)
		_tracked.append(e)
		entity_spawned.emit(e)

func _apply_modifiers(request: SpawnRequest, esc: float) -> void:
	for m in config.modifiers:
		if m == null or m.modifier == null:
			continue
		if not m.applies_to(request.tags):
			continue
		var chance: float = m.chance_at(esc)
		if chance > 0 and _modifier_rng.randf() < chance:
			m.modifier.apply(request)
		

func _prune() -> void:
	for i in range(_tracked.size() -1, -1, -1):
		if not _is_alive(_tracked[i]):
			_tracked.remove_at(i)


## the one place that decides "does this entity still count toward the cap"[br]
func _is_alive(e) -> bool:
	if not is_instance_valid(e):
		return false
	if e is Node and e.is_queued_for_deletion():
		return false
	return true
