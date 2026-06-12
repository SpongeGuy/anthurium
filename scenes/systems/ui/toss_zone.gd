extends InteractableUI



func activate(hand: UIHand) -> void:
	
	# create ability shard and spawn it on player
	hand.toss_ability()
	
	
