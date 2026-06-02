extends InteractableUI



func activate(hand: Hand) -> void:
	
	# create ability shard and spawn it on player
	hand.toss_ability()
	
	
