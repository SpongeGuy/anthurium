extends CharacterBody2D
class_name Entity

## The base class for all actors in the game world.
##
## Entities manage a component registry that allows systems to query for
## attached components by type. Components are registered automatically from
## the scene tree on [method _ready], and can also be added at runtime via
## [method add_component].[br][br]
## Components are stored by every class in their inheritance chain, so
## querying by a base class (e.g. [LocomotionHandler]) will correctly return
## a subclass instance (e.g. [NormalLocomotionHandler]).

var _components: Dictionary[Script, Array] = {}

## Emitted after all components have been registered and the entity is ready.
signal entity_initialized

## The filename of the scene this entity was instantiated from, without extension.
## Useful for identifying entity types at runtime without hardcoding class names.
var basename: StringName

func _ready() -> void:
	basename = get_basename()
	_register_components(self)
	
	entity_initialized.emit()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	basename = get_basename()

func _register_components(node: Node) -> void:
	for child in node.get_children():
		if child is Component:
			_register_component(child)
		_register_components(child)


func _register_component(component: Component) -> void:
	var script: Script = component.get_script()
	while script:
		if not _components.has(script):
			_components.set(script, [])
		_components[script].append(component)
		script = script.get_base_script()
	component.entity = self
	component._on_registered()
	component.registered.emit()

## Registers [param component] to this entity and adds it as a child of [param to].
## Use this when creating components at runtime, e.g. inside [method Ability.initialize].
func add_component(to: Node, component: Component) -> void:
	_register_component(component)
	to.add_child(component)

## Returns the first registered component matching [param type], or [code]null[/code] if none exists.[br]
## Supports base class queries — passing [LocomotionHandler] will return a [NormalLocomotionHandler]
## if that is what is attached.
func get_component(type: Script) -> Variant:
	if not _components.has(type):
		return null
	var array: Array = _components.get(type)
	return array[0]

## Returns all registered components matching [param type] as an [Array],
## or [code]null[/code] if none exist.
func get_components(type: Script) -> Variant:
	if not _components.has(type):
		return null
	return _components.get(type)

## Returns [code]true[/code] if at least one component of [param type] is registered.
func has_component(type: Script) -> bool:
	return _components.has(type)


func get_basename() -> StringName:
	return StringName(get_scene_file_path().get_file().get_basename())

## Walks up the scene tree from [param node] until an [Entity] ancestor is found.[br]
## Returns [code]null[/code] if no [Entity] exists in the ancestry.[br][br]
## Useful for nodes that are nested inside an entity's scene tree but are not
## [Component] instances themselves, such as [Hitbox] or [Hurtbox].
static func find_entity(node: Node) -> Entity:
	if node == null:
		return null
	if node is Entity:
		return node
	return find_entity(node.get_parent())
