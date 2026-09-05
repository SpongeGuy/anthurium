extends CanvasItem


var _timer: float = 0.0

var timer_duration: float = 0.5

func toggle_visibility() -> void:
	if visible:
		visible = false
	else:
		visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_timer += delta
	if _timer >= timer_duration:
		_timer = 0
		toggle_visibility()
