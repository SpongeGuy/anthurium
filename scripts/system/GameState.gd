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

func _ready() -> void:
	EventBus.added_opal_score_to.connect(_check_if_opal_score_player)
	EventBus.added_aura_score_to.connect(_check_if_aura_score_player)
	PlayerManager.player_set.connect(_on_player_set)
	EventBus.anthurium_core_spawned.connect(_on_anthurium_core_spawned)
	
func _process(delta: float) -> void:
	time += delta
	
	if Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()
	
func _check_if_opal_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		opal_score += amount
	
func _check_if_aura_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		aura_score += amount
	
func _on_player_set(entity: Entity) -> void:
	CameraController.change_camera_target(entity)
	WeatherController.change_fog_target(entity)
	player = entity

func _on_anthurium_core_spawned(entity: Entity) -> void:
	if entity not in anthurium_cores:
		anthurium_cores.append(entity)


func toggle_pause_menu() -> void:
	var next_hud_state: UIHUD.State = hud.toggle_hud_state()
	if next_hud_state == UIHUD.State.BAR:
		world.process_mode = Node.PROCESS_MODE_PAUSABLE
		state = Status.PLAYING
	elif next_hud_state == UIHUD.State.MENU:
		world.process_mode = Node.PROCESS_MODE_DISABLED
		state = Status.PAUSED

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("start"):
		toggle_pause_menu()
		
