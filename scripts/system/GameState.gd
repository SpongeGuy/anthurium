extends Node

# -------------------------------------------
# autoload 
#
# -------------------------------------------


enum Status { LOADING, PLAYING, PAUSED, GAME_OVER }

var state: Status = Status.LOADING
var game_score: int = 0
var nutri_score: int = 0

var player: Entity
var anthurium_cores: Array[Entity]

var time: float = 0.0

signal game_state_changed(status: Status)

func change_game_state(status: Status) -> void:
	state = status
	game_state_changed.emit(state)

func _ready() -> void:
	EventBus.added_game_score_to.connect(_check_if_game_score_player)
	EventBus.added_nutri_score_to.connect(_check_if_nutri_score_player)
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.anthurium_core_spawned.connect(_on_anthurium_core_spawned)
	
func _process(delta: float) -> void:
	time += delta
	
func _check_if_game_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		game_score += amount
	
func _check_if_nutri_score_player(subject: Entity, amount: int, source: Entity) -> void:
	if subject == player:
		nutri_score += amount
	HUDParticleController.collect(source.global_position, UIHUD.score_collect_pos, floor(amount / 10), Color.LAWN_GREEN)

func _on_player_spawned(entity: Entity) -> void:
	CameraController.change_camera_target(entity)
	WeatherController.change_fog_target(entity)
	player = entity

func _on_anthurium_core_spawned(entity: Entity) -> void:
	if entity not in anthurium_cores:
		anthurium_cores.append(entity)

