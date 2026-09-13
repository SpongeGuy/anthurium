## Autoload: AppController
##
## Orchestrates the external shell of the application: boot sequence,
## top-level app state ([enum AppStatus]) and in-game pause state
## ([enum GameStatus]), which input source is currently driving gameplay
## ([enum Controller]), scene container/viewport wiring, and screen fades.
## This is the entry point most other autoloads are wired up from; see
## [method _ready].
extends Node

## Orchestrates the external shell of the application.
## Logo scenes shown in sequence during [method _run_boot_sequence].
var logo_scenes: Array[PackedScene] = [
	load("uid://cs4i88vmrey4p")
]
## Voice/sound played alongside each entry in [member logo_scenes], by index.
var logo_voices: Array[VoiceProfile] = [
	load("uid://xfogely1wm48")
]


## Whether gameplay is currently playing or paused.
enum GameStatus { PLAYING, PAUSED }
## Top-level phase of the application.
enum AppStatus { BOOT, MENU, GAME, GAMEOVER }
## Which input source is currently allowed to drive movement/actions.
enum Controller { NONE, PLAYER, HAND, CAMERA }
## The currently active input controller. See [enum Controller].
var active_controller: Controller
## Current play/pause state. Only meaningful while [member app_state] is
## [constant AppStatus.GAME].
var game_state: GameStatus
## Current top-level app phase. See [enum AppStatus].
var app_state: AppStatus

## The container wrapping the main viewport, found via [method _retrieve_references].
var viewport_container: SubViewportContainer
## The main game [SubViewport], found via [method _retrieve_references].
var main_viewport: SubViewport
## Canvas layer the boot logo sequence is drawn on.
var logo_canvas_layer: CanvasLayer
## Canvas layer general UI is drawn on.
var ui_canvas_layer: CanvasLayer
## Title-screen scene, instantiated by [method initialize_main_menu].
var title_screen_scene: PackedScene = load("uid://ck6muwdsbdym3")
## The 2D world scene instantiated into [member container_2d] on
## [method _initialize_world].
var world_2d_scene: PackedScene = load("uid://c8bjpuv01on4i")

## Parent node for the active 2D world scene.
var container_2d: Node
## Parent node for the active 3D world scene (e.g. the title screen).
var container_3d: Node
## The currently active 2D world root, set by [method _initialize_world].
var world_2d: Node2D
## Reserved for an active 3D world root; currently unused beyond its
## declaration.
var world_3d: Node3D
## The gameplay camera created in [method _initialize_world].
var camera_2d: Camera2D
## Reserved for a 3D camera; currently unused beyond its declaration.
var camera_3d: Camera3D

## Full-screen overlay used for fade transitions. Created by
## [method _create_fade_overlay].
var fade_rect: ColorRect

## Accumulated in-game time, in seconds, advanced every [method _process].
## Used by [Log] to timestamp messages.
var time: float = 0

## Emitted whenever [method change_game_state] applies a new
## [enum GameStatus].
signal game_state_changed(status: GameStatus)


	

## Entry point for the whole application shell: initializes logging, finds
## scene references, builds the fade overlay, scans every content registry
## ([EntityRegistry], [CellTypeRegistry], [AccessoryArchetypeRegistry],
## [BloomEventRegistry]), wires up [UiController], and kicks off the boot
## sequence via [method change_app_state].
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Log.initialize()
	_retrieve_references()
	_create_fade_overlay()
	
	EntityRegistry.scan_all()
	CellTypeRegistry.scan_all()
	AccessoryArchetypeRegistry.scan_all()
	BloomEventRegistry.scan_all()
	UiController.retrieve_references(main_viewport)
	
	change_app_state(AppStatus.BOOT)

## Plays through the studio/game logos with fade in/out and voice stings,
## fades the boot screen out, then transitions to [constant AppStatus.MENU].
func _run_boot_sequence() -> void:
	Log.info("Booting...")
	Log.info("Welcome to Dreamland!")
	UiController.screen.set_message("")
	for i in range(logo_scenes.size()):
		await _show_logo(logo_scenes[i], logo_voices[i], 2.5, 0.7, 0.4)
	await _fade(1.0, 0.6)
	UiController.screen.set_bg_visible(false)
	
	
	change_app_state(AppStatus.MENU)
	
	await _wait_for_ui()
	
	







## Instantiates a fresh 2D world into [member container_2d], creates and
## registers its camera with [CameraController], hooks up the entity
## y-sort container with [EntityManager], and clears any existing active
## entities.
func _initialize_world() -> void:
	world_2d = change_scene_and_wait(container_2d, world_2d_scene)
	camera_2d = Camera2D.new()
	world_2d.add_child(camera_2d)
	world_2d.process_mode = Node.PROCESS_MODE_PAUSABLE
	#CameraController.reset()
	CameraController.register_camera(camera_2d)
	
	EntityManager.register_ysort_entity_container(world_2d.find_child("YSort", true, false))
	EntityManager.destroy_all()
	
