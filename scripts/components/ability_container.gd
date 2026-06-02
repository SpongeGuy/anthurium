extends Component
class_name AbilityContainer

@export var abilities: Array[Ability] = [null, null, null, null]

func _on_registered() -> void:
	var index: int = 0
	for ability in get_children():
		if index > 4:
			return
		if ability is Ability:
			abilities[0] = ability
			index += 1
			


