extends Node2D
class_name WeatherComponent

@onready var fog_shape: Polygon2D = $Shape
@onready var fog_area: Area2D = $Area2D
@onready var fog_collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var weather_tint: CanvasModulate = $CanvasModulate

var fog_color: Color = Color(0, 0, 0, 1)
var fog_position: Vector2 = Vector2.ZERO
var fog_radius: float = 100.0

var fog_default_shape: PackedVector2Array = PackedVector2Array([
	Vector2(-100000, -100000),
	Vector2(-100000, 100000),
	Vector2(100000, 100000),
	Vector2(100000, -100000)
])

var fog_shader: Shader = preload("res://assets/shaders/fog.gdshader")

func _ready() -> void:
	fog_shape.polygon = fog_default_shape
	
	var mat = ShaderMaterial.new()
	mat.shader = fog_shader
	fog_shape.material = mat
	fog_shape.material.set_shader_parameter("fog_color", fog_color)
	

