class_name GhostComponent extends Component

@export var ghost_points: int = 0
@export var sprite: Sprite2D
@export var ghost_resource: GhostResource 


signal ghost_points_exhausted(entity: Entity)

func _on_registered() -> void:
	ghost_resource = GhostResource.new()

func _on_entity_initialized() -> void:
	update_form()

func _on_entity_spawned() -> void:
	pass


func decrement_ghost_points(by: int) -> void:
	ghost_points -= by
	print(ghost_points)

	if ghost_points <= 0:
		ghost_points_exhausted.emit(entity)
		entity.die_and_despawn()
	update_form()

func update_form() -> void:
	for i in range(ghost_resource.upgrade_thresholds.size() - 1, -1, -1):
		if ghost_points > ghost_resource.upgrade_thresholds[i]:
			sprite.texture = ghost_resource.textures[i]
			return
