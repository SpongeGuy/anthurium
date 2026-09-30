extends InteractableUI
class_name PlayButtonElement

@export var activate_sound: VoiceProfile
@export var start_sound: VoiceProfile
@export var scaling_node: Control

var x_tween: Tween

func select(hand: UIHand) -> void:
	scaling_node.offset_transform_enabled = true
	TweenUtil.tween_to(x_tween, scaling_node, "offset_transform_position", Vector2(24, 0), 0.5)
	
func activate(hand: UIHand) -> void:
	AppController.change_app_state(AppController.AppStatus.GAME)
	if activate_sound:
		AudioManager.play_voice(activate_sound, null, true, false)
	if start_sound:
		AudioManager.play_voice(start_sound, null, true, false)

func deselect(hand: UIHand) -> void:
	TweenUtil.tween_to(x_tween, scaling_node, "offset_transform_position", Vector2(0, 0), 0.5)



