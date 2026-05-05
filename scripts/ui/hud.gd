extends Control
class_name UIHUD

static var score_collect_pos: Vector2 = Vector2(600, 350)

@export var bg_color: ColorRect
@export var time_label: Label
@export var time_message_label: Label
@export var player_health_bar: ProgressBar
@export var player_saturation_bar: ProgressBar

@export var inactive_game_score: Label
@export var active_game_score: Label
@export var inactive_nutri_score: Label
@export var active_nutri_score: Label

@export var ability_1_icon: Sprite2D
@export var ability_2_icon: Sprite2D
@export var ability_3_icon: Sprite2D
@export var ability_4_icon: Sprite2D

var ability_icons: Array[Sprite2D]

var game_score: float
var nutri_score: float

func _ready() -> void:
	ability_icons = [
		ability_1_icon,
		ability_2_icon,
		ability_3_icon,
		ability_4_icon,
	]

func change_game_score(new_game_score: float, delta: float) -> void:
	var string_length: int = 8
	game_score = lerp(game_score, new_game_score, delta * 1)
	active_game_score.text = str(int(game_score))
	inactive_game_score.text = str("0".repeat(string_length - active_game_score.text.length()))

func change_nutri_score(new_nutri_score: float, delta: float) -> void:
	var string_length: int = 8
	var factor: float = (new_nutri_score - nutri_score) + 250
	nutri_score = move_toward(nutri_score, new_nutri_score, delta * factor)
	active_nutri_score.text = str(int(nutri_score))
	inactive_nutri_score.text = str("0".repeat(string_length - active_nutri_score.text.length()))
