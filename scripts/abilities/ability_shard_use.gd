extends Ability
class_name AbilityShardUse

@export var recently_interacted: RecentlyInteracted
@export var ability_container: AbilityContainer

var icon_texture: Texture = preload("res://assets/textures/ability_icons/ability_shard_use_icon.png")
var sound: AudioStream = load("res://assets/sounds/effects/powerup.wav")

func initialize() -> void:
	icon = icon_texture
	display_name = "Absorb Ability"
	if not recently_interacted:
		recently_interacted = entity.get_component(RecentlyInteracted)
		
	if not ability_container:
		ability_container = entity.get_component(AbilityContainer)


func on_pressed(modifier: bool) -> void:
	AudioManager.play_sound(sound)
	var subject: Entity = recently_interacted.recently_interacted
	if subject:
		var ability_manager: AbilityManager = subject.get_component(AbilityManager)
		for ability in ability_container.abilities:
			
			if ability:
				ability_manager.add_ability(ability)
	entity.queue_free()
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
