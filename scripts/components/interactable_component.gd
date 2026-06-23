extends Component
class_name InteractableComponent

signal interacted(source: Entity)

@export var effect: EntityEffect
@export var detection_radius: float = 64

@export_flags_2d_physics var detection_mask: int = 3

@export_group("Shader")
@export var flash_target: Node
@export var flash_shader: Shader
@export var flash_duration: float = 0.3
@export var flash_width: float = 0.15
@export var flash_softness: float = 0.05

var _nearby: Array[Entity] = []
var _detection_area: Area2D
var _flash_material: ShaderMaterial

var interact_target: Entity:
	get: return _closest()


func _on_registered() -> void:
	_build_detection_area()
	_build_flash_material()

func interact(source: Entity) -> void:
	if effect:
		effect.execute(entity)
	interacted.emit(source)
	

# ----------------- detection ------------------
# ---------------------------------------------

func _build_detection_area() -> void:
	_detection_area = Area2D.new()
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = detection_mask
	_detection_area.monitorable = false
	
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = detection_radius
	shape.shape = circle
	
	_detection_area.add_child(shape)
	entity.add_child(_detection_area)
	
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node2D) -> void:
	if body == entity:
		return
	if body is Entity:
		_nearby.append(body)
		play_flash()
		
func _on_body_exited(body: Node2D) -> void:
	_nearby.erase(body)
	
func _closest() -> Entity:
	var best: Entity = null
	var best_dist := INF
	for e in _nearby:
		if not is_instance_valid(e):
			continue
		var d := entity.global_position.distance_squared_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best
	
	
# --------------------- flash -------------------
# ---------------------------------------------

func _build_flash_material() -> void:
	if not flash_shader or not flash_target:
		return
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = flash_shader
	_flash_material.set_shader_parameter("width", flash_width)
	_flash_material.set_shader_parameter("softness", flash_softness)
	_flash_material.set_shader_parameter("progress", 0.0)


func play_flash() -> void:
	if not _flash_material or not flash_target:
		return

	var existing_mat: Material = flash_target.material
	if existing_mat:
		existing_mat.next_pass = _flash_material
	else:
		flash_target.material = _flash_material

	_flash_material.set_shader_parameter("progress", 0.0)
	var tween := create_tween()
	tween.tween_method(
		func(v): _flash_material.set_shader_parameter("progress", v),
		0.0, 1.0, flash_duration
	)
	tween.tween_callback(func():
		if existing_mat:
			existing_mat.next_pass = null
		else:
			flash_target.material = null
	)
