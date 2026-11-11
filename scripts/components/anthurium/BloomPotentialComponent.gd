extends Component
class_name BloomPotentialComponent

signal potential_changed(new_value: float)

var value: float = 0.0

func add(amount: float) -> void:
	value += amount
	potential_changed.emit(value)
	
func clear() -> void:
	value = 0.0
