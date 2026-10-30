## Autoload: UiController
##
## Owns top-level UI plumbing: the HUD/screen/hand references retrieved from
## the scene tree, the CRT post-processing shader applied to the main
## viewport, named [UIStage] instances layered onto the UI canvas, and the
## bindings that push the current player's health/ichor/ability state onto
## the HUD.
extends Node

class PlayerBinding:
	var entity: Entity
	var health: HealthComponent
	var ichor: IchorComponent
	var abilities: AbilityManager
	var on_health: Callable
	var on_ichor: Callable
	var on_registered: Callable
	var on_unregistered: Callable
	var on_points: Callable

var _bindings: Dictionary[int, PlayerBinding] = {}
var _selector_open: Dictionary[int, bool] = {}
var _ability_ui_open: Dictionary[int, bool] = {}

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
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = crt_shader
	var vp_tex := AppController.main_viewport.get_texture()
	_crt_material.set_shader_parameter("tex", vp_tex)
	_crt_material.set_shader_parameter("tex_nearest", vp_tex)
	AppController.viewport_container.material = _crt_material
	set_crt_shader_mode(CRT_SHADER_MODES.NEAREST)
	
	PlayerManager.player_bound.connect(_bind_player)
	PlayerManager.player_unbound.connect(_unbind_player)
	PlayerManager.slot_state_changed.connect(_on_slot_state_changed)
	PlayerManager.selector_navigated.connect(_on_selector_navigated)
	PlayerManager.selection_confirm_requested.connect(_on_selection_confirm_requested)
	PlayerManager.menu_input.connect(_on_menu_input)
	PlayerManager.participants_changed.connect(_on_participants_changed)
	#GameInterface.level_loaded.connect(func(_l: int) -> void: hud.update_level_text())
	GameInterface.player_spawn_started.connect(_on_player_spawn_started)

	
	
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
	#hud = starting_point.find_child("UI_HUD", true, false)
	#if not hud:
		#Log.error("Could not find HUD element while retrieving!")
		#return
	
	screen = starting_point.find_child("UI_SCREEN", true, false)
	if not screen:
		Log.error("Could not find screen element while retrieving!")
		return
		
	#hand = starting_point.find_child("UI_HAND", true, false)
	#if not hand:
		#Log.error("Could not find hand element while retrieving!")
		#return
	
	c_selector = starting_point.find_child("UI_C_SELECT", true, false)
	if not c_selector:
		Log.error("Could not find c_selector element while retrieving!")
		return
	
	is_ready = true
	ui_ready.emit()
	





	


# -------------------------
# player binding
# --------------------------

	
## Connects the given entity's [HealthComponent], [IchorComponent], and
## [AbilityManager] signals to their HUD-update handlers, and immediately
## refreshes the ability icons for any abilities already present.
func _bind_player(slot: int, entity: Entity) -> void:
	if _bindings.has(slot):
		_unbind_player(slot, _bindings[slot].entity)
	var b: PlayerBinding = PlayerBinding.new()
	b.entity = entity
	b.on_health = _on_health_changed.bind(slot)
	b.on_ichor = _on_ichor_changed.bind(slot)
	b.on_registered = _on_ability_registered.bind(slot)
	b.on_unregistered = _on_ability_unregistered.bind(slot)
	b.on_points = _on_points_changed.bind(slot)

	b.health = entity.get_component(HealthComponent)
	if b.health:
		b.health.health_changed.connect(b.on_health)
		_on_health_changed(b.health.health, b.health.max_health, slot)
	b.ichor = entity.get_component(IchorComponent)
	if b.ichor:
		b.ichor.ichor_changed.connect(b.on_ichor)
		_on_ichor_changed(b.ichor.ichor, b.ichor.max_ichor, slot)
	b.abilities = entity.get_component(AbilityManager)
	if b.abilities:
		b.abilities.ability_registered.connect(b.on_registered)
		b.abilities.ability_unregistered.connect(b.on_unregistered)
		for i in b.abilities.abilities.size():
			var ability: Ability = b.abilities.get_ability(i)
			#hud.update_ability_icon(slot, i, ability.display_icon if ability else null) # TODO
	entity.points_changed.connect(b.on_points)
	_on_points_changed(slot)

	_bindings[slot] = b
	#hud.show_player_panel(slot) # TODO
	#hud.set_state(UIHUD.State.BAR)

	
