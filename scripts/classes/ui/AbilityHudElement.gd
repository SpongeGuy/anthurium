extends InteractableUI
class_name AbilityHudElement

@export var ability: Ability
@export var slot: int
@export var ability_icon: Sprite2D

var activation_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var place_sound: AudioStream = load("res://assets/sounds/effects/align.wav")

func select(hand: Hand) -> void:
	hand.selected_element = self
	if hand.current_state != Hand.State.HOLDING:
		hand.change_state(Hand.State.HOVER_OVER_ACTIVATEABLE)

func activate(hand: Hand) -> void:
	if hand.current_state != Hand.State.HOLDING:
		hand.grab_ability()
	else:
		hand.drop_ability()
