extends Component
class_name DirectionalSpriteAnimator

# --------------------------------
# animator module for entities that face in a particular direction
# also see SpriteAnimator (use that for entities that are static or don't face a direction)
# --------------------------------

# the character can face NSEW (4-way) or N, NE, NW, E, W, SE, SW (8-way).
const SPRITESHEET_TYPES: Array[int] = [4, 8]
# since the sprite for facing left and right are the same image but flipped,
# we can save space bu defining arrays to go back and use previous sprites on the spritesheet
# the integers in SECTORMAP8 and SECTORMAP4 essentially represent rows on the spritesheet.
const SECTORMAP8: Array[int] = [0, 1, 2, 3, 4, 3, 2, 1]
const SECTORMAP4: Array[int] = [0, 1, 2, 1]
const SECTORMAPMAP: Array[Array] = [SECTORMAP4, SECTORMAP8] # this is fucking stupid but i could either do this or an if statement so im doing this

@export var sprite: Sprite2D
@export var animations: Array[SpriteAnimation] = []
@export_enum("4-way", "8-way") var spritesheet_type: int
@export var facing: FacingComponent

var column: int = 0
var row: int = 0

var old_frame: int = 0
var current_frame: int = 0
var _current_animation: SpriteAnimation
var _timer: float = 0.0

var stopped: bool = false

var animation_speed_modifier: float = 1

signal animation_loaded(animation: SpriteAnimation)
signal frame_elapsed(to: int)


func _process(delta: float) -> void:
	_update_animation(delta, animation_speed_modifier)

func load_animation(animation_name: StringName) -> void:
	# use this when resetting the animation to the beginning is not necessary
	for animation in animations:
		if animation.name != animation_name:
			continue
		_current_animation = animation
	if not _current_animation:
		push_error("animation does not exist!")
	play()
	print(_current_animation)
	row = _current_animation.row
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
		
	# this checks if the current animation is a directional animation
	# if the current animation is directional, the system will then check if
	# the sprite needs to be flipped and then act.
	if row <= SPRITESHEET_TYPES[spritesheet_type] / 2:
		switch_direction()
	
	current_frame = floor(_timer)
	column = floor(_timer) + _current_animation.column
	
	if old_frame != current_frame:
		frame_elapsed.emit(current_frame)
	sprite.frame_coords = Vector2i(column, row)
	
func switch_direction() -> void:
	var sector: int = get_sector(facing.get_direction(), SPRITESHEET_TYPES[spritesheet_type])
	row = SECTORMAPMAP[spritesheet_type][sector]
	sprite.flip_h = sector > SPRITESHEET_TYPES[spritesheet_type] / 2

func stop() -> void:
	stopped = true
	
func play() -> void:
	stopped = false

func get_sector(direction: Vector2, ways: int) -> int:
	# some weird math to determine which sprite to use based on what direction the entity is facing
	# and how many ways the spritesheet is split up
	var angle: float = atan2(direction.y, direction.x * 0.9)
	var sector_size: float = TAU / ways
	return posmod(roundi(angle / sector_size) + ways / 4, ways)
