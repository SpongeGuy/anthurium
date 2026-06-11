extends Ability
class_name AbilityDetonate

@export var hurtbox: Hurtbox
@export var blast_radius: float = 3
@export var sound: BfxrVoiceProfile = preload("res://scripts/resources/voices/detonate.tres")

func initialize() -> void:
	print("initializing detonate for ", entity)
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
		
		created_nodes.append(hurtbox)
		
		# I DO NOT FUCKING KNOW WHY I NEED TO DO THIS, BUT IT ONLY WORKS
		# IF I PUT IT ON A CONTAINER ?
		var container := Node2D.new()
		entity.add_child(container)
		entity.add_child(hurtbox)
		

func on_pressed(modifier: bool) -> void:
	hurtbox.activate(0, 1)
	var cell: CellData = CellData.new()
	cell.terrain = CellData.TerrainType.GROUND
	cell.skin = 1
	WorldGrid.set_circle(WorldGrid.world_to_tile(entity.global_position), blast_radius, cell)
	AudioManager.play_voice(sound, entity)
	CameraController.add_trauma_distance(entity.global_position, 1)
	
	
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	pass
	
func on_released(hold_duration: float, modifier: bool) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
