extends Node
# AUTOLOAD AS WaveManager

const SPAWN_TRIES: int = 100

var max_waves: int
var current_wave: int = -1

var _config: WaveBoardConfig
var _alive_entities: Array[Entity] = []
var _creatures_spawned_this_wave: int = 0
var _wave_active: bool = false

signal wave_started(wave_index: int)
signal wave_complete(wave_index: int)
signal all_waves_complete

func configure(config: WaveBoardConfig) -> void:
	_config = config
	max_waves = config.max_waves
	current_wave = -1
	_alive_entities.clear()
	_creatures_spawned_this_wave = 0
	_wave_active = false

func start_next_wave() -> void:
	if not _config:
		Log.error("configure() must be called before start_next_wave()")
		return
	if current_wave + 1 >= max_waves:
		all_waves_complete.emit()
		return
	current_wave += 1
	_spawn_wave(current_wave)

func get_spawn_position() -> Vector2i:
	for i in range(SPAWN_TRIES):
		var pos = Vector2i(randi_range(0, WorldGrid.width - 1), randi_range(0, WorldGrid.height - 1))
		if WorldGrid.get_cell(pos).type.terrain == CellType.TerrainType.GROUND:
			return pos
	Log.warn("Could not find safe position, spawning at world center!")
	return WorldGrid.get_center()

func _spawn_wave(wave_index: int) -> void:
	_alive_entities.clear()
	_creatures_spawned_this_wave = 0

	var budget: int = _config.get_point_budget(wave_index)
	var spawn_list: Array[StringName] = _config.build_spawn_list(budget)

	for entity_name in spawn_list:
		#randomize()
		var pos: Vector2 = _config.get_spawn_position()
		#pos = Vector2i(randi_range(0, WorldGrid.width), randi_range(0, WorldGrid.height))
		var entity: Entity = EntityManager.spawn_safely(entity_name, WorldGrid.tile_to_world(pos))
		if entity:
			_track_entity(entity)

	if _alive_entities.is_empty():
		# budget too small to afford anything — don't leave the wave stuck forever
		push_warning("WaveManager: wave %d spawned zero creatures, completing immediately" % wave_index)
		wave_complete.emit(wave_index)
		return

	_wave_active = true
	wave_started.emit(wave_index)

func _track_entity(entity: Entity) -> void:
	_creatures_spawned_this_wave += 1
	_alive_entities.append(entity)
	entity.tree_exiting.connect(_on_tracked_entity_died.bind(entity), CONNECT_ONE_SHOT)

func _on_tracked_entity_died(entity: Entity) -> void:
	if not _wave_active:
		return
	_alive_entities.erase(entity)
	if _alive_entities.is_empty():
		_wave_active = false
		wave_complete.emit(current_wave)

func get_creatures_alive_count() -> int:
	return _alive_entities.size()

func get_creatures_spawned_count() -> int:
	return _creatures_spawned_this_wave

func is_wave_active() -> bool:
	return _wave_active
