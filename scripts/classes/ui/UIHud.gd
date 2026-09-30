extends UIStage
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)
@export var bar_node: Control
@export var menu_node: Control
@export var toss_zone_slot: InteractableUI

@export var hud_offset_from_bottom: float = 0.0
@export var menu_offset_from_bottom: float = -100
@export var animation_speed: float = 0.5

@export var bg_color: ColorRect
@export var player_health_bar: ProgressBar
@export var player_saturation_bar: ProgressBar
@export var player_health_label: Label
@export var player_saturation_label: Label

@export var score_1_label: RichTextLabel
@export var score_2_label: RichTextLabel

@export var level_display_label: Label

@export var time_label: Label

@export var ability_hud_elements: Array[AbilityHudElement]
var ability_missing_texture: Texture2D = load("uid://ghuabptc2k60")

var _score_1: float = 0.0
var _score_2: float = 0.0
var _target_score_1: float = 0.0
var _target_score_2: float = 0.0

const _SCORE_DIGITS := 8

const HUD_SIZE: Vector2 = Vector2(640, 200)

const STATE_POSITIONS: Dictionary[State, Vector2] = {
	State.BAR: Vector2(0.0, 336.0),
	State.INACTIVE: Vector2(0.0, 360.0),
	State.ACTIVE: Vector2(0.0, 240.0),
}

enum State { BAR, INACTIVE, ACTIVE }
var current_state: State

var _tween: Tween

var _screen_size: Vector2

var score_inactive_color: Color = Color(0.47, 0.47, 0.47, 1.0)

var _voice_inv_open: VoiceProfile = preload("uid://b778tjvr2o26a")
var _voice_inv_close: VoiceProfile = preload("uid://dy7px8dso8tvd")



func _process(delta: float) -> void:
	_update_score_values(delta)
	_update_time()









# ----------------------------
# tweening menu position
# --------------------------------



func set_state(new_state: State) -> void:
	current_state = new_state
	_tween_to(STATE_POSITIONS[new_state])

	match new_state:
		State.ACTIVE:
			AudioManager.play_voice(_voice_inv_open, null, true, false)
			toss_zone_slot.visible = true
		State.BAR, State.INACTIVE:
			AudioManager.play_voice(_voice_inv_close, null, true, false)
			toss_zone_slot.visible = false

func _tween_to(target: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, animation_speed)









# ------------------------------------
# updating values
# ----------------------------------




func update_health(value: float, max_value: float) -> void:
	player_health_bar.value = (value / max_value) * 100
	player_health_label.text = str("%s/%s" % [int(value), int(max_value)])
	
func update_ichor(value: float, max_value: float) -> void:
	player_saturation_bar.value = (value / max_value) * 100
	player_saturation_label.text = str("%s/%s" % [int(value), int(max_value)])
	
## Sets the icon displayed for [param slot] (0–3).
## Pass [code]null[/code] to clear the slot (shows the missing-ability placeholder).
func update_ability_icon(slot: int, texture: Texture2D) -> void:
	if slot < ability_hud_elements.size():
		if not texture:
			ability_hud_elements[slot].ability_icon.texture = ability_missing_texture
			ability_hud_elements[slot].type = UIHand.State.DEFAULT
		else:
			ability_hud_elements[slot].ability_icon.texture = texture
			ability_hud_elements[slot].type = UIHand.State.HOVER_OVER_GRAB

		
func set_score_1(value: float) -> void:
	_target_score_1 = value
	
func set_score_2(value: float) -> void:
	_target_score_2 = value


# --------------------------
# score animation
# ---------------------------

func _update_score_values(delta: float) -> void:
	_score_1 = lerp(_score_1, _target_score_1, 1.0 - exp(-8.0 * delta))
	if abs(_score_1 - _target_score_1) < 0.5:
		_score_1 = _target_score_1
	_write_score(_score_1, score_1_label)

	var factor_2: float = abs(_target_score_2 - _score_2) + 250.0
	_score_2 = move_toward(_score_2, _target_score_2, delta * factor_2)
	_write_score(_score_2, score_2_label)



func _write_score(value: float, label: RichTextLabel) -> void:
	var text: String = "%0*d" % [_SCORE_DIGITS, int(value)]
	var split: int = _SCORE_DIGITS - str(int(value)).length()
	
	label.clear()
	label.push_color(score_inactive_color)
	label.add_text(text.substr(0, split))
	label.pop()
	label.add_text(text.substr(split))


# -----------------------------
# time
# -----------------------------

func _update_time() -> void:
	var total_seconds: int = int(GameInterface.time)
	time_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]

func update_level_text() -> void:
	level_display_label.text = str("Level %d" % [GameInterface.current_level + 1])


