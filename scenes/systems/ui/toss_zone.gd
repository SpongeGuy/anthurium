extends InteractableUI

## A [InteractableUI] drop target that discards the held ability to the world.
##
## When the hand activates this zone while holding an ability,
## [method UIHand.toss_held_ability] is called. That method delegates to
## [method AbilityManager.drop_to_shard], which extracts the ability,
## emits [signal AbilityManager.ability_unregistered] (so the HUD clears the slot),
## and spawns an [AbilityShard] at the entity's feet.


func activate(hand: UIHand) -> void:
	# create ability shard and spawn it on player
	hand.toss_held_ability()
	
	
