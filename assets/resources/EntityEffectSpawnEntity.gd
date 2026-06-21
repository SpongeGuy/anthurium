extends EntityEffect
class_name EntityEffectSpawnEntity

@export var entity_name: StringName
@export var overrides: Array[ComponentPropertyOverride] = []

func _execute(entity: Entity) -> void:
	var spawned: Entity = EntityManager.spawn_safely(entity_name, entity.global_position)
	if not spawned:
		push_error("EntityEffectSpawnEntity: Could not spawn entity '%s', does not exist?" % spawned)
		return
	
	if overrides.is_empty():
		return
	
	# only apply overrides after the entity's ready function is called
	spawned.ready.connect(_apply_overrides.bind(spawned), CONNECT_ONE_SHOT)


func _apply_overrides(spawned: Entity) -> void:
	for override in overrides:
		if not override.component:
			push_error("EntityEffectSpawnEntity: An override has no component set")
			continue
		var component = spawned.get_component(override.component)
		if not component:
			push_error("EntityEffectSpawnEntity: Entity '%s' has no component '%s'" % [entity_name, override.component.resource_path])
			continue
		
		var prop_info: Dictionary = {}
		for p in component.get_property_list():
			if p.name == override.property:
				prop_info = p
				break
		
		if prop_info.is_empty():
			push_error("EntityEffectSpawnEntity: Component '%s' has no property '%s'" % [override.component.resource_path, override.property])
			continue
		
		# TYPE_NIL means untyped/Variant — skip type check in that case
		if prop_info.type != TYPE_NIL and typeof(override.value) != prop_info.type:
			push_error("EntityEffectSpawnEntity: Property '%s' expects type %s, got %s" % [
				override.property,
				type_string(prop_info.type),
				type_string(typeof(override.value))
			])
			continue


		
		if override.value is Array:
			var current = component.get(override.property)
			if current is Array:
				current.clear()
				current.assign(override.value)
			else:
				component.set(override.property, override.value)
		else:
			component.set(override.property, override.value)

