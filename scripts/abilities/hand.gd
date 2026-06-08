extends Ability
class_name AbilityHand

@export var hand: HandComponent
@export var facing: FacingComponent

@export var toss_force_multiplier: float = 50
@export var toss_force_maximum: float = 100


var toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")
var drop_sound: AudioStream = load("res://assets/sounds/effects/drop.wav")

var toss_force: float

func initialize() -> void:
	display_name = "Hand"
	
	if not hand:
		hand = entity.get_component(HandComponent)
		facing = entity.get_component(FacingComponent)
		

var ability_to_use: Ability
var just_picked_up_item: bool = false

func on_pressed(modifier: bool) -> void:
	if hand.item:
		if modifier:
			if ability_to_use:
				ability_to_use.on_pressed(modifier)
	else:
		var object: Entity = hand.try_pick_up_item_in_area()
		if object:
			var object_ability_manager = object.get_component(AbilityManager)
			if object_ability_manager:
				ability_to_use = object_ability_manager.abilities.get(0)
		just_picked_up_item = true
		finished.emit()
		
	
func on_released(hold_duration: float, modifier: bool) -> void:
	if hand.item and not just_picked_up_item:
		if modifier:
			if ability_to_use:
				ability_to_use.on_released(hold_duration, modifier)
		else:
			toss_force = min(hold_duration * toss_force_multiplier, toss_force_maximum)
			if toss_force < 10:
				AudioManager.play_entity_sound([drop_sound], entity)
			else:
				AudioManager.play_entity_sound([toss_sound], entity)
			hand.toss_item(facing.get_direction(), toss_force)
			
			ability_to_use = null
			finished.emit()
	just_picked_up_item = false
	
