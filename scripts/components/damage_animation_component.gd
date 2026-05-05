extends Component
class_name DamageAnimationComponent

@export var flash_color: Color = Color(1, 0.2, 0.2)
@export var flash_duration: float = 0.1
@export var knockback_frames: int = 3

@export var health_component: HealthComponent
@export var sprite: Sprite2D

@export var damage_sound: AudioStream = preload("res://assets/sounds/effects/damage/hit.wav")

const FLASH_SHADER_PATH = "res://assets/shaders/hit_flash.gdshader"
var _flash_material: ShaderMaterial

var flash_tween: Tween
var shake_tween: Tween

func _ready() -> void:
	if health_component:
		health_component.taken_damage.connect(_on_damaged)
	
		
func _on_damaged(amount: float, source: Node2D) -> void:
	_play_hit_flash()
	_play_hit_shake(Vector2.RIGHT)
	AudioManager.play_sound_with_random_pitch(damage_sound, entity.global_position, 0.8, 1.2)
	
func _play_hit_shake(direction: Vector2) -> void:
	if not sprite: return
	if shake_tween: shake_tween.kill()
	shake_tween = create_tween()
	
	var elapsed: float = 0.0
	var duration: float = 0.25
	var amplitude: float = 8.0 # pixels
	var frequency: float = 4.0 # oscillations per second
	
	shake_tween.tween_method(
		func(t: float):
			var decay: float = 1.0 - t
			var offset: Vector2 = direction * amplitude * decay * sin(t * duration * frequency * TAU)
			sprite.position = offset,
		0.0, 1.0, duration
	)
	shake_tween.tween_callback(func(): sprite.position = Vector2.ZERO)

func _play_hit_flash() -> void:
	if not sprite: return
	if flash_tween: flash_tween.kill()
	
	var mat: ShaderMaterial = _get_or_create_flash_material()
	sprite.material = mat
	mat.set_shader_parameter("stage", 0)
	mat.set_shader_parameter("fade", 0.0)
	flash_tween = create_tween()
	
	var stage_duration: float = 0.065
	
	flash_tween.tween_callback(func(): mat.set_shader_parameter("stage", 1)).set_delay(stage_duration)
	flash_tween.tween_callback(func(): mat.set_shader_parameter("stage", 2)).set_delay(stage_duration)
	flash_tween.tween_callback(func(): mat.set_shader_parameter("stage", 3)).set_delay(stage_duration)
	flash_tween.tween_callback(func(): mat.set_shader_parameter("stage_blend", 0.0))
	flash_tween.tween_method(
		func(v: float): mat.set_shader_parameter("stage_blend", v),
		0.0, 1.0, 0.1
	)
	flash_tween.tween_callback(func(): sprite.material = null)
	

func _get_or_create_flash_material() -> ShaderMaterial:
	if _flash_material:
		return _flash_material
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = load(FLASH_SHADER_PATH)
	return _flash_material
