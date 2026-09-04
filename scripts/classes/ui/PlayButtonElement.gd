extends InteractableUI
class_name PlayButtonElement

@export var activate_sound: VoiceProfile

func select(hand: UIHand) -> void:
	hand.change_state(UIHand.State.HOVER_OVER_ACTIVATEABLE)
	
func activate(hand: UIHand) -> void:
	AppController.change_app_state(AppController.AppStatus.GAME)
	if activate_sound:
		AudioManager.play_voice(activate_sound, null, true, false)

func deselect(hand: UIHand) -> void:
	pass
