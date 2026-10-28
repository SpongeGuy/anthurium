extends Component
class_name GlowComponent

@export var sprite: Sprite2D
@export var glow_color: Color = Color(1.0, 0.9, 0.4, 1.0)
@export var glow_width: float = 0.5
@export var ring_points: int = 8
@export var pulse_speed: float = 3
@export var min_intensity: float = 0
@export var max_intensity: float = 0.5
@export var auto_start: bool = true

const GLOW_SHADER_PATH = "uid://bryd5chbytxrk"

var _glow_sprites: Array[Sprite2D] = []
var _glow_material: ShaderMaterial
var _active: bool = false

func _ready() -> void:
	sprite.texture_changed.connect(start_glow)
	if auto_start:
		start_glow()

func _process(_delta: float) -> void:
	if not _active or not sprite:
		return
	_sync_ghosts()

func start_glow() -> void:
	if _active or not sprite:
		return

	_glow_material = ShaderMaterial.new()
	_glow_material.shader = load(GLOW_SHADER_PATH)
	_glow_material.set_shader_parameter("glow_color", glow_color)
	_glow_material.set_shader_parameter("pulse_speed", pulse_speed)
	_glow_material.set_shader_parameter("min_intensity", min_intensity)
	_glow_material.set_shader_parameter("max_intensity", max_intensity)
	_glow_material.set_shader_parameter("phase_offset", randf() * TAU)

	for i in ring_points:
		var angle: float = TAU * float(i) / float(ring_points)
		var offset := Vector2(cos(angle), sin(angle)) * glow_width

		var ghost := Sprite2D.new()
		ghost.material = _glow_material
		ghost.show_behind_parent = true
		ghost.position = offset

		sprite.add_child(ghost)
		_glow_sprites.append(ghost)

	_active = true
	_sync_ghosts() # match immediately, don't wait a frame

func stop_glow() -> void:
	if not _active:
		return
	for ghost in _glow_sprites:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_glow_sprites.clear()
	_glow_material = null
	_active = false

func _sync_ghosts() -> void:
	for ghost in _glow_sprites:
		ghost.texture = sprite.texture
		ghost.region_enabled = sprite.region_enabled
		ghost.region_rect = sprite.region_rect
		ghost.hframes = sprite.hframes
		ghost.vframes = sprite.vframes
		ghost.frame = sprite.frame
		ghost.centered = sprite.centered
		ghost.offset = sprite.offset
		ghost.flip_h = sprite.flip_h
		ghost.flip_v = sprite.flip_v
