extends Ability
class_name AbilityHand

@export var hand: HandComponent
@export var facing: FacingComponent

@export var toss_force_multiplier: float = 50
@export var toss_force_maximum: float = 100

var toss_force: float

func initialize() -> void:
	display_name = "Hand"

var ability_to_use: Ability

func on_pressed(modifier: bool) -> void:
	if hand.item:
		if modifier:
			if ability_to_use:
				ability_to_use.on_pressed(modifier)
	
func on_released(hold_duration: float, modifier: bool) -> void:
	if hand.item:
		if modifier:
			if ability_to_use:
				ability_to_use.on_released(hold_duration, modifier)
		else:
			toss_force = min(hold_duration * toss_force_multiplier, toss_force_maximum)
			hand.toss_item(facing.get_direction(), toss_force)
			ability_to_use = null
			finished.emit()
	else:
		var object: Entity = hand.try_pick_up_item_in_area()
		if object:
			var object_ability_manager = object.get_component(AbilityManager)
			if object_ability_manager:
				ability_to_use = object_ability_manager.abilities.get(0)
		finished.emit()


