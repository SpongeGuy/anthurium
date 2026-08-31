extends EntityEffect
class_name EntityEffectParticle

@export var particle_profile: ParticleProfile

func _execute(entity: Entity) -> void:
	ParticleManager.burst(particle_profile, entity.global_position)
