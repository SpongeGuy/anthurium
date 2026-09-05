extends Area2D
class_name Hitbox

var entity: Entity
@export var collision_shape: CollisionShape2D
@export var friends: FriendComponent
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
var z: float = 0.0
var layer: Entity.VerticalLayer = Entity.VerticalLayer.GROUND
enum DamageResponses{DAMAGE, REFLECT, ABSORB, IGNORE, REDIRECT}

@export_flags("Subterranean", "Ground", "Aerial") var forced_hittable_layers: int = 0

signal hit_received(damage_amount: float, source: Node2D)



func _ready() -> void:
	name = "Hitbox"
	
	collision_mask |= 1 << 7
	collision_layer |= 1 << 6
	area_entered.connect(_on_hurtbox_contact)
	entity = Entity.find_entity(self)
	if entity:
		z = entity.z
		layer = entity.layer
		entity.z_updated.connect(_on_entity_z_updated)
		
func _on_entity_z_updated(new_z: float, new_layer: Entity.VerticalLayer) -> void:
	z = new_z
	layer = new_layer

func _z_layers_compatible(hurtbox: Hurtbox) -> bool:
	if not entity or not hurtbox.entity:
		return true
	if forced_hittable_layers & (1 << hurtbox.layer):
		return true
	return layer == hurtbox.layer
	


func _on_hurtbox_contact(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	var hurtbox: Hurtbox = area
	if hurtbox.entity == entity and not hurtbox.can_hurt_self:
		return
	if friends and friends.is_friend(hurtbox.entity):
		return
	if not _z_layers_compatible(hurtbox):
		return
	if knockback:
		knockback.apply_knockback(hurtbox.entity.global_position, hurtbox.damage * knockback_force)
	hit_received.emit(hurtbox.damage, hurtbox.entity)
	EventBus.behavior_stimulus_event.emit(GameEvent.Stimulus.DAMAGE_TAKEN, {"damage": hurtbox.damage, "target": entity})


