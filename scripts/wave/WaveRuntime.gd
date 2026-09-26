class_name WaveRuntime
extends RefCounted

signal wave_complete
signal entity_spawned(entity: Entity)

var definition: WaveDefinition
var spawned_entities: Array[Entity] = []
var completion: CompletionStrategy

var _remaining_budget: float
var _next_spawn_timer: float = 0.0
var _rng: RandomNumberGenerator
var _exhausted: bool = false # true once nothing affordable remains

func _init(def: WaveDefinition, rng_stream_key: StringName) -> void:
	definition = def
	_remaining_budget = def.point_budget
	completion = def.completion_factory.build()
	completion.completed.connect(_on_completed, CONNECT_ONE_SHOT)
	_rng = RunRng.get_stream(rng_stream_key)

func start() -> void:
	completion.start(self)
	_queue_next_spawn()

func process(delta: float) -> void:
	completion.tick(delta)
	if _exhausted:
		return
	_next_spawn_timer -= delta
	if _next_spawn_timer <= 0.0:
		_spawn_one()
		_queue_next_spawn()

func _queue_next_spawn() -> void:
	_next_spawn_timer = _rng.randf_range(definition.spawn_interval_range.x, definition.spawn_interval_range.y)

func _spawn_one() -> void:
	var entry: EntityPoolEntry = definition.entity_pool.pick_affordable(_rng, _remaining_budget)
	if entry == null:
		_exhausted = true
		return
	_remaining_budget -= entry.cost
	
	var request: SpawnRequest = SpawnRequest.new()
	request.entity_type = entry.entity_type
	for m in definition.spawn_modifiers:
		m.apply(request)
	
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
		spawned_entities.append(e)
		completion.on_entity_tracked(e)
		entity_spawned.emit(e)
	
	if _remaining_budget < definition.entity_pool.cheapest_cost():
		_exhausted = true
	
func _on_completed() -> void:
	wave_complete.emit()
