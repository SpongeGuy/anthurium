extends Ability

@export var recently_interacted: RecentlyInteracted

var icon_texture: Texture = preload("res://assets/textures/ability_icons/ability_shard_use_icon.png")

func initialize() -> void:
	icon = icon_texture
	display_name = "Absorb Ability"
	if not recently_interacted:
		recently_interacted = entity.get_component(RecentlyInteracted)

func on_pressed() -> void:
	pass
	
func on_held(hold_duration: float, delta: float) -> void:
	pass
	
func on_released(hold_duration: float) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass

