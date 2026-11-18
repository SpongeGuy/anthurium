class_name GhostQuest extends Quest




# ----------------------------------------------
# KILL QUEST
# ----------------------------------------------

# at the start of a level, ghosts will spawn in and begin to wander around or orbit around the map center.
# ghost points will be calculated and then ghosts will spawn in.
# the algorithm will always try to spawn in a ghost with the highest amount of points.
# after the calamity timer elapses, all ghosts will become aggressive.

## set when the quest is reset. allocated budget
var total_ghost_points: int = 0
## part of the budget not yet turned into ghosts
var unspent_ghost_points: int = 0
## sum of the values of all alive ghosts
var current_ghost_energy: int = 0

var ghost_quest_ratio: float = 0.1

var kills: int = 0
var kill_quest_complete: bool = false

var ghosts: Array[Entity] = []
var ghost_values: Dictionary[int, StringName] = {
	1: "ghost_1",
	2: "ghost_2",
	5: "ghost_5",
	10: "ghost_10",
	25: "ghost_25",
	50: "ghost_50",
	100: "ghost_100",
}

var spawning_ghosts: bool = false
var target_ghost: Entity

# timer is set to (ground_tile_count * entities_per_ground_tile + level_value * entities_per_level * 15)
var _ghost_calamity_timer: float = 0
var ghost_calamity_timer_length: float = 100

var _ghost_spawn_timer: float = 0.0
var ghost_spawn_timer_length: float = 0.5

# entities should send out a signal when they are killed (on HealthComponent cuz im lazy).
# when an entity dies, that signal is intercepted by the target ghost and their ghost points are decremented based on how many points that entity was worth.
# when the ghost runs out of ghost points, it despawns and sends out a signal. this signal is intercepted here and a new target ghost is chosen.

# ghost points should scale with (level value) and (ground_tile_count)







func start(ctx: Dictionary) -> void:
	var ground_tile_count: int = ctx.ground_tile_count
	var level_value: int = ctx.level_value
	# ghost_calamity_timer_length = ctx.get(ghost_calamity_timer_length)

	var multiplier: float = max(0.05, level_value * 0.15)
	total_ghost_points = max(10, multiplier * ground_tile_count)
	unspent_ghost_points = total_ghost_points
	if ghosts.size() > 0:
		for g in ghosts:
			g.queue_free()
	ghosts.clear()
	kills = 0
	kill_quest_complete = false
	current_ghost_energy = 0


	spawning_ghosts = true




func tick(delta: float) -> void:
	if is_complete:
		return
	
	# spawn ghosts until we've run out of points in current_ghost_points.
	# in reset_ghost_quest, current_ghost_points is set to total_ghost_points.
	# total_ghost_points is not changed except between levels.
	if spawning_ghosts:
		_ghost_spawn_timer -= delta
		if _ghost_spawn_timer <= 0:
			_ghost_spawn_timer = ghost_spawn_timer_length
			_try_summon_ghost()
		return
	_recalculate_ghost_energy()
	if float(current_ghost_energy) / float(total_ghost_points) <= ghost_quest_ratio:
		finish(QuestResult.SUCCESS)
	_ghost_calamity_timer += delta
	
	# GHOST CALAMITY
	if _ghost_calamity_timer >= ghost_calamity_timer_length:
		# change all the behavior of the ghosts to be aggressive
		EventBus.ghost_calamity_triggered.emit()

func _try_summon_ghost() -> int:
	if unspent_ghost_points <= 0:
		spawning_ghosts = false
		return 0
	var rng: RandomNumberGenerator = RunRng.get_stream("ghosts")
	var best: int = 0

	var affordable: Array[int] = []
	for k: int in ghost_values.keys():
		if k <= unspent_ghost_points:
			affordable.append(k)
	best = affordable[rng.randi_range(0, affordable.size() - 1)]
	
	var spawn_pos: Vector2 = SpatialUtil.get_random_offscreen_position(CameraController.camera, rng)

	var ghost: Entity = EntityManager.simple_spawn(ghost_values[best], spawn_pos)
	ghost.modulate = Color(1, 1, 1, 0.3)
	var g_component: GhostComponent = ghost.get_component(GhostComponent)
	g_component.ghost_points_exhausted.connect(_on_ghost_evaporation)
	g_component.set_ghost_points(best)

	ghosts.append(ghost)
	unspent_ghost_points -= best
	_recalculate_ghost_energy()

	ghost.died.connect(_on_entity_death)

	if not target_ghost:
		_set_ghost_target_to(ghost)
	return best

	

	

func _recalculate_ghost_energy() -> void:
	current_ghost_energy = 0
	for g in ghosts:
		var ghost_component: GhostComponent = g.get_component(GhostComponent)
		current_ghost_energy += ghost_component.ghost_points


func _on_ghost_evaporation(entity: Entity) -> void:
	ghosts.erase(entity)
	_recalculate_ghost_energy()
	if entity == target_ghost:
		_choose_new_ghost_target()


func _choose_new_ghost_target() -> void:
	if ghosts.size() <= 0:
		target_ghost = null
		return
	var rng: RandomNumberGenerator = RunRng.get_stream("ghosts")
	var index: int = rng.randi_range(0, ghosts.size() - 1)
	_set_ghost_target_to(ghosts[index])


func _set_ghost_target_to(entity: Entity) -> void:
	target_ghost = entity
	target_ghost.modulate = Color(1, 0, 0, 0.5)
	Log.debug("New ghost target targeted! %s" % target_ghost)


func _on_entity_death(entity: Entity) -> void:
	if entity.has_component(GhostComponent):
		return
	if not target_ghost:
		_choose_new_ghost_target()
	if not target_ghost:
		return
	var ghost_component: GhostComponent = target_ghost.get_component(GhostComponent)
	ghost_component.decrement_ghost_points(entity.ghost_value)
