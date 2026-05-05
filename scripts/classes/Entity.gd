extends CharacterBody2D
class_name Entity

# -------------------------------------------------------------
# entities have components as children
# these components get stored in memory so that other entities can reference them easily
# components are stored in an array inside a dictionary with the class_name (technically Script) being the key.
# components of the same type get stored in an array under the same key.
# get_component() returns the first component in the array.
# get_components() returns the array.
# when a component is fully registered to the entity, its _on_registered() method is called.
# ---------------------------------------------------------

var _components: Dictionary[Script, Array] = {}

signal entity_initialized

var basename: StringName

func _ready() -> void:
	_register_components(self)
	entity_initialized.emit()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	basename = get_basename()
	
func _register_components(node: Node) -> void:
	for child in node.get_children():
		if child is Component:
			add_component(child)
		_register_components(child)

func add_component(component: Component) -> void:
	if not _components.has(component.get_script()):
		_components.set(component.get_script(), [])
	_components[component.get_script()].append(component)
	component.entity = self
	component._on_registered()
	
func get_component(type: Script) -> Variant:
	if not _components.has(type):
		return null
	var array: Array = _components.get(type)
	return array[0]
	
func get_components(type: Script) -> Variant:
	if not _components.has(type):
		return null
	return _components.get(type)

	

func has_component(type: Script) -> bool:
	
	return _components.has(type)

func get_basename() -> StringName:
	return StringName(get_scene_file_path().get_file().get_basename())
