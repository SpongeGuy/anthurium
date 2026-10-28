extends Node

var logo_scenes: Array[PackedScene] = [
	load("uid://cs4i88vmrey4p")
]

var logo_voices: Array[VoiceProfile] = [
	load("uid://xfogely1wm48")
]


enum GameStatus { PLAYING, PAUSED }
enum AppStatus { BOOT, MENU, GAME, GAMEOVER }
enum MenuStatus { WORLD_DEMO, SCORES }
enum Controller { NONE, PLAYER, HAND, CAMERA, MENU_DEFAULT }
enum GameMode { QUEST }
var active_controller: Controller
var game_state: GameStatus
var app_state: AppStatus

var viewport_container: SubViewportContainer
var main_viewport: SubViewport
var logo_canvas_layer: CanvasLayer
var ui_canvas_layer: CanvasLayer
var title_screen_scene: PackedScene = load("uid://ck6muwdsbdym3")
var world_2d_scene: PackedScene = load("uid://c8bjpuv01on4i")

var container_2d: Node
var container_3d: Node
var world_2d: Node2D
var world_3d: Node3D
var camera_2d: Camera2D
var camera_3d: Camera3D

var fade_rect: ColorRect

var time: float = 0

signal game_state_changed(status: GameStatus)

signal game_started

var world_ready: bool = false

	


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
	
	switch_app_state(AppStatus.BOOT)


func _process(delta: float) -> void:
	time += delta
		
	if Input.is_key_pressed(KEY_E):
		switch_app_state(AppStatus.MENU, true)
		
	_handle_control_inputs(delta)
	
	if not app_state == AppStatus.BOOT:
		PlayerManager.control_selector(delta)
		PlayerManager.control_players(delta)


func _run_boot_sequence() -> void:
	Log.info("Booting...")
	Log.info("Welcome to Dreamland!")
	UiController.screen.set_message("")
	for i in range(logo_scenes.size()):
		await _show_logo(logo_scenes[i], logo_voices[i], 2.5, 0.7, 0.4)
	#await _fade(1.0, 0.6)
	UiController.screen.set_bg_visible(false)
	
	
	switch_app_state(AppStatus.MENU)
	
	await _wait_for_ui()
	
	



func _initialize_world() -> void:
	world_2d = change_scene_and_wait(container_2d, world_2d_scene)
	camera_2d = Camera2D.new()
	world_2d.add_child(camera_2d)
	world_2d.process_mode = Node.PROCESS_MODE_PAUSABLE
	CameraController.reset()
	CameraController.register_camera(camera_2d)
	AudioManager.register_camera(camera_2d)
	
	EntityManager.register_ysort_entity_container(world_2d.find_child("YSort", true, false))
	EntityManager.destroy_all_entities()
	

func change_active_controller(controller: Controller) -> void:
	active_controller = controller
	match controller:
		Controller.CAMERA:
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_PLAYER)
		
## As of 2026-10-01, this function is really only used to control pausing the game.
## [member GameStatus.PAUSED] raises the UI bar to expose additional inventory information using [UiController] and pauses processes on the tree.[br]
## [member GameStatus.PLAYING] sets the UI bar to default position and unpauses the tree.[br]
## Note: the UILayer CanvasLayer is set to always process so the ui does not freeze when the tree is paused.
func switch_game_state(status: GameStatus) -> void:
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


func switch_menu_state(status: MenuStatus) -> void:
	pass


## Main orchestrator for the app, switches from different modes and GUIs.
## Controls the camera through [CameraController]'s [method set_behavior_mode].[br]
## [member AppStatus.BOOT] runs the boot sequence, which scans all the resource directories.[br]
## [member AppStatus.MENU] starts a new run without the player and summons the ui scenes
func switch_app_state(status: AppStatus, forcing: bool = false) -> void:
	app_state = status
	world_ready = false
	match status:
		AppStatus.BOOT:
			UiController.hand.visible = false
			_run_boot_sequence()
			switch_game_mode(GameMode.QUEST)
		AppStatus.MENU:
			_initialize_world()
			GameInterface.background_mode = true
			GameInterface.start_new_run(randi_range(0, 9), randi())
			await _wait_for_ui()
			CameraController.set_behavior_mode(CameraController.Behavior.CENTERED, 0.0, true)
			UiController.clear_stages()
			_fade(0, 1.6)
			MusicController.load_layer_from_path(MusicController.Layer.MELODY, "uid://d0jg8nqdq5mfp")
			MusicController.play(true)
			UiController.hud.set_state(UIHUD.State.INACTIVE)
			change_active_controller(Controller.MENU_DEFAULT)
			#UiController.hand.switch_stages(UiController.add_stage("title"))
			UiController.add_stage("arcade_title")
		AppStatus.GAME:
			GameInterface.background_mode = false
			await _fade(1, 0.6)
			UiController.clear_stages()
			MusicController.stop()
			_initialize_world()
			#_link_player_death()
			CameraController.set_behavior_mode(CameraController.Behavior.CENTERED, 0.0, true)
			GameInterface.start_new_run(0, randi())
			#GameInterface.start_debug_platform()
			switch_game_state(GameStatus.PLAYING)
			change_active_controller(Controller.PLAYER)
			UiController.hand.go_invisible()
			await _fade(0, 0.5)
			world_ready = true
			game_started.emit()
		AppStatus.GAMEOVER:
			GameInterface.background_mode = true
			CameraController.set_behavior_mode(CameraController.Behavior.TRACKING_RANDOM, 5.0)
			UiController.hud.set_state(UIHUD.State.INACTIVE)
			change_active_controller(Controller.NONE)
			UiController.hand.visible = false # REPLACE THIS WITH SETTING THE STAGE FOR UI
	
	


func switch_game_mode(to: GameMode) -> void:
	match to:
		GameMode.QUEST:
			GameInterface.active_level_gen = load("uid://bmt0fkah08ra7") # default_level_generator
			GameInterface.active_spawn_cfg = load("uid://ber8fdp8shydu") # default_spawn_director_config

func toggle_pause() -> void:
	if game_state == GameStatus.PLAYING:
		switch_game_state(GameStatus.PAUSED)
		
	elif game_state == GameStatus.PAUSED:
		switch_game_state(GameStatus.PLAYING)
		

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
	

func clear_scene(container: Node) -> void:
	container.get_child(0).queue_free()


func load_game() -> void:
	EntityManager.clear_cache()




	
func initialize_main_menu() -> void:
	var title: Node3D = title_screen_scene.instantiate()
	main_viewport.add_child(title)
	title.camera.make_current()




# -----------------------------------
# utility stuff
# -----------------------------------

func _link_player_death() -> void:
	PlayerManager.player_died.connect(_on_player_death, CONNECT_ONE_SHOT)

func _on_player_death(_slot: int, _e: Entity) -> void:
	if not PlayerManager.slot_states.values().has(PlayerManager.SlotState.PLAYING):
		switch_app_state(AppStatus.GAMEOVER)
	
func _wait_for_ui() -> void:
	if not UiController.is_ready:
		await UiController.ui_ready

func _create_fade_overlay() -> void:
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_canvas_layer.add_child(fade_rect)

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
		
func _fade(target_alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished


func _handle_control_inputs(delta: float) -> void:
	match active_controller:
		Controller.HAND:
			UiController.hand.control(delta)
		Controller.CAMERA:
			CameraController.directly_control(delta)



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
