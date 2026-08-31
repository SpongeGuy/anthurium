extends Component
class_name GrowthComponent

@export var chance_to_grow_root: float = 0.1
@export var chance_to_grow_accessory: float = 0.01
@export var grow_effect: EntityEffect

func try_grow_root(source: Entity) -> Entity:
	var chance: float = randf()
	if chance >= chance_to_grow_root:
		return null
	var angle: float = randf() * TAU
	var distance: float = randf_range(25.0, 38.0)
	var offset: Vector2 = Vector2.from_angle(angle) * distance
	var root: Entity = EntityManager.spawn_safely(&"anthurium_root", entity.global_position + offset)
	if grow_effect:
		grow_effect.execute(entity)
	return root

func try_grow_accessory(source: Entity) -> Entity:
	return null
