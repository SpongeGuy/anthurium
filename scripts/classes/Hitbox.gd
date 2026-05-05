extends Area2D
class_name Hitbox

@export var collision_shape: CollisionShape2D
@export var friends: FriendComponent
@export var collider_type: Array[ColliderType] = [ColliderType.NORMAL]
enum ColliderType{NORMAL, FLYING, GROUND}
const COLLIDER_BITS = [6, 12, 14]

signal hit_received(damage_amount: float, source: Node2D)

func _ready() -> void:
	if collider_type.is_empty():
		push_error("Collider type for hitbox cannot be empty!")
	
	collision_mask = 0
	collision_layer = 0
	for type in collider_type:
		collision_mask |= 1 << COLLIDER_BITS[type] + 1
		collision_layer |= 1 << COLLIDER_BITS[type]
	area_entered.connect(_on_hurtbox_contact)

func _on_hurtbox_contact(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	if area.owner == owner:
		return
	if friends and friends.is_friend(area.owner):
		return
	hit_received.emit(area.damage, area.owner)



