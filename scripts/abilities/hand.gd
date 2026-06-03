extends Ability
class_name AbilityHand

@export var hand: HandComponent
@export var facing: FacingComponent
var pickup_sound_player: SoundPlayer
var toss_sound_player: SoundPlayer
var drop_sound_player: SoundPlayer

@export var toss_force_multiplier: float = 50
@export var toss_force_maximum: float = 100

var pickup_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")
var drop_sound: AudioStream = load("res://assets/sounds/effects/drop.wav")

var toss_force: float

func initialize() -> void:
	display_name = "Hand"
	
	if not hand:
		hand = entity.get_component(HandComponent)
		facing = entity.get_component(FacingComponent)
		
	if not pickup_sound_player:
		pickup_sound_player = SoundPlayer.new()
		pickup_sound_player.possible_sounds.append(pickup_sound)
		pickup_sound_player.visibility = entity.get_component(VisibilityComponent)
		created_nodes.append(pickup_sound_player)
		entity.add_component(entity, pickup_sound_player)
	if not toss_sound_player:
		toss_sound_player = SoundPlayer.new()
		toss_sound_player.possible_sounds.append(toss_sound)
		toss_sound_player.visibility = entity.get_component(VisibilityComponent)
		created_nodes.append(toss_sound_player)
		entity.add_component(entity, toss_sound_player)
	if not drop_sound_player:
		drop_sound_player = SoundPlayer.new()
		drop_sound_player.possible_sounds.append(drop_sound)
		drop_sound_player.visibility = entity.get_component(VisibilityComponent)
		created_nodes.append(drop_sound_player)
		entity.add_component(entity, drop_sound_player)
		

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
		pickup_sound_player.play_sound()
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
				drop_sound_player.play_sound()
			else:
				toss_sound_player.play_sound()
			hand.toss_item(facing.get_direction(), toss_force)
			
			ability_to_use = null
			finished.emit()
	just_picked_up_item = false
	


