extends Component
class_name InteractorComponent

@export var proximity: ProximityDetector
@export var input: InputComponent
@export var effect: EntityEffect

var _nearby: Array[Entity]

func _on_registered() -> void:
	proximity.detected.connect(_on_entity_detected)
	proximity.lost.connect(_on_entity_lost)

func _process(delta: float) -> void:
	if input.interact_just_pressed:
		print(_nearby)
		if effect:
			effect.execute(entity)
		var target: Entity
		var dist: float
		for e in _nearby:
			if not target:
				target = e
				dist = entity.global_position.distance_to(target.global_position)
				continue
			else:
				var new_dist: float = entity.global_position.distance_to(e.global_position)
				if new_dist < dist:
					target = e
					dist = new_dist
					continue
		
		if target:
			var interactable: InteractableComponent = target.get_component(InteractableComponent)
			interactable.interact(entity)
	
# THIS PROBABLY HAS TERRIABLE PEORFERMANCE
func _on_entity_detected(source: Entity, target: Entity) -> void:
	_nearby.append(target)
	
func _on_entity_lost(source: Entity, target: Entity) -> void:
	_nearby.erase(target)


@export_group("Shader")
@export var flash_target: Node
@export var flash_shader: Shader
@export var flash_duration: float = 0.3
@export var flash_width: float = 0.15
@export var flash_softness: float = 0.05

var _flash_material: ShaderMaterial

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
