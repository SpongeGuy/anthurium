class_name FlowerQuest extends Quest



# ---------------------------------------------
# FLOWER QUEST
# --------------------------------------------
var total_flowers: int = 0
var current_flowers: int = 0
var flower_quest_ratio: float = 0.1
var flowers: Array[Entity] = []

 
func start(ctx: Dictionary) -> void:
	total_flowers = 0
	current_flowers = 0
	is_complete = false
	for f in flowers:
		if is_instance_valid(f):
			f.queue_free()
	flowers.clear()
	_spawn_flowers()
 
func _spawn_flowers() -> void:
	var coordinates: Array[Vector2i] = TerrainManager.query_for_tile_type(CellType.TerrainType.GROUND)
	for c in coordinates:
		var flower: Entity = EntityManager.simple_spawn_tile("collectible_flower", c)
		var comp: FlowerComponent = flower.get_component(FlowerComponent)
		flowers.append(flower)
		current_flowers += 1
		total_flowers += 1
		comp.collected.connect(_collect_flower, CONNECT_ONE_SHOT)
  
func tick(_delta: float) -> void:
	if is_complete or total_flowers == 0:
		return
	if float(current_flowers) / float(total_flowers) <= flower_quest_ratio:
		_complete_flower_quest()


func _collect_flower(flower: Entity) -> void:
	flowers.erase(flower)
	current_flowers -= 1
 
 
func _complete_flower_quest() -> void:
	finish()
