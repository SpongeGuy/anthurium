class_name EntityEffectDespawn extends EntityEffect

func _execute(entity: Entity) -> void:
	entity.die_and_despawn()

