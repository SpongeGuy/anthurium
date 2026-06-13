extends Node
class_name UIController

@export var hud: UIHUD
@export var gameview: UIGameView
@export var screen: UIScreen

var _health_component: HealthComponent
var _ichor_component: IchorComponent
var _ability_manager: AbilityManager

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
	_unbind_player()
	
	
		
	_health_component = entity.get_component(HealthComponent)
	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)

	_ichor_component = entity.get_component(IchorComponent)
	if _ichor_component:
		_ichor_component.ichor_changed.connect(_on_ichor_changed)
		
	_ability_manager = entity.get_component(AbilityManager)
	if _ability_manager:
		_ability_manager.ability_registered.connect(_on_ability_registered)
		_ability_manager.ability_unregistered.connect(_on_ability_unregistered)
		# Populate HUD immediately for any abilities already in the manager.
		_refresh_ability_icons()

	
func _unbind_player() -> void:
	if _health_component:
		_health_component.health_changed.disconnect(_on_health_changed)
		_health_component = null
	if _ichor_component:
		_ichor_component.ichor_changed.disconnect(_on_ichor_changed)
		_ichor_component = null
		
	if _ability_manager:
		_ability_manager.ability_registered.disconnect(_on_ability_registered)
		_ability_manager.ability_unregistered.disconnect(_on_ability_unregistered)
		_ability_manager = null

## Pushes the current manager state to the HUD on first bind or player swap.
func _refresh_ability_icons() -> void:
	if not _ability_manager:
		return
	for i in _ability_manager.abilities.size():
		var ability: Ability = _ability_manager.get_ability(i)
		hud.update_ability_icon(i, ability.icon if ability else ability_missing)
 
func _on_ability_registered(slot: int, ability: Ability) -> void:
	hud.update_ability_icon(slot, ability.icon)
 
func _on_ability_unregistered(slot: int) -> void:
	hud.update_ability_icon(slot, ability_missing)

	
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
