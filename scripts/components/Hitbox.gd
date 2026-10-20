extends Area2D
class_name Hitbox

var entity: Entity
@export var collision_shape: CollisionShape2D
@export var physics: PhysicsComponent
@export var damage_response: Dictionary[Hurtbox.DamageType, DamageResponses] = {
	Hurtbox.DamageType.GENERIC: DamageResponses.DAMAGE,
	Hurtbox.DamageType.PROJECTILE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.MELEE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.FORCE: DamageResponses.DAMAGE,
	Hurtbox.DamageType.CONTACT: DamageResponses.DAMAGE,
	Hurtbox.DamageType.SELF: DamageResponses.DAMAGE,
}
var knockback_force: float = 100
enum DamageResponses{DAMAGE, REFLECT, ABSORB, IGNORE, REDIRECT}

## Height offset of this hitbox's damage volume from the owning entity's
## current [member Entity.z] (its base). 0 means the volume starts at the
## entity's own base.
@export var z_offset: float = 0.0
## Vertical extent of this hitbox's damage volume, from
## [code]entity.z + z_offset[/code] up to [code]+ height[/code]. Defaults to
## roughly a creature's body height; set higher/lower for hitboxes meant to
## represent a specific body part, or for projectiles that fly at their own
## altitude.
@export var height: float = 1.0
## If true, this hitbox hits regardless of vertical overlap with the
## hurtbox; for abilities/effects that should ignore height entirely.
@export var ignore_height: bool = false

signal hit_received(damage_amount: float, source: Node2D)
	

func _ready() -> void:
	name = "Hitbox"
	
	collision_mask |= 1 << 7
	collision_layer |= 1 << 6
	area_entered.connect(_on_hurtbox_contact)
	entity = Entity.find_entity(self)
	
	if not physics:
		physics = entity.get_component(PhysicsComponent)

## Returns whether this hitbox's damage volume vertically overlaps
## [param hurtbox]'s, using each side's owning entity's live [member Entity.z]
## plus its own [member z_offset]/[member height]. See
## [method SpatialUtil.z_ranges_overlap].
func _hits_by_height(hurtbox: Hurtbox) -> bool:
	if ignore_height or not entity or not hurtbox.entity:
		return true
	return SpatialUtil.z_ranges_overlap(
		entity.z + z_offset, height,
		hurtbox.entity.z + hurtbox.z_offset, hurtbox.height
	)
	


func _on_hurtbox_contact(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	var hurtbox: Hurtbox = area
	if hurtbox.entity == entity and not hurtbox.can_hurt_self:
		return
	if hurtbox.entity.is_friends_with(entity):
		return
	if not _hits_by_height(hurtbox):
		return
	if physics:
		physics.apply_knockback(hurtbox.entity.global_position, hurtbox.damage * knockback_force)
	hit_received.emit(hurtbox.damage, hurtbox.entity)
	EventBus.behavior_stimulus_event.emit(GameEvent.Stimulus.DAMAGE_TAKEN, {"damage": hurtbox.damage, "target": entity})
