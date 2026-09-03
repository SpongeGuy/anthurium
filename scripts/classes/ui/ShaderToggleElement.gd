extends InteractableUI
class_name ShaderToggleElement

var mode: UiController.CRT_SHADER_MODES

func select(hand: UIHand) -> void:
	mode = UiController.crt_shader_mode
	
func activate(hand: UIHand) -> void:
	mode = (mode + 1) % UiController.CRT_SHADER_MODES.size()
	UiController.set_crt_shader_mode(mode)

func deselect(hand: UIHand) -> void:
	pass