## Disconnects the currently bound player's component signals, if any, and
## clears the cached component references.
func _unbind_player(slot: int, _entity: Entity) -> void:
	var b: PlayerBinding = _bindings.get(slot)
	if b == null:
		return
	_bindings.erase(slot)
	# components/entity may already be freed (death), so check before disconnecting
	if is_instance_valid(b.health) and b.health.health_changed.is_connected(b.on_health):
		b.health.health_changed.disconnect(b.on_health)
	if is_instance_valid(b.ichor) and b.ichor.ichor_changed.is_connected(b.on_ichor):
		b.ichor.ichor_changed.disconnect(b.on_ichor)
	if is_instance_valid(b.abilities):
		if b.abilities.ability_registered.is_connected(b.on_registered):
			b.abilities.ability_registered.disconnect(b.on_registered)
		if b.abilities.ability_unregistered.is_connected(b.on_unregistered):
			b.abilities.ability_unregistered.disconnect(b.on_unregistered)
	if is_instance_valid(b.entity) and b.entity.points_changed.is_connected(b.on_points):
		b.entity.points_changed.disconnect(b.on_points)
	# on death the panel should stay up showing the final score; hide_player_panel(slot) is for leaving entirely

func _on_health_changed(value: float, max_value: float, slot: int) -> void:
	pass
	#hud.update_health(slot, value, max_value)
func _on_ichor_changed(value: float, max_value: float, slot: int) -> void:
	pass
	#hud.update_ichor(slot, value, max_value)
func _on_ability_registered(index: int, ability: Ability, slot: int) -> void:
	pass
	#hud.update_ability_icon(slot, index, ability.display_icon)
	pass
func _on_ability_unregistered(index: int, slot: int) -> void:
	pass
	#hud.update_ability_icon(slot, index, null)
func _on_points_changed(slot: int) -> void:
	var b: PlayerBinding = _bindings.get(slot)
	#if b and is_instance_valid(b.entity):
		#hud.set_score(slot, b.entity.points)


## Pushes the current manager state to the HUD on first bind or player swap.
func _refresh_ability_icons() -> void:
	if not _ability_manager:
		return
	for i in _ability_manager.abilities.size():
		var ability: Ability = _ability_manager.get_ability(i)
		#if ability:
			#hud.update_ability_icon(i, ability.display_icon)
		#else:
			#hud.update_ability_icon(i, null)
			






func _on_slot_state_changed(slot: int, state: PlayerManager.SlotState) -> void:
	if not is_ready:
		return
	var want_selector: bool = state == PlayerManager.SlotState.SELECTING
	if want_selector != _selector_open.get(slot, false):
		_selector_open[slot] = want_selector
		if want_selector:
			c_selector.show_selector(slot)
		else:
			c_selector.hide_selector(slot)
	var want_abilities: bool = state == PlayerManager.SlotState.MANAGING
	if want_abilities != _ability_ui_open.get(slot, false):
		_ability_ui_open[slot] = want_abilities
		#if want_abilities: # TODO
			#hud.open_ability_ui(slot)  # slides in at the side of the screen, doesn't pause
		#else:
			#hud.close_ability_ui(slot)


func _on_selector_navigated(slot: int, direction: int) -> void:
	c_selector.cycle(slot, direction)

func _on_selection_confirm_requested(slot: int) -> void:
	PlayerManager.confirm_selection(slot, c_selector.get_selected_id(slot))

func _on_menu_input(slot: int, action: StringName) -> void:
	pass # TODO: route to the ability UI for `slot` (needs UIHUD/UIHand)

func _on_participants_changed(count: int) -> void:
	pass
	#hud.set_player_count(count) # HUD layout scales with how many players took part

func _on_player_spawn_started(_slot: int) -> void:
	pass
	#if PlayerManager.slots.is_empty():
		#hud.set_state(UIHUD.State.INACTIVE) # hide the bar during the very first fly-in

func show_game_over(results: Array[Dictionary], participant_count: int) -> void:
	Log.info("Game over: %s" % [results]) # TODO: per-device score panels (WIP)
