extends Control
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)
@export var bar_node: Control
@export var menu_node: Control

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

var ability_icons: Array[Sprite2D]

var opal_score: float
var aura_score: float

var hud_position: Vector2 = Vector2(0, 332)
var screen_size: Vector2
var menu_position: Vector2 = Vector2(0, 0)
var hud_y: float
var menu_y: float
var tween: Tween
var animation_speed: float = 0.5

enum State{BAR, MENU}
var current_state: State = State.BAR
	
func _create_tween() -> Tween:
	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	return tween
	
func toggle_hud_state() -> State:
	if current_state == State.BAR:
		current_state = State.MENU
		tween_to_menu_position()
	elif current_state == State.MENU:
		current_state = State.BAR
		tween_to_hud_position()
		
	return current_state

func tween_to_hud_position() -> void:
	var t = _create_tween()
	t.tween_property(self, "position", hud_position, abs(position.y - hud_position.y) / screen_size.y * animation_speed)
	
func tween_to_menu_position() -> void:
	var t = _create_tween()
	t.tween_property(self, "position", menu_position, abs(position.y - menu_position.y) / screen_size.y * animation_speed)

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	hud_position = Vector2(0, screen_size.y - bar_node.size.y)
	menu_position = Vector2(0, screen_size.y - (bar_node.size.y + menu_node.size.y))
	print(hud_position)
	print(menu_position)
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
