## Autoload: UiController
##
## Owns top-level UI plumbing: the HUD/screen/hand references retrieved from
## the scene tree, the CRT post-processing shader applied to the main
## viewport, named [UIStage] instances layered onto the UI canvas, and the
## bindings that push the current player's health/ichor/ability state onto
## the HUD.
extends Node



var _selector_open: Dictionary[int, bool] = {}
var _ability_ui_open: Dictionary[int, bool] = {}

var _panels: Dictionary[int, AbilityPanel] = {}


var screen: UIScreen
var c_selector: UICharacterSelector
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

var crt_shader: Shader = preload("uid://b7fav5cdhceky")
var _crt_material: ShaderMaterial

enum CRT_SHADER_MODES{ NEAREST, OFF, DOT, APERTURE, NULL }
var crt_shader_mode: CRT_SHADER_MODES

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
	
	PlayerManager.slot_state_changed.connect(_on_slot_state_changed)
	PlayerManager.selector_navigated.connect(_on_selector_navigated)
	PlayerManager.selection_confirm_requested.connect(_on_selection_confirm_requested)
	PlayerManager.player_bound.connect(_bind_player)
	PlayerManager.player_unbound.connect(_unbind_player)
	PlayerManager.menu_input.connect(_on_menu_input)

	
	
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
	



func _get_panel(slot: int) -> AbilityPanel:
	if not _panels.has(slot):
		var panel: AbilityPanel = AbilityPanel.new()
		panel.setup(slot)
		ui_canvas_layer.add_child(panel)
		_panels[slot] = panel
	return _panels[slot]

func _bind_player(slot: int, entity: Entity) -> void:
	print("binding player")
	PlayerOverlay.attach(entity, slot)
	_get_panel(slot).bind_entity(entity)

func _unbind_player(slot: int, _entity: Entity) -> void:
	if _panels.has(slot):
		_panels[slot].unbind()
	
func _on_menu_input(slot: int, action: StringName) -> void:
	_get_panel(slot).handle_input(action)



	


# -------------------------
# player binding
# --------------------------

	


	




			






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
	var want_panel: bool = state == PlayerManager.SlotState.MANAGING
	if want_panel != _ability_ui_open.get(slot, false):
		_ability_ui_open[slot] = want_panel
		if want_panel:
			_get_panel(slot).open()
		elif _panels.has(slot):
			_panels[slot].close()


func _on_selector_navigated(slot: int, direction: int) -> void:
	c_selector.cycle(slot, direction)

func _on_selection_confirm_requested(slot: int) -> void:
	PlayerManager.confirm_selection(slot, c_selector.get_selected_id(slot))




func show_game_over(results: Array[Dictionary], participant_count: int) -> void:
	Log.info("Game over: %s" % [results]) # TODO: per-device score panels (WIP)
