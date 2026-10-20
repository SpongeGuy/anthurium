extends CanvasLayer
## Unified debug overlay: height/hitbox visualisation + entity inspector.
## Replaces DebugHeightOverlay.gd and DebugUIHelper.gd (no Labels/VBoxContainers;
## everything is drawn directly onto a window-resolution CanvasLayer).
##
## Setup: Project Settings > Globals > Autoload, add this script as "DebugOverlay".
## It tracks Entities/Hitboxes/Hurtboxes automatically via SceneTree.node_added
## and frees itself in non-debug builds.
##
## Controls:
##   F8    - cycle height visualisation: OFF > ENTITIES > BOXES > ALL
##   F9    - toggle drawing of disabled (inactive) shapes
##   F7    - toggle the entity inspector (hover + click-to-pin panels)
##   Hover - shows the entity's debug panel next to the mouse
##   Click - pins that entity's panel (anchored to the entity); click it again to
##           unpin. Pinned panels disappear automatically when the entity is freed.
## Everything keeps working while the game is paused.
##
## Resolution: the world renders into AppController.main_viewport (usually
## 640x360) which is scaled up to the window. World points are mapped to screen
## pixels via main_viewport's canvas transform times [member resolution_scale]
## (window px per viewport px). Line widths and font size are in screen pixels.
##
## Naming in this project: Hitbox = receives damage (cyan), Hurtbox = deals
## damage (orange).
##
## Height visualisation:
##  ENTITIES: ground marker, dashed line up to the entity's current z, a thick
##            bar covering [z, z + height], and a ruler (1 tick = 1 z unit,
##            long tick every 5).
##  BOXES:    for every shape: the outline physics actually tests (thick),
##            the ground footprint (faint), and the bottom/top outlines of its
##            vertical volume [entity.z + z_offset, + height] joined by edges.
##            For every Hitbox/Hurtbox pair overlapping in XY a line is drawn:
##            green = HIT, red = Z MISS (with the vertical gap), grey = ignored
##            (friends / own hurtbox). The verdict uses SpatialUtil.z_ranges_overlap,
##            the same call Hitbox uses.

enum Mode { OFF, ENTITIES, BOXES, ALL }

## Must match the factor in Entity._apply_z_offset (offset = -z * 4.0).
const PX_PER_Z: float = 4.0

const COL_ENTITY_GROUND := Color(0.4, 1.0, 0.4)
const COL_ENTITY_AIR := Color(1.0, 0.9, 0.3)
const COL_HITBOX := Color(0.25, 0.85, 1.0)
const COL_HURTBOX := Color(1.0, 0.5, 0.15)
const COL_OK := Color(0.3, 1.0, 0.3)
const COL_BAD := Color(1.0, 0.25, 0.25)
const COL_IGNORED := Color(0.7, 0.7, 0.7)
const COL_HOVER := Color(0.85, 0.95, 1.0)
const COL_PINNED := Color(1.0, 0.85, 0.3)
const COL_PANEL_BG := Color(0.05, 0.05, 0.08, 0.82)
const COL_PANEL_TEXT := Color(0.92, 0.92, 0.92)

# --- tweakables (edit here; autoload scripts have no inspector) ---------------
var cycle_key: Key = KEY_F8
var inactive_key: Key = KEY_F9
var info_key: Key = KEY_F7
var overlay_layer: int = 128
## Screen pixels.
var label_font_size: int = 14
## Base line width in screen pixels.
var line_width: float = 1.5
var circle_segments: int = 24
## If > 0, forces the window-px-per-viewport-px ratio instead of auto-detecting
## it from AppController.main_viewport.
var scale_override: float = 0.0
# ------------------------------------------------------------------------------

var mode: Mode = Mode.OFF
var show_inactive: bool = false
var info_enabled: bool = true

## Window pixels per main-viewport pixel (e.g. 3.0 for 640x360 on a 1920x1080 window).
var resolution_scale: float = 1.0

var _origin := Vector2.ZERO                  # where the viewport's top-left lands on screen
var _world_to_vp := Transform2D.IDENTITY     # world -> main viewport pixels (camera)
var _world_px: float = 1.0                   # screen px per world unit (scale * camera zoom)

