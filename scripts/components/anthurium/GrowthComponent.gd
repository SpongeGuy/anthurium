extends Component
class_name GrowthComponent

@export var chance_to_grow_root: float = 0.1
@export var chance_to_grow_accessory: float = 0.01
@export var grow_effect: EntityEffect
@export var excluded_angle_range_degrees: float = 60.0

const MAX_ANGLE_ATTEMPTS: int = 12

var root_textures: Array[Texture2D] = [
	preload("uid://fsq4li8hk0yf"), 
	preload("uid://bm1nri7fdk4yl"),
	preload("uid://cwgrrrpo8o6i8"),
	preload("uid://mttj8js5ymgx")
]

var flower_textures: Array[Texture2D] = [
	preload("uid://bq58f3g3qvl8p"),
	preload("uid://lp3gwfff7qlk")
]


func try_grow_root(source: Entity, prev: Array[ArteryComponent.ArteryLink]) -> Entity:
	var chance: float = randf()
	if chance >= chance_to_grow_root:
		return null
	var excluded_angles: Array[float] = _get_excluded_angles(prev)
	var angle: float = _pick_valid_angle(excluded_angles)
	var distance: float = randf_range(25.0, 38.0)
	var offset: Vector2 = Vector2.from_angle(angle) * distance
	var root: Entity = EntityManager.spawn_safely(&"anthurium_root", entity.global_position + offset)
	
	var sprite: Sprite2D = root.visual
	if (angle >= (PI * 7/4) or angle < (PI * 1/4)) or (angle >= (PI * 3/4) and angle < (PI * 5/4)):
		sprite.texture = root_textures[0] if randf() < 0.5 else root_textures[2]
	else:
		sprite.texture = root_textures[1] if randf() < 0.5 else root_textures[3]
		
	if grow_effect:
		grow_effect.execute(entity)
	return root
	


func try_grow_accessory(source: Entity, prev: Array[ArteryComponent.ArteryLink]) -> Entity:
	var chance: float = randf()
	if chance >= chance_to_grow_accessory:
		return null
	var accessory: Entity = Entity.new()
	var excluded_angles: Array[float] = _get_excluded_angles(prev)
	var angle: float = _pick_valid_angle(excluded_angles)
	var distance: float = randf_range(4.0, 12.0)
	var offset: Vector2 = Vector2.from_angle(angle) * distance
	accessory = EntityManager.spawn(&"anthurium_flower", entity.global_position + offset)
	if grow_effect:
		grow_effect.execute(entity)
	return accessory
	



func _get_excluded_angles(prev: Array[ArteryComponent.ArteryLink]) -> Array[float]:
	var angles: Array[float] = []
	for link in prev:
		if not is_instance_valid(link.entity):
			continue
		var to_prev: Vector2 = link.entity.global_position - entity.global_position
		angles.append(to_prev.angle())
	return angles
	
func _pick_valid_angle(excluded_angles: Array[float]) -> float:
	var half_range: float = deg_to_rad(excluded_angle_range_degrees) * 0.5
	for attempt in MAX_ANGLE_ATTEMPTS:
		var angle: float = randf() * TAU
		var valid: bool = true
		for excluded in excluded_angles:
			if absf(wrapf(angle - excluded, -PI, PI)) < half_range:
				valid = false
				break
		if valid:
			return angle
		
	Log.warn("Could not find valid placement angle after %d attempts, allowing overlap" % MAX_ANGLE_ATTEMPTS)
	return randf() * TAU