## Sets [member active_controller] to [param controller], additionally
## switching [CameraController] into player-tracking mode when
## [param controller] is [constant Controller.CAMERA].
func change_active_controller(controller: Controller) -> void:
	active_controller = controller
	match controller:
		Controller.CAMERA:
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_PLAYER)
		
## Sets [member game_state] to [param status] and applies the associated UI/
## pause/camera-control changes (no-op unless [member app_state] is
## [constant AppStatus.GAME]). Emits [signal game_state_changed].
func change_game_state(status: GameStatus) -> void:
	if not app_state == AppStatus.GAME:
		return
	game_state = status
	match status:
		GameStatus.PAUSED:
			_wait_for_ui()
			change_active_controller(Controller.HAND)
			get_tree().paused = true
			UiController.hud.set_state(UIHUD.State.ACTIVE)
			UiController.hand.switch_stages(UiController.hud)
		GameStatus.PLAYING:
			_wait_for_ui()
			get_tree().paused = false
			change_active_controller(Controller.PLAYER)
			UiController.hud.set_state(UIHUD.State.BAR)
			UiController.hand.go_invisible()
	game_state_changed.emit(game_state)
	
## Advances [member time], handles the pause-toggle and debug menu-return
## hotkeys, and forwards per-frame input to whichever controller is active
## via [method _handle_control_inputs].
func _process(delta: float) -> void:
	time += delta
	if Input.is_action_just_pressed("start"):
		toggle_pause()
		
	if Input.is_key_pressed(KEY_E):
		change_app_state(AppStatus.MENU, true)
		
	_handle_control_inputs(delta)
	
	#match app_state:
		#AppStatus.GAMEOVER:
			#world_2d.global_position += Vector2(sin((time)) * 1, -sin((time + PI/3)) * 1)

## Transitions the app into [param status], running that phase's setup:
## [constant AppStatus.BOOT] runs the boot sequence, [constant AppStatus.MENU]
## reinitializes the world and title UI, [constant AppStatus.GAME] fades in
## a fresh game instance and hands control to the player, and
## [constant AppStatus.GAMEOVER] freezes control and drifts the camera.
## [param forcing] skips restarting an already-active game instance when
## re-entering the menu.
func change_app_state(status: AppStatus, forcing: bool = false) -> void:
	match status:
		AppStatus.BOOT:
			UiController.hand.visible = false
			_run_boot_sequence()
		AppStatus.MENU:
			_initialize_world()
			if not (GameInterface.game_instance_active and !forcing):
				GameInterface.start_new_game_instance()
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_RANDOM)
			await _wait_for_ui()
			_fade(0, 1.6)
			MusicController.load_layer_from_path(MusicController.Layer.MELODY, "uid://d0jg8nqdq5mfp")
			MusicController.play(true)
			UiController.hud.set_state(UIHUD.State.INACTIVE)
			change_active_controller(Controller.HAND)
			UiController.hand.switch_stages(UiController.add_stage("title"))
		AppStatus.GAME:
			MusicController.stop()
			await _fade(1, 0.6)
			_fade(1, 0.2)
			_initialize_world()
			GameInterface.start_new_game_instance_with_player()
			
			_link_player_death()
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_PLAYER)
			change_game_state(GameStatus.PLAYING)
			change_active_controller(Controller.PLAYER)
			UiController.hand.go_invisible()
			UiController.remove_stage("title")
			UiController.hud.set_state(UIHUD.State.BAR)
			_fade(0, 0.5)
		AppStatus.GAMEOVER:
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_RANDOM, 5.0)
			UiController.hud.set_state(UIHUD.State.INACTIVE)
			change_active_controller(Controller.NONE)
			UiController.hand.visible = true # REPLACE THIS WITH SETTING THE STAGE FOR UI
	
	app_state = status


## Toggles [member game_state] between [constant GameStatus.PLAYING] and
## [constant GameStatus.PAUSED].
func toggle_pause() -> void:
	if game_state == GameStatus.PLAYING:
		change_game_state(GameStatus.PAUSED)
		
	elif game_state == GameStatus.PAUSED:
		change_game_state(GameStatus.PLAYING)
		

