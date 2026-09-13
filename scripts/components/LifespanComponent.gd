extends Component
class_name LifespanComponent

@export var age: float = 0.0
@export var lifespan: float = -1

signal expired

func _process(delta: float) -> void:
	age += delta
	if age >= lifespan:
		expired.emit()

func _on_registered() -> void:
	pass # replace with function body

