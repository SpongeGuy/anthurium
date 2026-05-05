extends Ability
class_name AbilityPelletShoot

@export var entity_id: StringName
@export var facing: FacingComponent
@export var speed: float = 150.0
@export var friends: FriendComponent

@export var charge_time: float = 1.0

func on_pressed() -> void:
	execute()
	finished.emit()

func _execute() -> void:
	await get_tree().create_timer(charge_time).timeout
	var pellet = EntityManager.spawn(entity_id, owner.global_position)
	var movement: MovementComponent
	var pellet_friends: FriendComponent
	for child in pellet.get_children():
		if child is MovementComponent:
			movement = child
		if child is FriendComponent:
			pellet_friends = child
	movement.velocity = facing.get_direction() * speed
	pellet_friends.add_friend(owner)
	if friends:
		friends.add_friend(pellet)
	
