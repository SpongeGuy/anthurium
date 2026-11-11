class_name WaterDropComponent extends Component

@export var spawn_effect: EntityEffect
@export var land_effect: EntityEffect

func _on_entity_spawned() -> void:
	spawn_effect.execute(entity)



