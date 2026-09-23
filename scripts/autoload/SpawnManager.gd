extends Node

const SPAWN_TRIES: int = 200
const MAX_WAVE_SIZE: int = 200

signal wave_started(pool: SpawnPool, wave_index: int)
signal wave_complete(pool: SpawnPool, wave_index: int)
signal all_waves_complete(pool: SpawnPool)

var active_pools: Array[SpawnPool] = []

func create_new_pool(waves: Array[SpawnWave], level: int, pool_seed: int) -> SpawnPool:
	var pool: SpawnPool = SpawnPool.new(waves, level, pool_seed)
	active_pools.append(pool)
	return pool

func clear_pools() -> void:
	for pool in active_pools:
		pool.wave_active = false
	active_pools.clear()

func _process(delta: float) -> void:
	for pool in active_pools:
		if not pool.wave_active:
			continue
		if pool.wave.completion_condition != SpawnWave.CompletionCondition.TIME or pool.wave.completion_condition != SpawnWave.CompletionCondition.REMAINING_OR_TIME:
			continue
		pool.objective_time += delta
		if pool.objective_time >= pool.time_limit:
			_complete_wave(pool)

func start_next_wave(pool: SpawnPool) -> void:
	if pool.waves[pool.current_wave].loop:
		spawn_wave(pool, pool.current_wave)
		return
	if pool.current_wave + 1 >= pool.waves.size():
		all_waves_complete.emit(pool)
		return
	pool.current_wave += 1
	spawn_wave(pool, pool.current_wave)

func spawn_wave(pool: SpawnPool, wave_index: int) -> void:
	Log.debug("Spawning wave %s" % wave_index)
	var wave: SpawnWave = pool.waves[wave_index]
	var lvl: int = pool.level - 1
	pool.wave = wave
	pool.rng.seed = hash([pool.pool_seed, wave_index]) # each wave reproducible on its own
	pool.tracked_entities.clear()
	pool.creatures_spawned_this_wave = 0
	pool.objective_time = 0.0
	pool.boss = null
	pool.completion_ratio = maxf(minf(wave.remaining_limit_ratio, 0.05), wave.remaining_limit_ratio - 0.02 * lvl)
	pool.time_limit = wave.time_limit * maxf(0.5, 1.0 - 0.05 * lvl)
	pool.wave_active = true

	if wave.completion_condition == SpawnWave.CompletionCondition.BOSS:
		pool.boss = _spawn_tracked(pool, wave.boss_id)

	for id in build_spawn_list(wave, get_point_budget(pool, wave), pool.level, pool.rng):
		_spawn_tracked(pool, id)

	wave_started.emit(pool, wave_index)

	# softlock guard: nothing spawned or the boss failed to spawn
	var boss_missing: bool = wave.completion_condition == SpawnWave.CompletionCondition.BOSS and pool.boss == null
	if pool.tracked_entities.is_empty() or boss_missing:
		_complete_wave.call_deferred(pool)

func _spawn_tracked(pool: SpawnPool, id: StringName) -> Entity:
	var tile: Vector2i = get_random_spawn_position(pool.rng)
	var entity: Entity = EntityManager.spawn_safely(id, WorldGrid.tile_to_world(tile))
	if entity == null:
		Log.warn("Failed to spawn %s" % id)
		return null
	pool.creatures_spawned_this_wave += 1
	pool.tracked_entities.append(entity)
	var cb: Callable = _on_tracked_entity_died.bind(pool, entity)
	entity.died.connect(cb, CONNECT_ONE_SHOT)
	entity.tree_exiting.connect(cb, CONNECT_ONE_SHOT) # fallback: freed without dying
	return entity

func _on_tracked_entity_died(pool: SpawnPool, entity: Entity) -> void:
	if not pool.wave_active:
		return
	var idx: int = pool.tracked_entities.find(entity)
	if idx == -1:
		return # already handled, or leftover from an earlier wave
	pool.tracked_entities.remove_at(idx)
	Log.debug("entity died %s" % entity.basename)

	match pool.wave.completion_condition:
		SpawnWave.CompletionCondition.REMAINING:
			print(float(pool.tracked_entities.size()) / pool.creatures_spawned_this_wave)
			print(pool.completion_ratio)
			if float(pool.tracked_entities.size()) / pool.creatures_spawned_this_wave <= pool.completion_ratio:
				_complete_wave(pool)
		SpawnWave.CompletionCondition.REMAINING_OR_TIME:
			print(float(pool.tracked_entities.size()) / pool.creatures_spawned_this_wave)
			print(pool.completion_ratio)
			if float(pool.tracked_entities.size()) / pool.creatures_spawned_this_wave <= pool.completion_ratio:
				_complete_wave(pool)
		SpawnWave.CompletionCondition.BOSS:
			if entity == pool.boss:
				_complete_wave(pool)
		# TIME is handled in _process()

func _complete_wave(pool: SpawnPool) -> void:
	if not pool.wave_active:
		return
	pool.wave_active = false
	wave_complete.emit(pool, pool.current_wave)

func get_point_budget(pool: SpawnPool, wave: SpawnWave) -> int:
	return roundi(wave.budget * pow(1.12, pool.level - 1))

func build_spawn_list(wave: SpawnWave, budget: int, level: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var menu: Array = wave.entries.filter(func(e: SpawnEntry) -> bool: return e.min_level <= level)
	var list: Array[StringName] = []
	var remaining: int = budget
	while remaining > 0 and list.size() < MAX_WAVE_SIZE:
		var affordable: Array = menu.filter(func(e: SpawnEntry) -> bool: return e.cost <= remaining)
		if affordable.is_empty():
			break
		var pick: SpawnEntry = _pick_weighted(affordable, rng)
		list.append(pick.entity_id)
		remaining -= pick.cost
	return list

func _pick_weighted(entries: Array, rng: RandomNumberGenerator) -> SpawnEntry:
	var total: float = 0.0
	for e: SpawnEntry in entries:
		total += e.weight
	var roll: float = rng.randf() * total
	for e: SpawnEntry in entries:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return entries.back()

func get_random_spawn_position(rng: RandomNumberGenerator) -> Vector2i:
	for i in range(SPAWN_TRIES):
		var pos: Vector2i = Vector2i(rng.randi_range(0, WorldGrid.width - 1), rng.randi_range(0, WorldGrid.height - 1))
		if WorldGrid.get_cell(pos).type.terrain == CellType.TerrainType.GROUND:
			return pos
	Log.warn("Could not find a safe position, spawning at world center.")
	return WorldGrid.get_center()


class SpawnPool:
	var waves: Array[SpawnWave] = []
	var level: int
	var pool_seed: int
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()

	var wave: SpawnWave # current wave
	var boss: Entity
	var current_wave: int = -1
	var wave_active: bool = false
	var tracked_entities: Array[Entity] = []
	var creatures_spawned_this_wave: int = 0

	var objective_time: float = 0.0
	var time_limit: float = -1.0

	## ratio of tracked_entities.size() / creatures_spawned_this_wave
	## at or below this threshold the wave is considered complete
	var completion_ratio: float = 0.20

	func _init(spawn_waves: Array[SpawnWave], lvl: int, seed_value: int) -> void:
		waves = spawn_waves
		level = lvl
		pool_seed = seed_value
