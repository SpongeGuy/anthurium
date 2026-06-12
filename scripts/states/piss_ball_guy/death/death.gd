extends BehaviorState
class_name DeathState

## called once when the state machine does its initial switch to this state
@export var drop_ability_shard: AbilityShardSpawner
@export var entity_create: EntitySpawner
@export var animator: SpriteAnimator
@export var locomotion: LocomotionHandler
@export var death_effects: EntityEffect = preload("res://assets/resources/effects/default_death_effect.tres")

var burst: ParticleProfile = preload("res://assets/resources/particle_profiles/soulfire.tres")
var pop: ParticleProfile = preload("res://assets/resources/particle_profiles/pop.tres")

var play_death_animation: bool = true

func enter() -> void:
	if locomotion:
		locomotion.disabled = true
	_death_behavior()
	
	if animator and play_death_animation:
		animator.load_and_reset_animation("death")
		await animator.animation_finished
	
	if drop_ability_shard:
		drop_ability_shard.try_create()
		
	if entity_create:
		entity_create.spawn_at_entity()
	
	if death_effects:
		death_effects.execute(state_machine.entity)
	
	for child in state_machine.entity.get_children():
		if child is Area2D:
			child.set_deferred("monitorable", false)
			
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# yeah this is bad but idk man whatever fuck it we ball seriously
	state_machine.entity.queue_free()
	
func _death_behavior() -> void:
	pass
	
## called every frame while this state is active
func update(delta: float) -> void:
	if locomotion:
		locomotion.handle_locomotion(delta)
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass
