class_name GhostComponent extends Component

@export var ghost_points: int = 0
@export var sprite: Sprite2D
@export var ghost_resource: GhostResource 
@export var damage_animation: DamageAnimationComponent


signal ghost_points_exhausted(entity: Entity)

func _on_registered() -> void:
	ghost_resource = GhostResource.new()

func _on_entity_initialized() -> void:
	update_form()

func _on_entity_spawned() -> void:
	pass

func set_ghost_points(to: int) -> void:
	ghost_points = to
	update_form()

func decrement_ghost_points(by: int) -> void:
	ghost_points -= by
	damage_animation._play_hit_flash()
	damage_animation._play_hit_shake(Vector2.RIGHT)

	if ghost_points <= 0:
		ghost_points_exhausted.emit(entity)
		entity.die_and_despawn()
	update_form()

func update_form() -> void:
	for i in range(ghost_resource.upgrade_thresholds.size() - 1, -1, -1):
		if ghost_points > ghost_resource.upgrade_thresholds[i]:
			sprite.texture = ghost_resource.textures[i]
			return
