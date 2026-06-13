extends Control
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)
@export var bar_node: Control
@export var menu_node: Control
@export var toss_zone_slot: InteractableUI

@export var hud_offset_from_bottom: float = 0.0
@export var menu_offset_from_bottom: float = -100
@export var animation_speed: float = 0.5

@export var bg_color: ColorRect
@export var time_label: Label
@export var time_message_label: Label
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

@export var hand: UIHand

var ability_icons: Array[Sprite2D]

var _opal_score: float = 0.0
var _aura_score: float = 0.0
var _target_opal: float = 0.0
var _target_aura: float = 0.0

const _SCORE_DIGITS := 8

var hud_position: Vector2 = Vector2(0, 332)
var menu_position: Vector2 = Vector2(0, 0)

var _screen_size: Vector2
var _tween: Tween

var _voice_inv_open: VoiceProfile = preload("res://assets/resources/voices/ui_inventory_open.tres")
var _voice_inv_close: VoiceProfile = preload("res://assets/resources/voices/ui_inventory_close.tres")

enum State{BAR, MENU}
var current_state: State = State.BAR



func _ready() -> void:
	_screen_size = get_viewport().get_visible_rect().size
	ability_icons = [ability_1_icon, ability_2_icon, ability_3_icon, ability_4_icon]

	ability_icons = [
		ability_1_icon,
		ability_2_icon,
		ability_3_icon,
		ability_4_icon,
	]




func toggle_hud_state() -> State:
	if current_state == State.BAR:
		current_state = State.MENU
		_tween_to(_get_menu_position())
	else:
		current_state = State.BAR
		_tween_to(_get_hud_position())
	return current_state
	
func go_to_bar_state() -> void:
	if current_state == State.BAR:
		return
	current_state = State.BAR
	_tween_to(_get_hud_position())
	AudioManager.play_voice(_voice_inv_close, null, true, false)
	toss_zone_slot.visible = false
	
func go_to_menu_state() -> void:
	if current_state == State.MENU:
		return
	current_state = State.MENU
	_tween_to(_get_menu_position())
	AudioManager.play_voice(_voice_inv_open, null, true, false)
	toss_zone_slot.visible = true




func update_health(ratio: float) -> void:
	player_health_bar.value = ratio * 100
	
func update_ichor(ratio: float) -> void:
	player_saturation_bar.value = ratio * 100
	
## Sets the icon displayed for [param slot] (0–3).
## Pass [code]null[/code] to clear the slot (shows the missing-ability placeholder).
func update_ability_icon(slot: int, texture: Texture2D) -> void:
	if slot < ability_icons.size():
		ability_icons[slot].texture = texture

		
func update_time(elapsed: float) -> void:
	var day_length: float = TimeManager.DAYTIMES[TimeManager.DAYTIMES.size() - 1]
	var remaining: float = day_length - elapsed
	if remaining >= 0:
		time_label.text = "%02d:%02d" % [int(remaining / 60), int(remaining) % 60]
		
func show_time_message(message: String) -> void:
	time_message_label.text = message
	
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


# -------------------------------------------------------
# slide animation
# -------------------------------------------------------

func _get_hud_position() -> Vector2:
	return Vector2(0, _screen_size.y - bar_node.size.y - hud_offset_from_bottom)

func _get_menu_position() -> Vector2:
	return Vector2(0, _screen_size.y - bar_node.size.y - menu_node.size.y - menu_offset_from_bottom)

func _tween_to(target: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, animation_speed)