var _entities: Array[Entity] = []
var _hitboxes: Array[Hitbox] = []
var _hurtboxes: Array[Hurtbox] = []
var _font: Font
var _c: Node2D                                # draw surface

var _hover: Entity = null
var _hover_world: Vector2 = Vector2.ZERO
var _pinned: Array = []                       # of Entity; untyped so freed ones can't trip typed access


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = overlay_layer
	_font = ThemeDB.fallback_font
	_c = Node2D.new()
	_c.name = "Canvas"
	add_child(_c)
	_c.draw.connect(_draw_overlay)
	var tree := get_tree()
	tree.node_added.connect(_on_node_added)
	_scan(tree.root)


func _scan(node: Node) -> void:
	for child in node.get_children():
		_on_node_added(child)
		_scan(child)


func _on_node_added(node: Node) -> void:
	if node is Entity:
		_track(node, _entities)
	elif node is Hitbox:
		_track(node, _hitboxes)
	elif node is Hurtbox:
		_track(node, _hurtboxes)


func _track(node: Node, list: Array) -> void:
	if node is Entity:
		if node.show_in_debug == false:
			return
	if list.has(node):
		return
	list.append(node)
	node.tree_exiting.connect(func() -> void: list.erase(node), CONNECT_ONE_SHOT)


# ------------------------------------------------------------------------------
# Input / per-frame update
# ------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null:
		if not key.pressed or key.echo:
			return
		if key.keycode == cycle_key:
			mode = ((mode + 1) % Mode.size()) as Mode
		elif key.keycode == inactive_key:
			show_inactive = not show_inactive
		elif key.keycode == info_key:
			info_enabled = not info_enabled
		_c.queue_redraw()
		return

	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()


func _handle_click() -> void:
	if not info_enabled or not CameraController.camera:
		return
	var e := _get_entity_at(CameraController.get_world_mouse_position())
	if e != null:
		_toggle_pin(e)


func _toggle_pin(e: Entity) -> void:
	if _pinned.has(e):
		_pinned.erase(e)
		return
	_pinned.append(e)
	e.tree_exiting.connect(func() -> void: _pinned.erase(e), CONNECT_ONE_SHOT)


func _get_entity_at(world_pos: Vector2) -> Entity:
	if not AppController.world_2d:
		return null
	var space := AppController.world_2d.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_bodies = true
	for result in space.intersect_point(query):
		var collider: Object = result.collider
		if collider is Entity:
			return collider as Entity
	return null


func _process(_delta: float) -> void:
	_hover = null
	if info_enabled and CameraController.camera:
		_hover_world = CameraController.get_world_mouse_position()
		var e := _get_entity_at(_hover_world)
		# don't double-draw hover on top of a pinned entity's panel
		if e != null and not _pinned.has(e):
			_hover = e
	if mode != Mode.OFF or info_enabled:
		_c.queue_redraw()


# ------------------------------------------------------------------------------
# Resolution mapping
# ------------------------------------------------------------------------------

func _main_viewport() -> Viewport:
	var v: Variant = AppController.main_viewport
	if v is Viewport and is_instance_valid(v):
		return v as Viewport
	return get_viewport()


## Works out how the main viewport is placed on the window: uniform scale,
## centred (letterboxed). If your setup differs, set [member scale_override]
## or adjust this function.
func _update_mapping() -> void:
	var vp := _main_viewport()
	var vp_size := Vector2(vp.get_visible_rect().size)
	var screen_size := Vector2(get_viewport().get_visible_rect().size)
	if scale_override > 0.0:
		resolution_scale = scale_override
	elif vp_size.x > 0.0 and vp_size.y > 0.0:
		resolution_scale = minf(screen_size.x / vp_size.x, screen_size.y / vp_size.y)
	else:
		resolution_scale = 1.0
	_origin = (screen_size - vp_size * resolution_scale) * 0.5
	_world_to_vp = vp.global_canvas_transform * vp.canvas_transform
	_world_px = resolution_scale * _world_to_vp.get_scale().x


func _to_screen(p: Vector2) -> Vector2:
	return _origin + (_world_to_vp * p) * resolution_scale


