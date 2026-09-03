extends InteractableUI
class_name PlayButtonElement

func select(hand: UIHand) -> void:
	pass
	
func activate(hand: UIHand) -> void:
	AppController.change_app_state(AppController.AppStatus.GAME)

func deselect(hand: UIHand) -> void:
	pass
