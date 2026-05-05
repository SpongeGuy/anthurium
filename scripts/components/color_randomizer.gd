extends Component
class_name ColorRandomizer


@export var sprite: Sprite2D
@export var gradient: Image
@export var tint_strength: float = 0.8
	
var image: Image

func _ready() -> void:
	var size: Vector2i = gradient.get_size()
	if size.x != size.y:
		return
	var random: Vector2i = Vector2i(randi_range(0, size.x-1), randi_range(0, size.y-1))
	var color: Color = gradient.get_pixelv(random)
	
	apply_color_tint(color)

func apply_color_tint(color: Color) -> void:
	if not sprite.material or not sprite.material is not ShaderMaterial:
		var shader = preload("res://assets/shaders/palette_swap.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		sprite.material = mat
		
	var material = sprite.material as ShaderMaterial
	material.set_shader_parameter("tint_color", color)
	material.set_shader_parameter("tint_strength", tint_strength)
