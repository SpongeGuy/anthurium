## Autoload: UiController
##
## Owns top-level UI plumbing: the HUD/screen/hand references retrieved from
## the scene tree, the CRT post-processing shader applied to the main
## viewport, named [UIStage] instances layered onto the UI canvas, and the
## bindings that push the current player's health/ichor/ability state onto
## the HUD.
extends Node

## The player HUD (health/ichor/ability bar), found via [method retrieve_references].
var hud: UIHUD
## Reserved reference to the in-world/game view UI; currently unused beyond
## its declaration.
var gameview: UIGameView
## The full-screen message/fade layer, found via [method retrieve_references].
var screen: UIScreen
## The cursor/interaction "hand" UI, found via [method retrieve_references].
var hand: UIHand

var c_selector: UICharacterSelector

## reference to the player, necessary for binding and unbinding functions to signals
var player: Entity

## The [CanvasLayer] all [UIStage]s are parented under. Set externally by
## [code]AppController._retrieve_references()[/code].
var ui_canvas_layer: CanvasLayer

## Named [PackedScene]s that can be instantiated as [UIStage]s via
## [method add_stage].
var ui_scenes: Dictionary[String, PackedScene] = {
	"title": preload("uid://d1bn1no2fwcee"),
	"floating_square_cutout": preload("uid://dd0xlhuktb0p2"),
	"arcade_title": preload("uid://dwax5kri3bg24"),
}
## Currently instantiated stages, keyed by the name they were added under.
var active_ui_scenes: Dictionary[String, UIStage] = {}

## CRT post-processing shader applied to the main viewport container.
var crt_shader: Shader = preload("uid://b7fav5cdhceky")
## Material instance wrapping [member crt_shader], applied to
## [member AppController.viewport_container].
var _crt_material: ShaderMaterial

## Selectable CRT rendering styles. See [method set_crt_shader_mode].
enum CRT_SHADER_MODES{ NEAREST, OFF, DOT, APERTURE, NULL }
## The currently active CRT shader mode.
var crt_shader_mode: CRT_SHADER_MODES

## The current player's [HealthComponent], bound in [method _bind_player].
var _health_component: HealthComponent
## The current player's [IchorComponent], bound in [method _bind_player].
var _ichor_component: IchorComponent
## The current player's [AbilityManager], bound in [method _bind_player].
var _ability_manager: AbilityManager

## Emitted once [method retrieve_references] has successfully found every
## required UI node.
signal ui_ready
## Whether [method retrieve_references] has completed successfully.
var is_ready: bool = false

## Sets up the CRT shader material on the main viewport and starts listening
## for the player being set so the HUD can bind to it.
func _ready() -> void:
	PlayerManager.player_set.connect(_on_player_set)
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = crt_shader
	var vp_tex := AppController.main_viewport.get_texture()
	_crt_material.set_shader_parameter("tex", vp_tex)
	_crt_material.set_shader_parameter("tex_nearest", vp_tex)
	AppController.viewport_container.material = _crt_material
	set_crt_shader_mode(CRT_SHADER_MODES.NEAREST)
	
	
## Switches the CRT post-process shader to [param mode], configuring its
## shader parameters (mask type, aspect, curvature, color offset) to match.
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
	
	
## Instantiates the [UIStage] registered under [param name] in
## [member ui_scenes], adds it to [member ui_canvas_layer], and tracks it in
## [member active_ui_scenes].
func add_stage(name: String) -> UIStage:
	Log.debug("Adding stage %s" % name)
	var new_stage: UIStage = ui_scenes[name].instantiate() as UIStage
	active_ui_scenes[name] = new_stage
	ui_canvas_layer.add_child(new_stage)
	return new_stage
	
## Frees and forgets the active stage registered under [param name]. No-op
## if no such stage is active.
func remove_stage(name: String) -> void:
	if not active_ui_scenes.has(name):
		return
	active_ui_scenes[name].queue_free()
	active_ui_scenes.erase(name)
	
