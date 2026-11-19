extends Component
class_name InteractorComponent

@export var radius: float = 16
@export var input: InputComponent
@export var effect: EntityEffect

var target: Entity
var old_target: Entity

var _in_reach: Array[Entity] = []

var interactable_component: InteractableComponent



var _nearby: Array[Entity]

func _on_registered() -> void:
	input.interact_just_pressed.connect(_on_interact_just_pressed)

func _query_reach() -> Array[Entity]:
	var result: Array[Entity] = []
	var found: Array[Entity] = SpatialUtil.get_entities_in_radius(entity.get_world_2d().direct_space_state, entity.global_position, radius, SpatialUtil.PhysicsLayers.ITEMS)
	for e in found:
		if e != entity and e.has_component(InteractableComponent):
			result.append(e)
	return result

func _process(_delta: float) -> void:
	var reach: Array[Entity] = _query_reach()
	for e in reach:
		if not _in_reach.has(e):
			e.get_component(InteractableComponent).add_focus(entity)
	for e in _in_reach:
		if not reach.has(e) and is_instance_valid(e):
			e.get_component(InteractableComponent).remove_focus(entity)
	_in_reach = reach

func _on_interact_just_pressed() -> void:
	if effect:
		effect.execute(entity)
	var nearest: Entity = SpatialUtil.get_nearest_entity_in_array(entity.global_position, _query_reach())
	if nearest:
		nearest.get_component(InteractableComponent).interact(entity)

func _exit_tree() -> void:
	for e in _in_reach:
		if is_instance_valid(e):
			e.get_component(InteractableComponent).remove_focus(entity)
	_in_reach.clear()
