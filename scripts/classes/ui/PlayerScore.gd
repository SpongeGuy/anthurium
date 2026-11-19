class_name PlayerScore extends VBoxContainer

## one player's rolling score
## slides in when score changes, stays until number stopp ROLLING plus HOLD_TIME, then slides out
## keeps its final value after the player dies

const HIDDEN_POS: Vector2 = Vector2(0, -40)
const SHOWN_POS: Vector2 = Vector2.ZERO
const HOLD_TIME: float = 2
const SLIDE_SPEED: float = 15
const ROLL_SPEED: float = 8
const DIGITS: int = 8
const SCORE_INACTIVE_COLOR: Color = Color(0.4, 0.4, 0.4)

@onready var _score_label: RichTextLabel = $SCORE
@onready var _player_label: Label = $PLAYER_LABEL

var _shown_value: float = 0
var _target_value: float = 0
var _hold: float = 0
var _want_visible: bool = false

func _ready() -> void:
	offset_transform_enabled = true
	offset_transform_position = HIDDEN_POS
	_write()

func setup(slot: int) -> void:
	_player_label.text = "P%d" % (slot + 1)
	var c: Color = PlayerPalette.color_for(slot)
	_player_label.add_theme_color_override("font_color", c)
	_score_label.add_theme_color_override("font_color", c)

## called when score changes. starts rolling and slides element in
func set_score(value: float) -> void:
	_target_value = value
	_hold = HOLD_TIME
	_want_visible = true

## snaps to [param value] with no rolling and hides. only for a new game or new player
func reset(value: float = 0) -> void:
	_shown_value = value
	_target_value = value
	_want_visible = false
	_hold = 0
	_write()

func _process(delta: float) -> void:
	if _shown_value != _target_value:
		_shown_value = lerpf(_shown_value, _target_value, 1.0 - exp(-ROLL_SPEED * delta))
		if absf(_shown_value - _target_value) < 0.5:
			_shown_value = _target_value
		_hold = HOLD_TIME
		_write()
	elif _want_visible:
		_hold -= delta
		if _hold <= 0:
			_want_visible = false
	
	var goal: Vector2 = SHOWN_POS if _want_visible else HIDDEN_POS
	offset_transform_position = offset_transform_position.lerp(goal, 1.0 - exp(-SLIDE_SPEED * delta))
#
# func _write() -> void:
# 	_score_label.text = "%0*d" % [DIGITS, int(_shown_value)]
#

func _write() -> void:
	var text: String = "%0*d" % [DIGITS, int(_shown_value)]
	var split: int = DIGITS - str(int(_shown_value)).length()
	
	_score_label.clear()
	_score_label.push_color(SCORE_INACTIVE_COLOR)
	_score_label.add_text(text.substr(0, split))
	_score_label.pop()
	_score_label.add_text(text.substr(split))
