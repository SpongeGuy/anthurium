extends Component
class_name InteractorComponent

@export var proximity: ProximityDetector
@export var input: InputComponent
@export var effect: EntityEffect

var target: Entity
var old_target: Entity

var interactable_component: InteractableComponent



var _nearby: Array[Entity]

func _on_registered() -> void:
	proximity.detected.connect(_on_entity_detected)
	proximity.lost.connect(_on_entity_lost)

func _process(delta: float) -> void:
	target = find_nearby_target()
	print(entity, input.interact_just_pressed)
	if input.interact_just_pressed:
		
		if effect:
			effect.execute(entity)
		if interactable_component:
			interactable_component.interact(entity)
	
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
		
		
		
func find_nearby_target() -> Entity:
	if _nearby.size() <= 0:
		return
		
	var closest: Entity = _nearby[0]
	var dist: float = entity.global_position.distance_to(closest.global_position)
	for e in _nearby.slice(1):
		var new_dist: float = entity.global_position.distance_to(e.global_position)
		if new_dist < dist:
			closest = e
			dist = new_dist

	return closest
	
# THIS PROBABLY HAS TERRIABLE PEORFERMANCE
func _on_entity_detected(source: Entity, target: Entity) -> void:
	_nearby.append(target)
	
func _on_entity_lost(source: Entity, target: Entity) -> void:
	_nearby.erase(target)




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
