extends Node
class_name UIController

@export var hud: UIHUD
@export var gameview: UIGameView
@export var screen: UIScreen

var _health_component: HealthComponent
var _ichor_component: IchorComponent

@export var ability_missing: Texture2D

func _ready() -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)
	EventBus.day_state_changed.connect(_on_day_state_changed)
	PlayerManager.player_set.connect(_on_player_set)
	EventBus.added_opal_score_to.connect(_on_opal_score_added)
	EventBus.added_aura_score_to.connect(_on_aura_score_added)
	
	


	
func _on_game_state_changed(status: GameState.Status) -> void:
	match status:
		GameState.Status.LOADING:
			_enter_loading()
		GameState.Status.PLAYING:
			_enter_playing()
		GameState.Status.PAUSED:
			_enter_paused()
		GameState.Status.GAME_OVER:
			_enter_game_over()
			
func _enter_loading() -> void:
	_set_all_invisible()
	screen.visible = true
	screen.bg_color.color = Color.BLACK
	screen.central_message.text = "Loading..."
	
func _enter_playing() -> void:
	_set_all_invisible()
	gameview.visible = true
	hud.visible = true
	hud.go_to_bar_state()
	
func _enter_paused() -> void:
	hud.go_to_menu_state()
	
func _enter_game_over() -> void:
	pass #TODO
	
func _set_all_invisible() -> void:
	hud.visible = false
	gameview.visible = false
	screen.visible = false			

# -------------------------
# player binding
# --------------------------


func _on_player_set(entity: Entity) -> void:
	if _health_component:
		_health_component.health_changed.disconnect(_on_health_changed)
	if _ichor_component:
		_ichor_component.ichor_changed.disconnect(_on_ichor_changed)
		
	_health_component = entity.get_component(HealthComponent)
	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)

	_ichor_component = entity.get_component(IchorComponent)
	if _ichor_component:
		_ichor_component.ichor_changed.connect(_on_ichor_changed)
	

	
func _on_health_changed(value: float, max_value: float) -> void:
	hud.update_health(value / max_value)

func _on_ichor_changed(value: float, max_value: float) -> void:
	hud.update_ichor(value / max_value)	

func _on_opal_score_added(subject: Entity, _amount: int, _source: Entity) -> void:
	if subject == PlayerManager.player:
		hud.set_opal_score(GameState.opal_score)

func _on_aura_score_added(subject: Entity, _amount: int, _source: Entity) -> void:
	if subject == PlayerManager.player:
		hud.set_aura_score(GameState.aura_score)
			
#----------------------
# day state
# -----------------------------

func _on_day_state_changed(_state: TimeManager.DayState, day_name: String) -> void:
	hud.show_time_message(day_name)
