extends Component
class_name AbilityContainer

## Present on the `ability_shard` entity.
## See [AbilityShardUse] ability, which requires this [Component] to be on the [Entity].

@export var ability_icon_visual: Sprite2D

@export var abilities: Array[Ability] = [null, null, null, null]

func _on_registered() -> void:
	populate_abilities()
			


func add_ability(ability: Ability) -> void:
	if ability.get_parent():
		ability.reparent(self)
	else:
		add_child(ability)
	populate_abilities()
	ability_icon_visual.texture = ability.display_icon
	
func populate_abilities() -> void:
	abilities = [null, null, null, null]
	var index: int = 0
	for ability in get_children():
		if index > 4:
			return
		if ability is Ability:
			abilities[index] = ability
			index += 1
