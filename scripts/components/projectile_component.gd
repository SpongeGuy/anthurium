extends Component
class_name ProjectileComponent


@export var damage_to_take_on_contact: float = 1.0
@export var hurtbox: Hurtbox
@export var health: HealthComponent
@export var friends: FriendComponent

@export_group("Optional")
@export var terrain_collider: ShapeCast2D


func _ready() -> void:
	hurtbox.area_entered.connect(_take_contact_damage_area)
	hurtbox.collision_shape.disabled = false
	
func _physics_process(delta: float) -> void:
	_collide_with_terrain()

func _take_contact_damage_area(area: Area2D) -> void:
	if area.owner == owner:
		return
	if friends.is_friend(area.owner):
		return
	health.take_damage(damage_to_take_on_contact, area.owner)
	
func _collide_with_terrain() -> void:
	if not terrain_collider:
		return
	if terrain_collider.is_colliding():
		for i in terrain_collider.get_collision_count():
			var collider := terrain_collider.get_collider(i)
			if collider is TileMapLayer:
				health.take_damage(damage_to_take_on_contact, collider)
				return
	

