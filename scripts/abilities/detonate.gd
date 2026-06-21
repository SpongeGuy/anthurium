extends Ability
class_name AbilityDetonate

@export var hurtbox: Hurtbox
@export var blast_radius: float = 3
@export var damage: float = 25
@export var sound: VoiceProfile = preload("res://assets/resources/voices/detonate.tres")
@export var explosion_effect: EntityEffect = preload("res://assets/resources/effects/detonation_effect.tres")
var icon_texture: Texture2D = preload("res://assets/textures/ability_icons/detonate.png")

func initialize() -> void:
	icon = icon_texture
	if not hurtbox:
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = blast_radius * 16
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		collision_shape.shape = shape
		hurtbox = Hurtbox.new()
		hurtbox.damage = 10
		hurtbox.can_hurt_self = true
		hurtbox.collision_shape = collision_shape
		hurtbox.add_child(collision_shape)
		hurtbox.entity = entity
		hurtbox.set_active(false)
		
		created_nodes.append(hurtbox)
		
		# I DO NOT FUCKING KNOW WHY I NEED TO DO THIS, BUT IT ONLY WORKS
		# IF I PUT IT ON A CONTAINER ?
		var container := Node2D.new()
		entity.add_child(container)
		entity.add_child(hurtbox)
		

func on_pressed(modifier: bool) -> void:
	hurtbox.activate(0, 1)
	WorldGrid.damage_circle(WorldGrid.world_to_tile(entity.global_position), blast_radius, damage)
	explosion_effect.execute(entity)
	
	
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
