extends Control
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)
@export var bar_node: Control
@export var menu_node: Control

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

@export var hand: Hand

var ability_icons: Array[Sprite2D]

var opal_score: float
var aura_score: float

var hud_position: Vector2 = Vector2(0, 332)
var screen_size: Vector2
var menu_position: Vector2 = Vector2(0, 0)
var tween: Tween

var voice_inv_open: VoiceProfile = preload("res://assets/resources/voices/ui_inventory_open.tres")
var voice_inv_close: VoiceProfile = preload("res://assets/resources/voices/ui_inventory_close.tres")

enum State{BAR, MENU}
var current_state: State = State.BAR
	
func _create_tween() -> Tween:
	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	return tween
	
func _get_hud_position() -> Vector2:
	return Vector2(0, screen_size.y - bar_node.size.y - hud_offset_from_bottom)

func _get_menu_position() -> Vector2:
	return Vector2(0, screen_size.y - bar_node.size.y - menu_node.size.y - menu_offset_from_bottom)
	
func _tween_to(target: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target, animation_speed)

func toggle_hud_state() -> State:
	if current_state == State.BAR:
		current_state = State.MENU
		_tween_to(_get_menu_position())
		AudioManager.play_voice(voice_inv_open, null, true, false)
	else:
		current_state = State.BAR
		_tween_to(_get_hud_position())
		AudioManager.play_voice(voice_inv_close, null, true, false)
	return current_state

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	hud_position = Vector2(0, screen_size.y - bar_node.size.y)
	menu_position = Vector2(0, screen_size.y - (bar_node.size.y + menu_node.size.y))
	tween = get_tree().create_tween()
	
	
	ability_icons = [
		ability_1_icon,
		ability_2_icon,
		ability_3_icon,
		ability_4_icon,
	]

func change_opal_score(new_opal_score: float, delta: float) -> void:
	var string_length: int = 8
	opal_score = lerp(opal_score, new_opal_score, delta * 1)
	active_opal_score.text = str(int(opal_score))
	inactive_opal_score.text = str("0".repeat(string_length - active_opal_score.text.length()))

func change_aura_score(new_aura_score: float, delta: float) -> void:
	var string_length: int = 8
	var factor: float = (new_aura_score - aura_score) + 250
	aura_score = move_toward(aura_score, new_aura_score, delta * factor)
	active_aura_score.text = str(int(aura_score))
	inactive_aura_score.text = str("0".repeat(string_length - active_aura_score.text.length()))
