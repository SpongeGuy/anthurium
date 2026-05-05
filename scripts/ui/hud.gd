extends Control
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)

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

func _ready() -> void:
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
