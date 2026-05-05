extends Component
class_name AnthuriumPitcherComponent

@export var inventory: Inventory

# --------------------------------------------------
# behavior of pitcher plant
# accept food
# play animation
# give the target points (how tf to do this??)
# --------------------------------------------------


func _ready() -> void:
	inventory.item_put_into_inventory.connect(_on_item_accepted)
	
func _on_item_accepted(item: Entity) -> void:
	pass
