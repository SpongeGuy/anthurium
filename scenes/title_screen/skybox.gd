extends MeshInstance3D

@export var top_color: Color = Color(0.0, 0.6, 0.3) # Green-ish top
@export var middle_color: Color = Color(0.8, 0.4, 0.1) # Orange middle
@export var bottom_color: Color = Color(0.9, 0.2, 0.1) # Red-ish bottom
@export var middle_pos: float = 0.5 : set = set_middle_pos # Position of middle color (0-1)
@export var enable_pixelation: bool = false # Toggle pixelated effect
@export var pixel_steps: float = 8.0 # Steps for pixelation (1-64)

func _ready() -> void:
	update_shader_params()

func set_middle_pos(value: float) -> void:
	middle_pos = clamp(value, 0.0, 1.0)
	update_shader_params()

func update_shader_params() -> void:
	if mesh.material is ShaderMaterial:
		var mat: ShaderMaterial = mesh.material
		mat.set_shader_parameter("top_color", top_color)
		mat.set_shader_parameter("middle_color", middle_color)
		mat.set_shader_parameter("bottom_color", bottom_color)
		mat.set_shader_parameter("middle_pos", middle_pos)
		mat.set_shader_parameter("enable_pixelation", enable_pixelation)
		mat.set_shader_parameter("pixel_steps", pixel_steps)
