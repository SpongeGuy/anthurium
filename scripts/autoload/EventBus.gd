extends Node


signal camera_ready(camera: Camera2D)
signal terrain_generated_successfully()

signal cell_hidden(coords: Vector2i)
signal cell_revealed(coords: Vector2i)
signal cells_visibled(batch: Dictionary[Vector2i, bool])

signal spawn_requested(entity_type: StringName, pos: Vector2)
signal entity_spawned(entity: Node2D)
signal player_died()
signal entity_killed(entity: Node2D)
signal entity_destroyed(entity: Node2D)

signal anthurium_core_spawned(entity: Node2D)
signal anthurium_core_died()

signal item_put_into_inventory(item: Entity)
signal camera_target_changed(target: Node2D)

signal behavior_stimulus_event(event_name: GameEvent.Stimulus, context: Dictionary)

signal part_spawned(name: StringName)

signal part_destroyed(name: StringName)


signal gate_activated(position: Vector2)

signal clearing_grid()
