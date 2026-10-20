class_name EntityEffectCreateHurtbox extends EntityEffect
@export var damage: float
@export var radius: float
@export var persistence: float

func _execute(entity: Entity) -> void:
	GeneralUtil.create_dynamic_circle_hurtbox(entity, damage, entity.global_position, radius, persistence)

