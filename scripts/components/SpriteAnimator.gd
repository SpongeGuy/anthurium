extends Component
class_name SpriteAnimator

@export var sprite: Sprite2D
@export var default_animation: SpriteAnimation
@export var locomotion: LocomotionHandler

var column: int = 0
var row: int = 0

var old_frame: int = 0
var current_frame: int = 0
var _current_animation: SpriteAnimation
var _timer: float = 0.0

var stopped: bool = false

var playing_default_animation: bool = false

var animation_speed_modifier: float = 1

signal animation_finished(animation: SpriteAnimation)
signal animation_loaded(animation: SpriteAnimation)
signal frame_elapsed(to: int)

func _on_registered() -> void:
	if default_animation:
		play_animation(default_animation)

func _process(delta: float) -> void:
	if _current_animation and _current_animation.scales_with_speed and locomotion:
		var ratio: float = entity.velocity.length() / locomotion.speed if locomotion.speed > 0.0 else 0.0
		animation_speed_modifier = ratio
		
	_update_animation(delta, animation_speed_modifier)


func stop() -> void:
	stopped = true
	
func play() -> void:
	stopped = false

## plays [param animation] directly
func play_animation(animation: SpriteAnimation, speed_modifier: float = 1.0) -> void:
	# use this when resetting the animation to the beginning is not necessary
	if not animation:
		Log.error("Tried to play a null animation")
		return
	playing_default_animation = false
	_current_animation = animation
	row = animation.row
	animation_speed_modifier = speed_modifier
	play()
	animation_loaded.emit(_current_animation)
	
func set_default_animation(animation: SpriteAnimation, speed_modifier: float = 1.0) -> void:
	default_animation = animation
	if playing_default_animation:
		play_default_animation(speed_modifier)
	
func play_default_animation(speed_modifier: float = 1.0) -> void:
	if default_animation:
		play_animation(default_animation, speed_modifier)
		playing_default_animation = true
	
func play_and_reset_animation(animation: SpriteAnimation, speed_modifier: float = 1.0) -> void:
	# use this in most scenarios
	_timer = 0.0
	play_animation(animation, speed_modifier)
	
func set_speed_modifier(value: float) -> void:
	animation_speed_modifier = value

func _update_animation(delta: float, modifier: float = 1.0) -> void:
	if not _current_animation or stopped:
		return
	
	_timer += delta * _current_animation.speed * modifier
	old_frame = current_frame
	
	if _timer >= _current_animation.frames:	
		if _current_animation.loop:
			_timer = 0.0
		else:
			var finished_animation: SpriteAnimation = _current_animation
			stop()
			animation_finished.emit(finished_animation)
			if finished_animation != default_animation:
				play_default_animation()
			return
	
	current_frame = floor(_timer)
	column = floor(_timer) + _current_animation.column
	
	if old_frame != current_frame:
		frame_elapsed.emit(current_frame)
	if not stopped:
		sprite.frame_coords = Vector2i(column, row)
