extends Node

# -------------------------------------------
# autoload 
#
# -------------------------------------------


enum Status { LOADING, PLAYING, PAUSED, GAME_OVER }

var state: Status = Status.LOADING
var opal_score: int = 0
var aura_score: int = 0

var player: Entity
var anthurium_cores: Array[Entity]

var time: float = 0.0

var hud: UIHUD

var world: Node2D

signal game_state_changed(status: Status)

func change_game_state(status: Status) -> void:
	state = status
	game_state_changed.emit(state)
	_on_state_changed(state)

func _ready() -> void:
	EventBus.added_opal_score_to.connect(_check_if_opal_score_player)
	EventBus.added_aura_score_to.connect(_check_if_aura_score_player)
	PlayerManager.player_set.connect(_on_player_set)
	EventBus.anthurium_core_spawned.connect(_on_anthurium_core_spawned)
	
func _process(delta: float) -> void:
	time += delta
	
	if Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("start"):
		toggle_pause()
	
func _check_if_opal_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		opal_score += amount
	
func _check_if_aura_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		aura_score += amount
	
func _on_player_set(entity: Entity) -> void:
	CameraController.change_camera_target(entity)
	CameraController.go_instantly_to(entity.global_position)
	WeatherController.change_fog_target(entity)
	player = entity
	

func _on_anthurium_core_spawned(entity: Entity) -> void:
	if entity not in anthurium_cores:
		anthurium_cores.append(entity)


func toggle_pause() -> void:
	if state == Status.PLAYING:
		change_game_state(Status.PAUSED)
	elif state == Status.PAUSED:
		change_game_state(Status.PLAYING)
		
func _on_state_changed(status: Status) -> void:
	match status:
		Status.PAUSED:
			world.process_mode = Node.PROCESS_MODE_DISABLED
		Status.PLAYING:
			world.process_mode = Node.PROCESS_MODE_PAUSABLE
