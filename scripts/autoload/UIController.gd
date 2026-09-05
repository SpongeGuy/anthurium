extends Node

var hud: UIHUD
var gameview: UIGameView
var screen: UIScreen
var hand: UIHand

var ui_canvas_layer: CanvasLayer

var ui_scenes: Dictionary[String, PackedScene] = {
	"title": load("uid://d1bn1no2fwcee"),
	"floating_square_cutout": load("uid://dd0xlhuktb0p2")
}
var active_ui_scenes: Dictionary[String, UIStage] = {}

var crt_shader: Shader = preload("uid://b7fav5cdhceky")
var _crt_material: ShaderMaterial

enum CRT_SHADER_MODES{ NEAREST, OFF, DOT, APERTURE, NULL }
var crt_shader_mode: CRT_SHADER_MODES

var _health_component: HealthComponent
var _ichor_component: IchorComponent
var _ability_manager: AbilityManager

signal ui_ready
var is_ready: bool = false

func _ready() -> void:
	PlayerManager.player_set.connect(_on_player_set)
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = crt_shader
	var vp_tex := AppController.main_viewport.get_texture()
	_crt_material.set_shader_parameter("tex", vp_tex)
	_crt_material.set_shader_parameter("tex_nearest", vp_tex)
	AppController.viewport_container.material = _crt_material
	set_crt_shader_mode(CRT_SHADER_MODES.DOT)
	
	
func set_crt_shader_mode(mode: CRT_SHADER_MODES) -> void:
	crt_shader_mode = mode
	match mode:
		CRT_SHADER_MODES.NEAREST:
			_crt_material.set_shader_parameter("enabled", false)
			_crt_material.set_shader_parameter("use_nearest_filter", true)
		CRT_SHADER_MODES.OFF:
			_crt_material.set_shader_parameter("enabled", false)
			_crt_material.set_shader_parameter("use_nearest_filter", false)
		CRT_SHADER_MODES.DOT:
			_crt_material.set_shader_parameter("enabled", true)
			_crt_material.set_shader_parameter("use_nearest_filter", false)
			
			_crt_material.set_shader_parameter("mask_type", 1)
			_crt_material.set_shader_parameter("aspect", 0.562)
			_crt_material.set_shader_parameter("curve", 0.12)
			_crt_material.set_shader_parameter("color_offset", -0.15)
		CRT_SHADER_MODES.APERTURE:
			_crt_material.set_shader_parameter("enabled", true)
			_crt_material.set_shader_parameter("use_nearest_filter", false)
			_crt_material.set_shader_parameter("mask_type", 5)
			_crt_material.set_shader_parameter("aspect", 0.562)
			_crt_material.set_shader_parameter("curve", 0.12)
			_crt_material.set_shader_parameter("color_offset", -0.15)
		CRT_SHADER_MODES.NULL:
			_crt_material.set_shader_parameter("enabled", true)
			_crt_material.set_shader_parameter("use_nearest_filter", false)
			
			_crt_material.set_shader_parameter("mask_type", 0)
			_crt_material.set_shader_parameter("aspect", 0.562)
			_crt_material.set_shader_parameter("curve", 0.12)
			_crt_material.set_shader_parameter("color_offset", -0.15)
	
	
func add_stage(name: String) -> UIStage:
	var new_stage: UIStage = ui_scenes[name].instantiate() as UIStage
	active_ui_scenes[name] = new_stage
	ui_canvas_layer.add_child(new_stage)
	return new_stage
	
func remove_stage(name: String) -> void:
	if not active_ui_scenes.has(name):
		return
	active_ui_scenes[name].queue_free()
	active_ui_scenes.erase(name)
	
	
	
func retrieve_references(starting_point: Node) -> void:
	hud = starting_point.find_child("UI_HUD", true, false)
	if not hud:
		Log.error("Could not find HUD element while retrieving!")
		return
	
	screen = starting_point.find_child("UI_Screen", true, false)
	if not screen:
		Log.error("Could not find screen element while retrieving!")
		return
		
	hand = starting_point.find_child("UI_Hand", true, false)
	if not hand:
		Log.error("Could not find hand element while retrieving!")
		return
	
	is_ready = true
	ui_ready.emit()
	



	





# -------------------------
# player binding
# --------------------------


func _on_player_set(entity: Entity) -> void:
	# disconnect all signals before binding a new player
	_unbind_player()
	_bind_player(entity)
	

func _bind_player(entity: Entity) -> void:
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
		
	Log.info("Bound new player %s to HUD." % entity)
	
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
		if ability:
			hud.update_ability_icon(i, ability.icon)
		else:
			hud.update_ability_icon(i, null)

 
func _on_ability_registered(slot: int, ability: Ability) -> void:
	hud.update_ability_icon(slot, ability.icon)
 
func _on_ability_unregistered(slot: int) -> void:
	hud.update_ability_icon(slot, null)

func _on_health_changed(value: float, max_value: float) -> void:
	hud.update_health(value / max_value)

func _on_ichor_changed(value: float, max_value: float) -> void:
	hud.update_ichor(value / max_value)	


			
