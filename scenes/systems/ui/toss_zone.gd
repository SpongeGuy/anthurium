extends InteractableUI

var toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")

func activate(hand: Hand) -> void:
	
	# create ability shard and spawn it on player
	
	
	var shard: Entity = EntityManager.spawn_safely(&"ability_shard", PlayerManager.player.global_position)
	var container: AbilityContainer = shard.get_component(AbilityContainer)
	container.add_child(hand.holding.ability)
	
	hand.grabbed_sprite.texture = null
	hand.holding.ability = null
	hand.label.text = ""
	hand.current_state = Hand.State.HOVER_OVER_ACTIVATEABLE
	AudioManager.play_sound(toss_sound)
