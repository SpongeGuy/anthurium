## Autoload: EventBus
##
## Global signal hub. Decouples systems that need to react to game events
## (spawning, world state, camera, UI) without holding direct references to
## each other; emit here, connect from anywhere.
extends Node

# initialization
## Emitted when a new game instance starts (see
## [method GameInterface.start_new_game_instance]).
signal starting_new_game()
## Emitted once the active [Camera2D] has been registered with
## [CameraController] and is ready to use.
signal camera_ready(camera: Camera2D)
## Emitted after [DungeonGenerator] finishes generating a new layout.
signal terrain_generated_successfully()

# entity lifecycle
## Emitted right before an entity is instantiated, before it exists in the
## world.
signal spawn_requested(entity_type: StringName, pos: Vector2)
## Emitted after an entity has been added to the world.
signal entity_spawned(entity: Node2D)
## Emitted when the current player entity dies.
signal player_died()
## Emitted when an entity dies (as opposed to being otherwise removed).
signal entity_killed(entity: Node2D)
## Emitted when an entity is removed from the world for any reason.
signal entity_destroyed(entity: Node2D)

# anthurium
## Emitted when the anthurium core entity is spawned.
signal anthurium_core_spawned(entity: Node2D)
## Emitted when the anthurium core dies.
signal anthurium_core_died()

# camera
## Emitted when [CameraController]'s follow target changes.
signal camera_target_changed(target: Node2D)

# fog
## Emitted when the fog-of-war's target changes.
signal fog_target_changed(target: Node2D)
## Emitted to request new pulse parameters for the fog effect.
signal change_fog_pulse_params(min: float, max: float, rate: float)

# inventories
## Emitted when an item is placed into an inventory.
signal item_put_into_inventory(item: Entity)

## Emitted when a behavior-relevant stimulus occurs, for creature AI
## ([code]lobes[/code]) to react to.
signal behavior_stimulus_event(event_name: GameEvent.Stimulus, context: Dictionary)

## Emitted when an anthurium part is spawned. Mirrors on [AnthuriumInterface]
## via [method AnthuriumInterface._on_part_spawned].
signal part_spawned(name: StringName)
## Emitted when an anthurium part is destroyed. Mirrors on
## [AnthuriumInterface] via [method AnthuriumInterface._on_part_destroyed].
signal part_destroyed(name: StringName)

# worldgrid
## Emitted when a tile becomes hidden (fog-of-war). Mirrors
## [signal WorldGrid.cell_hidden].
signal cell_hidden(coords: Vector2i)
## Emitted when a tile becomes revealed. Mirrors
## [signal WorldGrid.cell_revealed].
signal cell_revealed(coords: Vector2i)
## Emitted with a batch of tiles whose visibility changed together, from
## [WorldGrid]'s batching system.
signal cells_visibled(batch: Dictionary[Vector2i, bool])




signal gate_activated(position: Vector2)

signal clearing_grid()
