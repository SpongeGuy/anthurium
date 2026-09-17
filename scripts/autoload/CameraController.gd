## Autoload: CameraController
##
## Owns the active [Camera2D] and drives its position each frame according to
## [member behavior]: following the player, drifting between random entities,
## sitting frozen, or taking raw directional input. Also handles screen-shake
## trauma and nudges [WorldGrid] to reveal tiles the camera target is
## standing on if they were marked invisible.
extends Component

## Smoothing factor used by [method go_to] when following [member target_position].
var lerp_weight: float = 5.0
## Debug voice profile, currently unused in the reachable code paths.
var debug_sound: VoiceProfile
## The active camera this controller drives. Set via [method register_camera].
var camera: Camera2D

## The [Node2D] currently being followed when [member behavior] is
## [constant Behavior.TRACKING_PLAYER] or [constant Behavior.TRACKING_RANDOM].
var target: Node2D
## Current camera behavior mode. See [enum Behavior].
var behavior: Behavior
## Cached world position of [member target], updated every [method _process].
var target_position: Vector2

## Camera movement modes.
## [br][constant TRACKING_PLAYER]: follow [member target] continuously.
## [br][constant TRACKING_RANDOM]: periodically retarget to a random active
## entity and follow it (used for menu/attract-mode drift).
## [br][constant FROZEN]: camera does not move.
## [br][constant CONTROLLED]: camera moves via direct input, see
## [method directly_control].
enum Behavior{ TRACKING_PLAYER, TRACKING_RANDOM, FROZEN, CONTROLLED, CENTERED }


## Emitted when a new random target is acquired (currently unused/reserved).
signal found_target


## How long, in seconds, [constant Behavior.TRACKING_RANDOM] waits before
## picking a new random target.
var tracking_random_patience: float = 5.0
var _tracking_random_timer: float = 0.0
var _delay_timer: float = 0.0
## Tween used to delay a behavior-mode switch (see [method set_behavior_mode]).
var delay_tween: Tween

var _visibility_timer: float = 0.0
## How often, in seconds, [method _fix_if_standing_on_invisible] checks
## whether the target is standing on a hidden tile.
var visibility_check_interval: float = 0.5

	
## Updates the cached mouse position (in world space) and
## [member target_position] each frame, and runs debug tile-painting input
## handlers.
func _process(delta: float) -> void:
	if not camera:
		return
	relative_mouse_coords = get_viewport().get_mouse_position()
	relative_mouse_coords = (relative_mouse_coords /3 + camera.position - Vector2(320, 180))
	
	
	debug_handlers()

## Drives camera movement, screen shake, and the invisible-tile fixup each
## physics frame.
func _physics_process(delta: float) -> void:
	if not camera:
		return
	_handle_camera_behavior(delta)
	_handle_screen_shake(delta)
	_periodically_reveal_target(delta)
	
	
## Periodically checks whether [member target] is standing on a tile marked
## invisible in [WorldGrid] and, if so, forces a reveal from that tile. If
## there is no target, keeps revealing from the camera instead.
func _periodically_reveal_target(delta: float) -> void:
	_visibility_timer += delta
	if _visibility_timer >= visibility_check_interval:
		_visibility_timer = 0
		reveal_target()
			
func reveal_target() -> void:
	if not target:
		reveal_from_camera()
		return
	var tile_pos: Vector2i = WorldGrid.world_to_tile(target.global_position)
	var occupying_cell: CellData = WorldGrid.get_cell(tile_pos)
	if not occupying_cell:
		return
	if occupying_cell.invisible:
		WorldGrid.reveal_from(tile_pos)

## Reveals fog-of-war outward from wherever [CameraController] is currently
## targeting, awaiting [signal EventBus.camera_target_changed] first if no
## target is set yet.
func reveal_from_camera() -> void:
	if not target_position:
		await EventBus.camera_target_changed
	WorldGrid.reveal_from(WorldGrid.world_to_tile(target_position))
			
## Moves [member target_position] directly from raw movement input. Used
## when [member behavior] is [constant Behavior.CONTROLLED].
func directly_control(delta: float) -> void:
	var magnitude: float = 150.0
	var move_input_direction = Input.get_vector("west", "east", "north", "south")
	target_position += move_input_direction * magnitude * delta

## Switches [member behavior] to [param b]. If [param delay] is greater than
## zero, the switch to [param b] is deferred by that many seconds via a
## tween (any previously pending delayed switch is cancelled first).
## Entering [constant Behavior.CONTROLLED] clears [member target].
func set_behavior_mode(b: Behavior, delay: float = 0.0) -> void:
	behavior = b
	if delay_tween:
		delay_tween.kill()
		_delay_timer = 0
	match b:
		Behavior.TRACKING_RANDOM:
			delay_tween = create_tween()
			delay_tween.tween_property(self, "_delay_timer", delay, delay)
			delay_tween.tween_callback((func(b: Behavior): behavior = b).bind(b))
		Behavior.CONTROLLED:
			target = null
		Behavior.CENTERED:
			target_position = WorldGrid.tile_to_world(WorldGrid.get_center())
			
## Clears the current target and resets tracking state (used when tearing
## down/reinitializing a scene).
func reset() -> void:
	target = null
	target_position = Vector2.ZERO
	behavior = 2
	_delay_timer = 0


