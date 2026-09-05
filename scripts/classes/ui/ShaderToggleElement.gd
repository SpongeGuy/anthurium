extends InteractableUI
class_name ShaderToggleElement

var mode: UiController.CRT_SHADER_MODES

@export var activate_sound: VoiceProfile
@export var start_sound: VoiceProfile

func select(hand: UIHand) -> void:
	mode = UiController.crt_shader_mode
	
func activate(hand: UIHand) -> void:
	mode = (mode + 1) % UiController.CRT_SHADER_MODES.size()
	UiController.set_crt_shader_mode(mode)
	CameraController.add_trauma(0.4)
	if activate_sound:
		AudioManager.play_voice(activate_sound, null, true, false)
	if start_sound:
		AudioManager.play_voice(start_sound, null, true, false)

func deselect(hand: UIHand) -> void:
	pass
