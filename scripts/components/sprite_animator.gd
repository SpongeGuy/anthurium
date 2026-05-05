extends Component
class_name SpriteAnimator

@export var sprite: Sprite2D

@export var animations: Array[SpriteAnimation]

var _current_animation: SpriteAnimation
var _current_frame: int = 0
var _animation_timer: float = 0.0

var stopped: bool = false

signal animation_finished(animation: SpriteAnimation)
signal animation_loaded(animation: SpriteAnimation)
signal frame_elapsed(frame: int)

var animation_speed: float = 1.0


func _process(delta: float) -> void:
	_update_animation(delta, animation_speed)


# loads the animation and sets the frame counter to the beginning of the animation
# chances are you want to use this one over load_animation, this one will look less buggy in most use cases.
func load_and_reset_animation(animation_name: StringName) -> void:
	for animation in animations:
		if animation.name != animation_name:
			continue
		_current_animation = animation
	if not _current_animation:
		return
	_animation_timer = _current_animation.column
	_current_frame = floor(_animation_timer)
	_play()
	animation_loaded.emit(_current_animation)
	
# loads the animation forcibly without resetting the frame counter
# can look buggy when loading an animation that starts on a new column.
func load_animation(animation_name: StringName) -> void:
	if _current_animation and animation_name == _current_animation.name:
		return
	for animation in animations:
		if animation.name != animation_name:
			continue
		_current_animation = animation
	_play()
	animation_loaded.emit(_current_animation)
	
func reset_animation() -> void:
	_current_frame = 0
	_animation_timer = 0.0
	_play()



func _stop() -> void:
	stopped = true
	
func _play() -> void:
	stopped = false

func _update_animation(delta: float, modifier: float = 1.0) -> void:
	if not _current_animation:
		return
	
	if stopped:
		return
	
	var old_frame: int = _current_frame
	_animation_timer += delta * modifier * _current_animation.speed
	if _animation_timer >= _current_animation.frames + _current_animation.column:
		# if this isn't a looping animation, then stop the animation
		if not _current_animation.loop:
			animation_finished.emit(SpriteAnimation)
			_stop()
			return
		
		_animation_timer = _current_animation.column
		
		
		
			
	if not _current_animation:
		return
	
	_current_frame = floor(_animation_timer)
	
	
	if old_frame != _current_frame:
		frame_elapsed.emit(_current_frame)
	sprite.frame_coords = Vector2i(_current_frame, _current_animation.row)
