extends Area2D
class_name Hitbox

var entity: Entity
@export var collision_shape: CollisionShape2D
@export var friends: FriendComponent
@export var collider_type: Array[Hurtbox.Layer] = [Hurtbox.Layer.NORMAL]
@export var knockback: KnockbackComponent
@export var damage_response: Dictionary[Hurtbox.DamageType, DamageResponses] = {
	Hurtbox.DamageType.GENERIC: DamageResponses.DAMAGE,
	Hurtbox.DamageType.PROJECTILE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.MELEE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.FORCE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.CONTACT: DamageResponses.DAMAGE,
	Hurtbox.DamageType.SELF: DamageResponses.DAMAGE,
}
var knockback_force: float = 100
const COLLIDER_BITS = [6, 12, 14]
enum DamageResponses{DAMAGE, REFLECT, ABSORB, IGNORE, REDIRECT}

signal hit_received(damage_amount: float, source: Node2D)

func _ready() -> void:
	name = "Hitbox"
	if collider_type.is_empty():
		push_error("Collider type for hitbox cannot be empty!")
	
	collision_mask = 0
	collision_layer = 0
	for type in collider_type:
		collision_mask |= 1 << COLLIDER_BITS[type] + 1
		collision_layer |= 1 << COLLIDER_BITS[type]
	area_entered.connect(_on_hurtbox_contact)
	entity = Entity.find_entity(self)
	


func _on_hurtbox_contact(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	var hurtbox: Hurtbox = area
	if hurtbox.entity == entity and not hurtbox.can_hurt_self:
		return
	if friends and friends.is_friend(hurtbox.entity):
		return
	if knockback:
		knockback.apply_knockback(hurtbox.entity.global_position, hurtbox.damage * knockback_force)
	hit_received.emit(hurtbox.damage, hurtbox.entity)