## Registers [param c] as the active camera and makes it current. Call this
## once a [Camera2D] exists in the world (see
## [code]AppController._initialize_world()[/code]).
func register_camera(c: Camera2D) -> void:
	Log.info("Camera %s registered." % c)
	camera = c
	camera.make_current()

## Sets [member target] to [param new_target], snaps [member target_position]
## to it, and re-reveals [WorldGrid] fog-of-war from the new target's tile.
## Emits [signal EventBus.camera_target_changed].
func set_camera_target(new_target: Node2D) -> void:
	if not new_target:
		return
	target = new_target
	target_position = target.global_position
	WorldGrid.hide_map()
	WorldGrid.reveal_from(WorldGrid.world_to_tile(new_target.global_position))
	EventBus.camera_target_changed.emit(target)

## Smoothly moves [member camera] toward [param pos] at [member lerp_weight].
func go_to(pos: Vector2, delta: float) -> void:
	camera.position = lerp(camera.position, pos, delta * lerp_weight)

## Snaps [member camera] instantly to [param pos]. No-op if no camera is
## registered.
func go_instantly_to(pos: Vector2) -> void:
	if not camera:
		return
	camera.position = pos

# ---------------------------------------
# mouse position
# ---------------------------------------

## Mouse position converted into the camera's local/world-relative space,
## updated every [method _process]. Used by debug tile-painting.
var relative_mouse_coords: Vector2

## Returns the mouse position in world space, or [constant Vector2.ZERO] if
## no camera is registered.
func get_world_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_global_mouse_position()

## Returns the mouse position in viewport (screen) space, or
## [constant Vector2.ZERO] if no camera is registered.
func get_screen_mouse_position() -> Vector2:
	if not camera:
		return Vector2.ZERO
	return camera.get_viewport().get_mouse_position()




# -------------------------------------------
# screen shake
# ------------------------------------------
## Current shake intensity, in the range [code][0, 1][/code]. Decays toward
## zero at [member trauma_decay] per second; the visible shake offset scales
## with [code]trauma * trauma[/code] for a punchier falloff.
var trauma: float = 0
## How quickly [member trauma] decays per second.
var trauma_decay: float = 1
## Maximum pixel offset applied to the camera at full trauma.
var max_shake_offset: float = 18.0
## Distance beyond which [method add_trauma_distance] contributes no shake.
var trauma_falloff_range: float = 400.0

## Adds [param amount] to [member trauma], clamped to [code][0, 1][/code].
func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0, 1)
	
## Adds trauma from an event at [param position], falling off linearly with
## distance from the camera up to [member trauma_falloff_range]. No-op if no
## camera is registered.
func add_trauma_distance(position: Vector2, amount: float) -> void:
	if not camera:
		return
	var dist: float = camera.global_position.distance_to(position)
	var falloff: float = 1.0 - clamp(dist / trauma_falloff_range, 0.0, 1.0)
	add_trauma(amount * falloff)



# ---------------------------------
# debug
# -----------------------------------
## Debug hotkeys for painting terrain under the mouse cursor
## ([code]debug_1[/code] paints stone wall, [code]debug_2[/code] paints soil
## ground).
func debug_handlers() -> void:
	var tile_coords: Vector2i = WorldGrid.world_to_tile(relative_mouse_coords)
	if Input.is_action_just_pressed("debug_1"):
		WorldGrid.set_cell_type(tile_coords, &"wall_stone")
		#BFXR.PlayRandom()
		#WorldGrid.set_circle(tile_coords, 2, cell)

	if Input.is_action_just_pressed("debug_2"):
		WorldGrid.set_cell_type(tile_coords, &"ground_soil")
		#WorldGrid.set_circle(tile_coords, 2, cell)


# --------------------------------
# private eyes
# ------------------------------

## Applies the current [member behavior] each physics frame: follows
## [member target_position] directly, or (for
## [constant Behavior.TRACKING_RANDOM]) periodically retargets to a random
## active entity before following it.
func _handle_camera_behavior(delta: float) -> void:
	match behavior:
		Behavior.TRACKING_PLAYER:
			if not target:
				return
			target_position = target.global_position
			go_to(target_position, delta)
		Behavior.TRACKING_RANDOM:
			_tracking_random_timer -= delta
			if _tracking_random_timer <= 0.0:
				var random_entity: Entity = EntityManager.active_entities.pick_random()
				set_camera_target(random_entity)
				_tracking_random_timer = tracking_random_patience + randf_range(-2, 2)
			if not target:
				return
			target_position = target.global_position
			go_to(target_position, delta)
		Behavior.CENTERED:
			if not target_position:
				return
			go_to(target_position, delta)
				
#func _reveal_target(delta: float) -> void:
	
				
## Decays [member trauma] and applies a random offset to [member camera]
## scaled by [code]trauma * trauma[/code].
func _handle_screen_shake(delta: float) -> void:
	trauma = move_toward(trauma, 0.0, trauma_decay * delta)
	var intensity: float = trauma * trauma
	
	camera.offset = Vector2(
		randf_range(-1, 1) * max_shake_offset * intensity, 
		randf_range(-1, 1) * max_shake_offset * intensity
	)
