extends Node2D

@export var show: bool = false
@export var vbox: VBoxContainer
@export var title: Label
@export var l1: Label
@export var l2: Label
@export var l3: Label
@export var l4: Label
@export var camera: CameraController
@export var game_master: GameMaster

var coords: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if not show:
		visible = false
		return
	
	title.text = ""
	l1.text = ""
	l2.text = ""
	l3.text = ""
	l4.text = ""
	
	if camera.camera:
		coords = get_viewport().get_mouse_position()
		coords += camera.camera.position - Vector2(320, 180)
		vbox.position = get_window().get_mouse_position() + Vector2(5, 2)
		
	
	var space = game_master.world.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = coords
	query.collide_with_bodies = true
	var results = space.intersect_point(query)
	
	if results.is_empty():
		l4.text = ""
		return
	
	var subject: Node2D = results[0].collider
	if subject is not Entity:
		return
	
	var entity: Entity = subject as Entity
	
	display_base_stats(title, entity)
	
	if entity.has_component(Brain):
		display_entity_brain_state(l1, entity)
	
	if entity.has_component(AnthuriumComponent):
		update_anthurium(entity)
	
	
func update_anthurium(entity: Entity) -> void:
	display_coordinates(l2)
	display_anthurium_nutrition_points(l3)
	display_anthurium_active_parts(l4)
	
func display_base_stats(label: Label, entity: Entity) -> void:
	var string: String = ""
	string += str(entity.get_basename(), "\n")
	if entity.has_component(HealthComponent):
		string += str("hp: ", entity.get_component(HealthComponent).health)
	label.text = string
	
func display_coordinates(label: Label) -> void:
	label.text = str(WorldGrid.world_to_tile(coords))
	
func display_anthurium_active_parts(label: Label) -> void:
	var string = ""
	for entry in AnthuriumBrain.active_anthurium_names:
		string += str(entry, ": ", AnthuriumBrain.active_anthurium_names[entry], "\n")
	label.text = str(string)
	
func display_anthurium_nutrition_points(label: Label) -> void:
	var string: String = ""
	string += str("nutri: ", AnthuriumBrain.nutrition_points, "\n")
	string += str("furor: ", AnthuriumBrain.furor, "\n")
	label.text = string

func display_entity_brain_state(label: Label, entity: Entity) -> void:
	if entity.has_component(Brain):
		var ebrain: Brain = entity.get_component(Brain)
		var last_state: Dictionary[String, Array] = ebrain.last_state
		var string: String = ""
		for entry in last_state:
			string += str(entry, ": ", last_state[entry][0], "\n")
		
		label.text = str("BRAIN_STATE:\n", ebrain.personality, "\n", string)
	
