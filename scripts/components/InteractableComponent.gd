extends Component
class_name InteractableComponent

signal interacted(source: Entity)

signal focused(source: Entity)
signal unfocused(source: Entity)

@export var effect: EntityEffect
var recently_interacted: Entity

@export var flash_duration: float = 0.2
var _focusers: Array[Entity] = []
var _flash_material: ShaderMaterial = preload("uid://7uhb7uu6inj6")
var _active_flash_material: ShaderMaterial
var _flash_tween: Tween
var _active_flash_target: CanvasItem



func interact(source: Entity) -> void:
	recently_interacted = source
	interacted.emit(source)
	if effect:
		effect.execute(entity)
	
func add_focus(source: Entity) -> void:
	if _focusers.has(source):
		return
	_focusers.append(source)
	if _focusers.size() == 1:
		focused.emit(source)
	play_flash(entity.get_visual()) # flashes for every entity that arrives
	
func remove_focus(source: Entity) -> void:
	_focusers.erase(source)
	for i in range(_focusers.size() - 1, -1, -1):
		if not is_instance_valid(_focusers[i]):
			_focusers.remove_at(i)
	if _focusers.is_empty():
		unfocused.emit(source)
	# only when this has been unfocused by every entity does it emit unfocused



# ------------------------- flash effect ------------------------------------------------





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
