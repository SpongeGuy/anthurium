extends EntityEffect
class_name ParticleEntityEffect

@export var particle_profile: ParticleProfile

func execute(entity: Entity) -> void:
	ParticleManager.burst(particle_profile, entity.global_position)
	entity.tree_exited.connect(_stop_emitting)

func _stop_emitting() -> void:
	pass