## Instantiates [param scene] under [param container], freeing whatever
## scene was previously the sole child. Returns the new scene instance.
func change_scene_and_wait(container: Node, scene: PackedScene) -> Node:
	Log.info("Changing scene to %s" % scene)
	var old_scene
	if container.get_child_count() > 0:
		old_scene = container.get_child(0)
	var new_scene := scene.instantiate()
	if old_scene:
		old_scene.queue_free()
	container.add_child(new_scene)
	return new_scene
	
## Frees the first (only expected) child of [param container].
func clear_scene(container: Node) -> void:
	container.get_child(0).queue_free()

## Clears [EntityManager]'s instantiated-scene cache. Currently the only
## step performed for a "load"; save/load persistence itself is not yet
## implemented here.
func load_game() -> void:
	EntityManager.clear_cache()




	

## Instantiates [member title_screen_scene] directly into
## [member main_viewport] and makes its camera current. Currently unused by
## [method change_app_state]'s menu flow, which uses [method _initialize_world]
## and a [UIStage] instead.
func initialize_main_menu() -> void:
	var title: Node3D = title_screen_scene.instantiate()
	main_viewport.add_child(title)
	title.camera.make_current()




# -----------------------------------
# utility stuff
# -----------------------------------

## Connects the current player's death (one-shot) to
## [method _on_player_death], so the app transitions to
## [constant AppStatus.GAMEOVER] automatically when they die.
func _link_player_death() -> void:
	PlayerManager.player_died.connect(_on_player_death, CONNECT_ONE_SHOT)

## Connected (one-shot) to [signal PlayerManager.player_died]; transitions
## the app to [constant AppStatus.GAMEOVER].
func _on_player_death(_e: Entity) -> void:
	change_app_state(AppStatus.GAMEOVER)
	
## Awaits [signal UiController.ui_ready] if [UiController] hasn't finished
## retrieving its references yet; otherwise returns immediately.
func _wait_for_ui() -> void:
	if not UiController.is_ready:
		await UiController.ui_ready

## Creates the full-screen black [ColorRect] used for fade transitions and
## parents it under [member logo_canvas_layer], starting fully transparent.
func _create_fade_overlay() -> void:
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_canvas_layer.add_child(fade_rect)

## Instantiates [param scene] as a logo, fades it in over
## [param fade_in_time], plays [param voice] once visible, holds for
## [param hold_time], then fades it out over [param fade_out_time] and frees
## it. Used in sequence by [method _run_boot_sequence].
func _show_logo(scene: PackedScene, voice: VoiceProfile = null, hold_time: float = 1.5, fade_in_time: float = 0.4, fade_out_time: float = 0.4) -> void:
	var logo: Control = scene.instantiate()
	logo.modulate.a = 0.0
	logo_canvas_layer.add_child(logo)
	var tween_in: Tween = create_tween()
	tween_in.tween_property(logo, "modulate:a", 1.0, fade_in_time)
	await tween_in.finished
	AudioManager.play_voice(voice, null, true, false)
	await get_tree().create_timer(hold_time).timeout
	var tween_out: Tween = create_tween()
	tween_out.tween_property(logo, "modulate:a", 0.0, fade_out_time)
	await tween_out.finished
	logo.queue_free()
		
## Tweens [member fade_rect]'s opacity to [param target_alpha] over
## [param duration] seconds and awaits completion.
func _fade(target_alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished


## Forwards per-frame control to whichever system owns input right now,
## based on [member active_controller]: the player entity, the UI hand
## cursor, or the free camera.
func _handle_control_inputs(delta: float) -> void:
	match active_controller:
		Controller.PLAYER:
			PlayerManager.control_player(delta)
		Controller.HAND:
			UiController.hand.control(delta)
		Controller.CAMERA:
			CameraController.directly_control(delta)


## Locates the scene-tree nodes this controller depends on
## ([code]Container2D[/code], [code]Container3D[/code],
## [code]SubViewportContainer[/code], [code]MainViewport[/code],
## [code]UI_Layer[/code], [code]Logo_Layer[/code]), logging success/failure
## for the containers and configuring the UI/logo canvas layers to keep
## processing while the game is paused.
func _retrieve_references() -> void:
	var root: Node = get_tree().root
	container_2d = root.find_child("Container2D", true, false)
	container_3d = root.find_child("Container3D", true, false)
	if container_2d and container_3d:
		Log.info("Found containers successfully.")
	else:
		Log.error("An issue occurred finding containers.")
		
	viewport_container = root.find_child("SubViewportContainer", true, false)
	main_viewport = root.find_child("MainViewport", true, false)
	ui_canvas_layer = root.find_child("UI_Layer", true, false)
	if ui_canvas_layer:
		ui_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		UiController.ui_canvas_layer = ui_canvas_layer
	logo_canvas_layer = root.find_child("Logo_Layer", true, false)
	if logo_canvas_layer:
		logo_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
