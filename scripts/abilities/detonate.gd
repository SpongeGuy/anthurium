extends Ability
class_name AbilityDetonate


@export var blast_radius: float = 3
@export var damage: float = 25
var icon_texture: Texture2D = preload("uid://d4ixqeh4puotd")

func initialize() -> void:
	icon = icon_texture
	display_name = "Detonate"
		

func on_pressed(modifier: bool) -> void:
	var explosion: Entity = EntityManager.spawn(&"explosion", entity.position)
	var hurtbox: Hurtbox = explosion.get_child(0)
	hurtbox.scale = Vector2(blast_radius * 16, blast_radius * 16)
	hurtbox.damage = damage
	WorldGrid.damage_circle(WorldGrid.world_to_tile(entity.global_position), blast_radius, damage)
	
	
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
