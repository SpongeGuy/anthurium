extends Ability
class_name AbilityHand

@export var hand: HandComponent
@export var facing: FacingComponent

@export var toss_force_multiplier: float = 50
@export var toss_force_maximum: float = 100

var toss_force: float


	
	
func on_released(hold_duration: float) -> void:
	if hand.item:
		toss_force = min(hold_duration * toss_force_multiplier, toss_force_maximum)
		hand.toss_item(facing.get_direction(), toss_force)
		finished.emit()
	else:
		hand.try_pick_up_item_in_area()
		finished.emit()


