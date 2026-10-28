class_name GeneralUtil
static func create_dynamic_circle_hurtbox(entity: Entity, damage: float, position: Vector2, radius: float, persistence: float) -> Hurtbox:
	var e: Entity = EntityManager.create_generic_entity()
	var hb: Hurtbox = Hurtbox.new(damage)
	hb.entity = e
	hb.persistence = persistence
	hb.create_circular_collision_shape(radius, 0)
	hb.set_behavior_type(Hurtbox.BehaviorType.CONSTANT)
	
	e.set_origin(entity)
	e.display_name = "%s %s" % [entity.display_name, "dynamic hurtbox"]
	e.add_child(hb)
	
	hb.persistence_elapsed.connect(func(): e.queue_free())
	
	EntityManager.spawn_entity(e, position, 0, false)
	return hb
