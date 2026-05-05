extends Component
class_name EdibleComponent

@export var stages: int = 1
@export var nutrition: float = 50.0
@export var type: FoodType
	
enum FoodType{ NEUTRAL, HERB, SYNTHETIC, MEAT }

signal eaten()



func eat(power: int = 1) -> void:
	stages -= power
	if stages <= 0:
		eaten.emit()
		entity.queue_free()
