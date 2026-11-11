extends Component
class_name PickupableComponent

# --------------------------------
# available for interaction between entities
# a simple switch to tell if this object is held by another entity or not.
# -----------------------------------

@export var components_to_disable: Array[Node]

var _held: bool = false
var holder: Entity = null

signal picked_up(by: Entity)
signal dropped(by: Entity)

func is_held() -> bool:
	return _held
	
func toggle_held(by: Entity) -> void:
	if _held:
		# item was dropped
		_enable_components()
		_held = false
		dropped.emit(by)
		holder = null
	else:
		# item was picked up
		_disable_components()
		_held = true
		picked_up.emit(by)
		holder = by

func _disable_components() -> void:
	for component in components_to_disable:
		component.process_mode = Node.PROCESS_MODE_DISABLED
		if component is CollisionShape2D:
			component.disabled = true

func _enable_components() -> void:
	for component in components_to_disable:
		component.process_mode = Node.PROCESS_MODE_INHERIT
		if component is CollisionShape2D:
			component.disabled = false
