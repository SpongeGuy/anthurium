extends Component
class_name Inventory

@export var inventory_capacity: int = 10
var inventory: Array[Node2D] = []
var inventory_item_collision_data: Dictionary

signal item_put_into_inventory(item: Entity)

func put_into_inventory(item: Entity) -> void:
	# hide item
	# freeze item's interactions and physics and behavior
	# item must have a stashablecomponent to be put into an inventory
	item.global_position = Vector2(-1000, -1000)
	item_put_into_inventory.emit(item)
	EventBus.item_put_into_inventory.emit(item)
	
func take_from_inventory(item: Entity) -> void:
	pass
	
func take_from_inventory_stack() -> void:
	pass