func _to_screen_pts(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = _to_screen(pts[i])
	return out


# ------------------------------------------------------------------------------
# Drawing primitives (inputs are world positions; widths/sizes in screen px)
# ------------------------------------------------------------------------------

func _line(a: Vector2, b: Vector2, color: Color, width_mult: float = 1.0) -> void:
	_c.draw_line(_to_screen(a), _to_screen(b), color, line_width * width_mult)


func _dashed(a: Vector2, b: Vector2, color: Color) -> void:
	_c.draw_dashed_line(_to_screen(a), _to_screen(b), color, line_width, 4.0)


func _loop(pts: PackedVector2Array, color: Color, width_mult: float = 1.0) -> void:
	if pts.size() < 2:
		return
	var s := _to_screen_pts(pts)
	s.append(s[0])
	_c.draw_polyline(s, color, line_width * width_mult)


func _label(world_pos: Vector2, text: String, color: Color, offset: Vector2 = Vector2(8.0, -4.0)) -> void:
	_label_at(_to_screen(world_pos) + offset, text, color)


func _label_at(screen_pos: Vector2, text: String, color: Color) -> void:
	_c.draw_string(_font, screen_pos + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, Color(0, 0, 0, 0.85))
	_c.draw_string(_font, screen_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, color)


## Draws a boxed block of text with its top-left near [param anchor] (screen px),
## clamped so it stays inside the window. First line is drawn in [param accent].
func _draw_panel(anchor: Vector2, lines: PackedStringArray, accent: Color) -> void:
	if lines.is_empty():
		return
	var fs := label_font_size
	var line_h := _font.get_height(fs) + 2.0
	var pad := 6.0
	var width := 0.0
	for l in lines:
		width = maxf(width, _font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var box := Vector2(width + pad * 2.0, line_h * lines.size() + pad * 2.0)
	var screen := Vector2(get_viewport().get_visible_rect().size)
	var pos := anchor + Vector2(10.0, 4.0)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, screen.x - box.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, screen.y - box.y))

	_c.draw_rect(Rect2(pos, box), COL_PANEL_BG)
	_c.draw_rect(Rect2(pos, box), accent, false, line_width)
	var y := pos.y + pad + _font.get_ascent(fs)
	for i in lines.size():
		_c.draw_string(_font, Vector2(pos.x + pad, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, accent if i == 0 else COL_PANEL_TEXT)
		y += line_h


# ------------------------------------------------------------------------------
# Overlay
# ------------------------------------------------------------------------------

func _draw_overlay() -> void:
	if mode == Mode.OFF and not info_enabled:
		return
	_update_mapping()
	if mode == Mode.ENTITIES or mode == Mode.ALL:
		for e in _entities:
			_draw_entity(e)
	if mode == Mode.BOXES or mode == Mode.ALL:
		for hb in _hitboxes:
			var cs := _resolve_shape(hb, hb.collision_shape)
			_draw_volume(hb, cs, hb.z_offset, hb.height, COL_HITBOX, "HITBOX", hb.ignore_height)
		for hu in _hurtboxes:
			var cs := _resolve_shape(hu, hu.collision_shape)
			_draw_volume(hu, cs, hu.z_offset, hu.height, COL_HURTBOX, "HURTBOX", false)
		for hb in _hitboxes:
			_draw_interactions(hb)
	if info_enabled:
		_draw_info()
	_draw_legend()


func _draw_info() -> void:
	for item in _pinned:
		if not is_instance_valid(item):
			continue
		var e := item as Entity
		var anchor := _to_screen(e.global_position)
		_c.draw_arc(anchor, 5.0, 0.0, TAU, 16, COL_PINNED, line_width)
		_draw_panel(anchor, _build_info(e, e.global_position, true), COL_PINNED)

	if is_instance_valid(_hover):
		var mouse := get_viewport().get_mouse_position()
		_c.draw_arc(_to_screen(_hover.global_position), 5.0, 0.0, TAU, 16, COL_HOVER, line_width)
		_draw_panel(mouse, _build_info(_hover, _hover_world, false), COL_HOVER)


func _draw_entity(e: Entity) -> void:
	var ground := e.global_position
	var col := COL_ENTITY_GROUND if e.is_on_ground() else COL_ENTITY_AIR
	var base := ground + Vector2(0.0, -e.z * PX_PER_Z)
	var top := base + Vector2(0.0, -e.height * PX_PER_Z)

	_c.draw_arc(_to_screen(ground), 3.0 * _world_px, 0.0, TAU, 16, col, line_width)
	if absf(e.z) > 0.01:
		_dashed(ground, base, col)
	_line(base, top, col, 2.5)

	# ruler: 1 tick per z unit, long tick + number every 5
	var lo := floori(minf(e.z, 0.0))
	var hi := ceili(maxf(e.z + e.height, 4.0)) + 1
	for i in range(lo, hi + 1):
		var y := ground.y - i * PX_PER_Z
		var tick := 6.0 if i % 5 == 0 else 3.0
		_line(Vector2(ground.x + 4.0, y), Vector2(ground.x + 4.0 + tick, y), Color(col, 0.55))
		if i % 5 == 0 and i != 0:
			_label(Vector2(ground.x + 4.0 + tick, y), str(i), Color(col, 0.75), Vector2(4.0, 5.0))

	var state := "ground" if e.is_on_ground() else "air"
	if e.is_subterranean:
		state = "subterranean"
	_label(top, "%s  z %.2f..%.2f  [%s]" % [
		_name_of(e), e.z, e.z + e.height, state
	], col, Vector2(10.0, -2.0))


func _draw_volume(area: Area2D, cs: CollisionShape2D, z_offset: float, height: float,
		color: Color, kind: String, ignores_height: bool) -> void:
	if cs == null or cs.shape == null:
		return
	var active := not cs.disabled
	if not active and not show_inactive:
		return
	var e := Entity.find_entity(area)
	if e == null:
		return
	var pts := _shape_outline(cs)
	if pts.is_empty():
		return

	var col := color if active else Color(color, 0.3)

	# The outline physics actually tests in XY.
	_loop(pts, col, 1.6)

	if ignores_height:
		_label(_centroid(pts), "%s (ignores height)" % kind, col)
		return

	# If this node is registered to the entity's z-drive, its position already
	# has the screen-space z offset baked in; undo that to find the ground footprint.
	var baked := _baked_offset(area, e)
	var base_z := e.z + z_offset
	var ground_pts := _shifted(pts, -baked)
	var bottom := _shifted(pts, Vector2(0.0, -base_z * PX_PER_Z) - baked)
	var top := _shifted(pts, Vector2(0.0, -(base_z + height) * PX_PER_Z) - baked)

	_loop(ground_pts, Color(col, 0.25))
	_loop(bottom, Color(col, 0.7))
	_loop(top, col)

	var step := maxi(1, int(pts.size() * 0.25))
	for i in range(0, pts.size(), step):
		_line(bottom[i], top[i], Color(col, 0.6))

	_label(_centroid(top), "%s %s  z %.1f..%.1f%s" % [
		kind, _name_of(e), base_z, base_z + height,
		"" if active else "  (disabled)"
	], col)


func _draw_interactions(hb: Hitbox) -> void:
	if not hb.monitoring:
		return
	for area in hb.get_overlapping_areas():
		var hu := area as Hurtbox
		if hu:
			_draw_interaction(hb, hu)


func _draw_interaction(hb: Hitbox, hu: Hurtbox) -> void:
	var he := Entity.find_entity(hb)
	var ue := Entity.find_entity(hu)
	var hb_cs := _resolve_shape(hb, hb.collision_shape)
	var hu_cs := _resolve_shape(hu, hu.collision_shape)
	if he == null or ue == null or hb_cs == null or hu_cs == null:
		return

	var hb_base := he.z + hb.z_offset
	var hu_base := ue.z + hu.z_offset
	var gap := maxf(hu_base - (hb_base + hb.height), hb_base - (hu_base + hu.height))

	# Same order of checks as Hitbox._on_hurtbox_contact
	var verdict: String
	var col: Color
	if ue == he and not hu.can_hurt_self:
		verdict = "IGNORED: own hurtbox"
		col = COL_IGNORED
	elif ue.is_friends_with(he):
		verdict = "IGNORED: friends"
		col = COL_IGNORED
	elif not (hb.ignore_height or SpatialUtil.z_ranges_overlap(hb_base, hb.height, hu_base, hu.height)):
		verdict = "Z MISS  gap %.2f" % gap
		col = COL_BAD
	else:
		verdict = "HIT"
		col = COL_OK

	var a := _volume_center(hb, hb_cs, he, hb.z_offset, hb.height)
	var b := _volume_center(hu, hu_cs, ue, hu.z_offset, hu.height)
	_line(a, b, col, 1.8)
	_c.draw_circle(_to_screen(a), 3.0, col)
	_c.draw_circle(_to_screen(b), 3.0, col)
	_label((a + b) * 0.5, "%s  (hitbox %.1f..%.1f | hurtbox %.1f..%.1f)" % [
		verdict, hb_base, hb_base + hb.height, hu_base, hu_base + hu.height
	], col)


func _draw_legend() -> void:
	var vp_size := _main_viewport().get_visible_rect().size
	_label_at(Vector2(10.0, 8.0 + label_font_size),
		"debug  height [%s]: %s   inactive [%s]: %s   inspector [%s]: %s   pinned: %d   viewport %dx%d x%.2f" % [
			OS.get_keycode_string(cycle_key), Mode.keys()[mode],
			OS.get_keycode_string(inactive_key), "on" if show_inactive else "off",
			OS.get_keycode_string(info_key), "on" if info_enabled else "off",
			_pinned.size(), int(vp_size.x), int(vp_size.y), resolution_scale
		], Color.WHITE)


# ------------------------------------------------------------------------------
# Inspector text
# ------------------------------------------------------------------------------

func _build_info(entity: Entity, world_pos: Vector2, pinned: bool) -> PackedStringArray:
	var out := PackedStringArray()
	out.append("%s%s" % [String(entity.get_basename()), "  (pinned)" if pinned else ""])

	if entity.has_component(HealthComponent):
		out.append("hp: %s" % str(entity.get_component(HealthComponent).health))
	if entity.has_component(PhysicsComponent):
		out.append("physv: %s" % str(entity.get_component(PhysicsComponent).physics_velocity))
	out.append("v: %s" % str(entity.velocity))
	out.append("z: %.2f  h: %.1f" % [entity.z, entity.height])
	if entity.has_component(IchorComponent):
		var ich: IchorComponent = entity.get_component(IchorComponent)
		out.append("ich: %d/%d" % [ich.ichor, ich.max_ichor])

	if entity.has_component(Brain):
		out.append("")
		out.append_array(_brain_lines(entity))

	if entity.has_component(HeartbeatEmitter) or entity.has_component(ArteryComponent) or entity.has_component(HeartbeatReceptor):
		out.append("")
		out.append(str(WorldGrid.world_to_tile(world_pos)))
		out.append_array(_esoterica_lines(entity))
	return out


func _esoterica_lines(entity: Entity) -> PackedStringArray:
	var out := PackedStringArray()
	out.append_array(str(AnthuriumInterface.esoterica.get_string()).split("\n"))
	var bloom: BloomPotentialComponent = entity.get_component(BloomPotentialComponent)
	if bloom:
		out.append("bloom: %f" % bloom.value)
	return out


func _brain_lines(entity: Entity) -> PackedStringArray:
	var out := PackedStringArray()
	var brain: Brain = entity.get_component(Brain)
	if not brain:
		return out

	out.append("PERSONALITY:")
	out.append_array(_personality_lines(brain))

	out.append("")
	out.append("BRAIN STATE:")
	var path: Array[String] = []
	_append_state_path(brain.top_machine, path, 0)
	out.append_array(PackedStringArray(path))

	out.append("")
	out.append("LOBES:")
	out.append_array(_lobe_lines(brain, entity))
	return out


func _personality_lines(brain: Brain) -> PackedStringArray:
	var out := PackedStringArray()
	var keys := Brain.PERSONALITY.keys()
	var row: Array[String] = []
	for i in keys.size():
		row.append("%s:%.2f" % [keys[i], brain.personality[i]])
		if row.size() == 3 or i == keys.size() - 1:
			out.append("  " + ", ".join(row))
			row.clear()
	return out


func _lobe_lines(brain: Brain, entity: Entity) -> PackedStringArray:
	var active_name: StringName = brain.top_machine.current_name
	var rows: Array[Dictionary] = []
	var active_effective: float = -INF
	for lobe in brain.lobes:
		var raw: float = lobe.get_priority(entity)
		var bored: float = brain.boredom_values.get(lobe, 0.0)
		var is_active: bool = lobe.state_name == active_name
		# Brain only subtracts boredom from the active lobe when deciding whether to switch.
		var effective: float = raw - bored if is_active else raw
		if is_active:
			active_effective = effective
		rows.append({"name": lobe.state_name, "raw": raw, "bored": bored, "effective": effective, "active": is_active})

	rows.sort_custom(func(a, b): return a["effective"] > b["effective"])

	var out := PackedStringArray()
	var best_challenger: float = -INF
	for row in rows:
		if row["active"]:
			out.append("  %s: %.3f - %.3f bored = %.3f  <-- active" % [row["name"], row["raw"], row["bored"], row["effective"]])
		else:
			best_challenger = maxf(best_challenger, row["effective"])
			var tail: String = "  (bored %.3f)" % row["bored"] if row["bored"] > 0.0005 else ""
			out.append("  %s: %.3f%s" % [row["name"], row["raw"], tail])

	if active_effective > -INF and best_challenger > -INF:
		out.append("  lead over active: %+.3f (switch at %.3f)" % [best_challenger - active_effective, brain.switch_priority_margin])
	return out


func _append_state_path(machine: BrainStateMachine, lines: Array[String], depth: int) -> void:
	if machine.current_name == &"" or not machine.current_state:
		lines.append("%s(idle)" % "  ".repeat(depth))
		return

	lines.append("%s%s" % ["  ".repeat(depth), machine.current_name])

	if machine.current_state is ContainerState:
		var container: ContainerState = machine.current_state
		_append_state_path(container.inner_machine, lines, depth + 1)


# ------------------------------------------------------------------------------
# Geometry helpers
# ------------------------------------------------------------------------------

func _name_of(e: Entity) -> String:
	return e.display_name if e.display_name != "" else String(e.name)


func _resolve_shape(area: Area2D, preferred: CollisionShape2D) -> CollisionShape2D:
	if is_instance_valid(preferred):
		return preferred
	for c in area.get_children():
		if c is CollisionShape2D:
			return c
	return null


## Offset already applied to [param node]'s position by the entity's z-drive
## (non-zero only if the node or an ancestor was passed to Entity.register_z_node).
func _baked_offset(node: Node, e: Entity) -> Vector2:
	var n: Node = node
	while n != null and n != e:
		if e._z_tracked_nodes.has(n):
			return Vector2(0.0, minf(0.0, -e.z * PX_PER_Z))
		n = n.get_parent()
	return Vector2.ZERO


func _volume_center(area: Area2D, cs: CollisionShape2D, e: Entity, z_offset: float, height: float) -> Vector2:
	var ground := cs.global_position - _baked_offset(area, e)
	return ground + Vector2(0.0, -(e.z + z_offset + height * 0.5) * PX_PER_Z)


func _shape_outline(cs: CollisionShape2D) -> PackedVector2Array:
	var out := _local_outline(cs.shape)
	var xf := cs.global_transform
	for i in out.size():
		out[i] = xf * out[i]
	return out


func _local_outline(shape: Shape2D) -> PackedVector2Array:
	var out := PackedVector2Array()
	if shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		for i in circle_segments:
			out.append(Vector2.from_angle(TAU * i / circle_segments) * r)
	elif shape is RectangleShape2D:
		var h: Vector2 = (shape as RectangleShape2D).size * 0.5
		out.append(Vector2(-h.x, -h.y))
		out.append(Vector2(h.x, -h.y))
		out.append(Vector2(h.x, h.y))
		out.append(Vector2(-h.x, h.y))
	elif shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		var s := maxf(0.0, cap.height * 0.5 - cap.radius)
		var n := maxi(2, circle_segments >> 1)
		for i in n + 1:
			out.append(Vector2.from_angle(PI + PI * i / n) * cap.radius + Vector2(0.0, -s))
		for i in n + 1:
			out.append(Vector2.from_angle(PI * i / n) * cap.radius + Vector2(0.0, s))
	elif shape is ConvexPolygonShape2D:
		out = (shape as ConvexPolygonShape2D).points
	else:
		# unsupported shape type: small diamond so it's at least visible
		out.append(Vector2(0.0, -4.0))
		out.append(Vector2(4.0, 0.0))
		out.append(Vector2(0.0, 4.0))
		out.append(Vector2(-4.0, 0.0))
	return out


func _shifted(pts: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] + offset
	return out


func _centroid(pts: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in pts:
		sum += p
	return sum / maxf(1.0, float(pts.size()))
