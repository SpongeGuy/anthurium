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

@export var inactive_opal_score: Label
@export var active_opal_score: Label
@export var inactive_aura_score: Label
@export var active_aura_score: Label

@export var ability_1_icon: Sprite2D
@export var ability_2_icon: Sprite2D
@export var ability_3_icon: Sprite2D
@export var ability_4_icon: Sprite2D

var ability_icons: Array[Sprite2D]

var _opal_score: float = 0.0
var _aura_score: float = 0.0
var _target_opal: float = 0.0
var _target_aura: float = 0.0

const _SCORE_DIGITS := 8

const HUD_SIZE: Vector2 = Vector2(640, 200)

const STATE_POSITIONS: Dictionary[State, Vector2] = {
	State.BAR: Vector2(0.0, 336.0),
	State.INACTIVE: Vector2(0.0, 360.0),
	State.ACTIVE: Vector2(0.0, 160.0),
}

enum State { BAR, INACTIVE, ACTIVE }
var current_state: State

var _tween: Tween

var _screen_size: Vector2

var _voice_inv_open: VoiceProfile = preload("uid://b778tjvr2o26a")
var _voice_inv_close: VoiceProfile = preload("uid://dy7px8dso8tvd")





func _ready() -> void:
	ability_icons = [ability_1_icon, ability_2_icon, ability_3_icon, ability_4_icon]




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




func update_health(ratio: float) -> void:
	player_health_bar.value = ratio * 100
	
func update_ichor(ratio: float) -> void:
	player_saturation_bar.value = ratio * 100
	
## Sets the icon displayed for [param slot] (0–3).
## Pass [code]null[/code] to clear the slot (shows the missing-ability placeholder).
func update_ability_icon(slot: int, texture: Texture2D) -> void:
	if slot < ability_icons.size():
		ability_icons[slot].texture = texture

		

		
	
func set_opal_score(value: float) -> void:
	_target_opal = value
	
func set_aura_score(value: float) -> void:
	_target_aura = value


# --------------------------
# score animation
# ---------------------------

func _process(delta: float) -> void:
	_opal_score = lerp(_opal_score, _target_opal, delta)
	_write_score(_opal_score, active_opal_score, inactive_opal_score)

	var aura_factor := (_target_aura - _aura_score) + 250.0
	_aura_score = move_toward(_aura_score, _target_aura, delta * aura_factor)
	_write_score(_aura_score, active_aura_score, inactive_aura_score)

func _write_score(value: float, active: Label, inactive: Label) -> void:
	var text := str(int(value))
	active.text = text
	inactive.text = "0".repeat(max(0, _SCORE_DIGITS - text.length()))


