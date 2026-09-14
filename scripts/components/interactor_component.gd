extends Component
class_name InteractorComponent

@export var radius: float = 16
@export var input: InputComponent
@export var effect: EntityEffect

var target: Entity
var old_target: Entity

var interactable_component: InteractableComponent



var _nearby: Array[Entity]

func _on_registered() -> void:
	input.interact_just_pressed.connect(_on_interact_just_pressed)

func _process(delta: float) -> void:
	var nearby: Array[Entity] = SpatialUtil.get_entities_in_radius(entity.get_world_2d().direct_space_state, entity.global_position, radius, SpatialUtil.PhysicsLayers.ITEMS)
	target = SpatialUtil.get_nearest_entity_in_array(entity.global_position, nearby)

	
	if old_target != target:
		# give target the shader
		# play the shader
		var visual: Sprite2D
		if target:
			visual = target.get_visual()
		if visual:
			play_flash(visual)
		old_target = target
		if target:
			interactable_component = target.get_component(InteractableComponent)
		else:
			interactable_component = null
		
func _on_interact_just_pressed() -> void:
	if input.interact_just_pressed:
		if effect:
			effect.execute(entity)
		if interactable_component:
			interactable_component.interact(entity)




var _flash_material: ShaderMaterial = preload("uid://7uhb7uu6inj6")
var _active_flash_material: ShaderMaterial
var _flash_tween: Tween
var _active_flash_target: CanvasItem
@export var flash_duration: float = 0.2
func play_flash(flash_target: CanvasItem) -> void:
	if not flash_target:
		return
		
	_cancel_flash()

	var existing_mat: Material = flash_target.material
	_active_flash_material = _flash_material.duplicate()
	_active_flash_material.set_shader_parameter("progress", 1.0) # start normal
	_active_flash_target = flash_target

	if existing_mat:
		existing_mat.next_pass = _active_flash_material
	else:
		flash_target.material = _active_flash_material

	var stage: float = flash_duration / 4.0
	_flash_tween = create_tween()
	_flash_tween.tween_callback(func(): _active_flash_material.set_shader_parameter("progress", 0.0)) # white
	_flash_tween.tween_callback(func(): _active_flash_material.set_shader_parameter("progress", 1.0)).set_delay(stage) # normal
	_flash_tween.tween_callback(func(): _active_flash_material.set_shader_parameter("progress", 0.0)).set_delay(stage) # white
	_flash_tween.tween_callback(func(): _active_flash_material.set_shader_parameter("progress", 1.0)).set_delay(stage) # normal
	_flash_tween.finished.connect(_cancel_flash)

			
func _cancel_flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null

	if _active_flash_target and is_instance_valid(_active_flash_target):
		var existing_mat: Material = _active_flash_target.material
		if existing_mat == _active_flash_material:
			_active_flash_target.material = null
		elif existing_mat:
			existing_mat.next_pass = null

	_active_flash_material = null
	_active_flash_target = null
