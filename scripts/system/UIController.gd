extends Node
class_name UIController

@export var hud: UIHUD
@export var gameview: UIGameView
@export var screen: UIScreen

var player: Entity

func _ready() -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)
	EventBus.day_state_changed.connect(_on_day_state_changed)
	EventBus.player_spawned.connect(_on_player_spawned)
	
func _process(delta: float) -> void:
	if GameState.state != GameState.Status.PLAYING:
		return
		
	_update_hud(delta)
	
func _on_game_state_changed(status: GameState.Status) -> void:
	match status:
		GameState.Status.LOADING:
			_show_loading_screen()
		GameState.Status.PLAYING:
			_set_all_invisible()
			_show_game()
			_show_hud()

func _update_hud(delta: float) -> void:
	_update_module_time()
	_update_module_healthbar()
	_update_module_saturationbar()
	_update_module_ability_icons()
	hud.change_game_score(GameState.game_score, delta)
	hud.change_nutri_score(GameState.nutri_score, delta)
	
func _update_module_ability_icons() -> void:
	if not player:
		return	
	var ability_manager: AbilityManager = player.get_component(AbilityManager)
	for i in ability_manager.abilities.size():
		hud.ability_icons[i].texture = ability_manager.abilities[i].icon
		
	

func _update_module_saturationbar() -> void:
	if not player:
		hud.player_saturation_bar.value = 0
		return
	var saturation_component: SaturationComponent = player.get_component(SaturationComponent)
	if not saturation_component:
		return
	var value: float = saturation_component.saturation / saturation_component.max_saturation
	hud.player_saturation_bar.value = value * 100

func _update_module_healthbar() -> void:
	if not player:
		hud.player_health_bar.value = 0
		return
	var health_component: HealthComponent = player.get_component(HealthComponent)
	if not health_component:
		return
	var value: float = health_component.health / health_component.max_health
	hud.player_health_bar.value = value * 100

func _update_module_time() -> void:
	var day_length: float = TimeManager.DAYTIMES[TimeManager.DAYTIMES.size() - 1]
	if day_length - TimeManager.elapsed >= 0:
		hud.time_label.text = str( "%02d:%02d" % [int((day_length - TimeManager.elapsed) / 60), int(day_length - TimeManager.elapsed) % 60])

func _on_day_state_changed(state: TimeManager.DayState, name: String) -> void:
	hud.time_message_label.text = str(name)


# --------------------------------------------------------
# helpers / one-time methods
# ---------------------------------------------------------

func _on_player_spawned(e: Entity) -> void:
	player = e

func _set_all_invisible() -> void:
	hud.visible = false
	gameview.visible = false
	screen.visible = false
	
func _show_black() -> void:
	_set_all_invisible()
	screen.visible = true
	screen.bg_color.color = Color(0, 0, 0, 1)

func _show_loading_screen() -> void:
	_show_black()
	screen.central_message.text = "Loading..."

func _show_game() -> void:
	gameview.visible = true
	
func _show_hud() -> void:
	hud.visible = true
