class_name DisappearInTimeComponent extends Component

@export var blink_timer: float = 0.2
var _blink_timer: float = 0

@export var disappear_timer: float = 10
var _disappear_timer: float = 0

@export var blink_threshold_ratio: float = 0.8
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
	
	if _disappear_timer / disappear_timer < fast_blink_threshold_ratio and not fast_blinking:
		blink_timer = blink_timer / 2
		fast_blinking = true
	
	if _disappear_timer / disappear_timer < blink_threshold_ratio and not blinking:
		blinking = true
	
	if _disappear_timer <= 0:
		_disappear()
		_disappear_timer = disappear_timer

func _on_entity_initialized() -> void:
	pass

func _on_entity_spawned() -> void:
	pass

func _toggle_blink() -> void:
	entity.visible = !entity.visible

func _disappear() -> void:
	entity.queue_free()
