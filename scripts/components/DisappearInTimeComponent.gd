class_name DisappearInTimeComponent extends Component

var modulate_is_clear: bool = false

@export var blink_timer: float = 0.2
var _blink_timer: float = 0

@export var disappear_timer: float = 30
var _disappear_timer: float = 0

@export var blink_threshold_ratio: float = 0.7
var blinking: bool = false

@export var fast_blink_threshold_ratio: float = 0.9
var fast_blinking: bool = false

func _on_registered() -> void:
	_blink_timer = blink_timer
	_disappear_timer = disappear_timer

func _process(delta: float) -> void:
	if blinking:
		_blink_timer -= delta
	_disappear_timer -= delta
	
	if _blink_timer <= 0:
		_toggle_blink()
		_blink_timer = blink_timer
	
	var elapsed_ratio: float = 1.0 - _disappear_timer / disappear_timer
	if elapsed_ratio >= fast_blink_threshold_ratio and not fast_blinking:
		blink_timer = blink_timer / 2
		fast_blinking = true
	
	if elapsed_ratio >= blink_threshold_ratio and not blinking:
		blinking = true
	
	if _disappear_timer <= 0:
		_disappear()

func _toggle_blink() -> void:
	modulate_is_clear = not modulate_is_clear
	entity.modulate.a = 0.0 if modulate_is_clear else 1.0

func _disappear() -> void:
	entity.queue_free()
