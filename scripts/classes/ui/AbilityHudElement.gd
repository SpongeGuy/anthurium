extends InteractableUI
class_name AbilityHudElement

@export var ability: Ability
@export var slot: int
@export var ability_icon: Sprite2D

var activation_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var place_sound: AudioStream = load("res://assets/sounds/effects/align.wav")

func select(hand: UIHand) -> void:
	hand.selected_element = self
	if hand.current_state != UIHand.State.HOLDING:
		hand.change_state(UIHand.State.HOVER_OVER_ACTIVATEABLE)

func activate(hand: UIHand) -> void:
	if hand.current_state != UIHand.State.HOLDING:
		hand.grab_ability()
	else:
		hand.drop_ability()
