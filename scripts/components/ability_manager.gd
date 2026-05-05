extends Component
class_name AbilityManager

# -----------------------------------------------
# interfaces with an inputcomponent to activate abilities
# -----------------------------------------------

@export var abilities: Array[Ability]

@export var input: InputComponent


func _ready() -> void:
	input.input_just_pressed.connect(_on_input_just_pressed)
	input.input_just_released.connect(_on_input_just_released)

func _on_input_just_pressed(id: int) -> void:
	if not abilities.get(id):
		return
	abilities[id].on_pressed()

func _on_input_just_released(id: int, held_time: float) -> void:
	if not abilities.get(id):
		return
	abilities[id].on_released(held_time)

func _process(delta: float) -> void:
	for i in range(input.is_held.size()):
		if input.is_held[i]:
			if i >= abilities.size():
				continue
			if abilities[i] == null:
				continue
			abilities[i].on_held(input.hold_time[i], delta)
			
func get_ability_from_id(id: int) -> Ability:
	if not abilities[id]:
		return
	return abilities[id]

func get_ability_from_string(action: String) -> Ability:
	var id: int = input.actions.bsearch(action)
	if not abilities[id]:
		return
	return abilities[id]
