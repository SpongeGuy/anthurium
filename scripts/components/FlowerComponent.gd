extends Component
class_name FlowerComponent

@export var col: Area2D
@export var collection_effect: EntityEffect

signal collected(flower: Entity)

func _on_entity_initialized() -> void:
	col.body_entered.connect(_on_body_entered)
	
	
func _on_body_entered(body: Node2D) -> void:
	if body is Entity:
		body.flower_collected()
		collected.emit(entity)
		entity.queue_free()
