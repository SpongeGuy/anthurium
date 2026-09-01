extends Node

## Orchestrates the external shell of the application.


enum GameStatus { PLAYING, PAUSED }
enum AppStatus { MENU, GAME }
var game_state: GameStatus
var app_state: AppStatus

var main_viewport: SubViewport
var title_screen_scene: PackedScene = load("uid://ck6muwdsbdym3")
var world_2d_scene: PackedScene = load("uid://c8bjpuv01on4i")

var container_2d: Node
var container_3d: Node
var world_2d: Node2D
var world_3d: Node3D
var camera_2d: Camera2D
var camera_3d: Camera3D

var time: float = 0

signal game_state_changed(status: GameStatus)

func change_game_state(status: GameStatus) -> void:
	game_state = status
	game_state_changed.emit(game_state)
	
func change_app_state(status: AppStatus) -> void:
	match status:
		AppStatus.MENU:
			pass
		AppStatus.GAME:
			_initialize_game()
	

func _ready() -> void:
	Log.initialize()
	Log.info("Game starting...")
	EntityRegistry.scan_all()
	CellTypeRegistry.scan_all()
	AccessoryArchetypeRegistry.scan_all()
	BloomEventRegistry.scan_all()
	_retrieve_references()
	
	await get_tree().process_frame
	
	
	change_app_state(AppStatus.GAME)
	change_game_state(GameStatus.PLAYING)






func _initialize_game() -> void:
	world_2d = change_scene_and_wait(container_2d, world_2d_scene)
	camera_2d = Camera2D.new()
	world_2d.add_child(camera_2d)
	CameraController.register_camera(camera_2d)
	UiController.retrieve_references(main_viewport)
	EntityManager.register_ysort_entity_container(world_2d.find_child("YSort", true, false))
	GameInterface.start_new_game_instance()
	
	


func _retrieve_references() -> void:
	var root: Node = get_tree().root
	container_2d = root.find_child("Container2D", true, false)
	container_3d = root.find_child("Container3D", true, false)
	if container_2d and container_3d:
		Log.info("Found containers successfully.")
	else:
		Log.error("An issue occurred finding containers.")
		
	main_viewport = root.find_child("MainViewport", true, false)
	


func toggle_pause() -> void:
	if game_state == GameStatus.PLAYING:
		change_game_state(GameStatus.PAUSED)
	elif game_state == GameStatus.PAUSED:
		change_game_state(GameStatus.PLAYING)


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
	


func game_process(delta: float) -> void:
	PlayerManager.control_player(delta)


func _process(delta: float) -> void:
	time += delta
	if Input.is_action_just_pressed("start"):
		toggle_pause()
		
	if Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()


func initialize_main_menu() -> void:
	var title: Node3D = title_screen_scene.instantiate()
	main_viewport.add_child(title)
	title.camera.make_current()