func clear_stages() -> void:
	for i in active_ui_scenes:
		active_ui_scenes[i].queue_free()
	active_ui_scenes.clear()
	
	
	
## Locates [member hud], [member screen], and [member hand] under
## [param starting_point] by name. Emits [signal ui_ready] and sets
## [member is_ready] to [code]true[/code] only if all three are found.
func retrieve_references(starting_point: Node) -> void:
	hud = starting_point.find_child("UI_HUD", true, false)
	if not hud:
		Log.error("Could not find HUD element while retrieving!")
		return
	
	screen = starting_point.find_child("UI_SCREEN", true, false)
	if not screen:
		Log.error("Could not find screen element while retrieving!")
		return
		
	hand = starting_point.find_child("UI_HAND", true, false)
	if not hand:
		Log.error("Could not find hand element while retrieving!")
		return
	
	c_selector = starting_point.find_child("UI_C_SELECT", true, false)
	if not c_selector:
		Log.error("Could not find c_selector element while retrieving!")
		return
	
	is_ready = true
	ui_ready.emit()
	





	


# -------------------------
# player binding
# --------------------------


## Connected to [signal PlayerManager.player_set]; unbinds the previous
## player's signals (if any) and binds [param entity]'s.
func _on_player_set(entity: Entity) -> void:
	# disconnect all signals before binding a new player
	_unbind_player()
	_bind_player(entity)
	
## Connects the given entity's [HealthComponent], [IchorComponent], and
## [AbilityManager] signals to their HUD-update handlers, and immediately
## refreshes the ability icons for any abilities already present.
func _bind_player(entity: Entity) -> void:
	player = entity
	_health_component = entity.get_component(HealthComponent)
	if _health_component:
		_health_component.health_changed.connect(_on_health_changed)
		_on_health_changed(_health_component.health, _health_component.max_health)

	_ichor_component = entity.get_component(IchorComponent)
	if _ichor_component:
		_ichor_component.ichor_changed.connect(_on_ichor_changed)
		_on_ichor_changed(_ichor_component.ichor, _ichor_component.max_ichor)
		
	_ability_manager = entity.get_component(AbilityManager)
	if _ability_manager:
		_ability_manager.ability_registered.connect(_on_ability_registered)
		_ability_manager.ability_unregistered.connect(_on_ability_unregistered)
		# Populate HUD immediately for any abilities already in the manager.
		_refresh_ability_icons()
	
	player.points_changed.connect(_on_points_changed)
		
	Log.info("Bound new player %s to HUD." % entity)
	
## Disconnects the currently bound player's component signals, if any, and
## clears the cached component references.
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
	if player:
		player.points_changed.disconnect(_on_points_changed)
		
		player = null

## Pushes the current manager state to the HUD on first bind or player swap.
func _refresh_ability_icons() -> void:
	if not _ability_manager:
		return
	for i in _ability_manager.abilities.size():
		var ability: Ability = _ability_manager.get_ability(i)
		if ability:
			hud.update_ability_icon(i, ability.display_icon)
		else:
			hud.update_ability_icon(i, null)
			

func _on_points_changed() -> void:
	hud.set_score_1(player.points)

 
## Connected to [signal AbilityManager.ability_registered]; updates the HUD
## icon for [param slot].
func _on_ability_registered(slot: int, ability: Ability) -> void:
	hud.update_ability_icon(slot, ability.display_icon)
 
## Connected to [signal AbilityManager.ability_unregistered]; clears the HUD
## icon for [param slot].
func _on_ability_unregistered(slot: int) -> void:
	hud.update_ability_icon(slot, null)

## Connected to [signal HealthComponent.health_changed]; updates the HUD
## health bar as a fraction of max health.
func _on_health_changed(value: float, max_value: float) -> void:
	hud.update_health(value, max_value)

## Connected to [signal IchorComponent.ichor_changed]; updates the HUD ichor
## bar as a fraction of max ichor.
func _on_ichor_changed(value: float, max_value: float) -> void:
	hud.update_ichor(value, max_value)
