extends Component
class_name SpriteAnimator

@export var sprite: Sprite2D
@export var starting_animation: int = -1
@export var animations: Array[SpriteAnimation] = []

var column: int = 0
var row: int = 0

var old_frame: int = 0
var current_frame: int = 0
var _current_animation: SpriteAnimation
var _timer: float = 0.0

var stopped: bool = false

signal animation_finished

var animation_speed_modifier: float = 1

signal animation_loaded(animation: SpriteAnimation)
signal frame_elapsed(to: int)

func _on_registered() -> void:
	if starting_animation >= 0:
		load_and_reset_animation(animations[starting_animation].name)

func _process(delta: float) -> void:
	_update_animation(delta, animation_speed_modifier)


func stop() -> void:
	stopped = true
	
func play() -> void:
	stopped = false

func load_animation(animation_name: StringName) -> void:
	# use this when resetting the animation to the beginning is not necessary
	for animation in animations:
		if animation.name != animation_name:
			continue
		_current_animation = animation
	if not _current_animation:
		push_error("animation does not exist!")
	play()
	row = _current_animation.row
	animation_speed_modifier = 1
	animation_loaded.emit(_current_animation)
	
func load_and_reset_animation(animation_name: StringName) -> void:
	# use this in most scenarios
	_timer = 0.0
	load_animation(animation_name)

func _update_animation(delta: float, modifier: float = 1.0) -> void:
	if not _current_animation:
		return
	
	if not stopped:
		_timer += delta * _current_animation.speed * modifier
	old_frame = current_frame
	if _timer >= _current_animation.frames:
		
		if _current_animation.loop:
			_timer = 0.0
		else:
			stop()
			animation_finished.emit()
	
	current_frame = floor(_timer)
	column = floor(_timer) + _current_animation.column
	
	if old_frame != current_frame:
		frame_elapsed.emit(current_frame)
	sprite.frame_coords = Vector2i(column, row)
