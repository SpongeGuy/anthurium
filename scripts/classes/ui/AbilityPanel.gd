class_name AbilityPanel extends Control
## One player's ability column, shown only while that player is managing their abilities
## (slides in from the nearest screen edge, doesn't pause the game). Pure view + layout:
## the arrow/grab/swap/toss behavior lives in [AbilityCursor].
##
## Layout matches the mockup: P1 top-left, P2 top-right, P3 bottom-left, P4 bottom-right.
## Positions are in the 640x360 game viewport.
##
## Each slot is a 22x22 frame. Ability icons are drawn at their native size (18x18), centered in the
## frame, never stretched.

enum ScreenSide { LEFT, RIGHT }

const VIEW_WIDTH: float = 640.0
const FRAME_SIZE: float = 22.0
const SLOT_GAP: float = 3.0
const SLOT_COUNT: int = 4
const EDGE_MARGIN: float = 3.0
const TITLE_HEIGHT: float = 10.0
const HIDDEN_MARGIN: float = 8.0
const SLIDE_TIME: float = 0.3
## Top y of the panel (title row) for slots 0..3: top row, then bottom row.
const PANEL_Y: Array[float] = [51.0, 51.0, 187.0, 187.0]

var slot: int = 0
var side: ScreenSide = ScreenSide.LEFT
var color: Color = Color.WHITE
var cursor: AbilityCursor
var is_open: bool = false

var _frame_texture: Texture2D = load("uid://dvt6eg4pxqerm")
var _icons: Array[TextureRect] = []
var _hidden_slot: int = -1
var _manager: AbilityManager
var _tween: Tween


## Builds the panel for player [param slot_index]. Call before adding to the tree.
func setup(slot_index: int) -> void:
	slot = slot_index
	side = ScreenSide.LEFT if slot % 2 == 0 else ScreenSide.RIGHT
	color = PlayerPalette.color_for(slot)
	theme = load("uid://bvh1budw06kq6")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(FRAME_SIZE, TITLE_HEIGHT + SLOT_COUNT * FRAME_SIZE + (SLOT_COUNT - 1) * SLOT_GAP)
	position = Vector2(_hidden_x(), PANEL_Y[slot % PANEL_Y.size()])
	visible = false
	_build()


func _build() -> void:
	var title: Label = Label.new()
	title.text = "P%d" % (slot + 1)
	title.position = Vector2.ZERO
	title.size = Vector2(FRAME_SIZE, TITLE_HEIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", color)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	for i in SLOT_COUNT:
		var y: float = _slot_y(i)

		var bg: ColorRect = ColorRect.new()
		bg.color = Color.BLACK
		bg.position = Vector2(0.0, y)
		bg.size = Vector2(FRAME_SIZE, FRAME_SIZE)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

		# Same draw order as the old HUD scene: frame first, ability icon on top of it.
		var frame: TextureRect = _make_rect(_frame_texture, y)
		frame.modulate = color
		add_child(frame)

		var icon: TextureRect = _make_rect(null, y)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED # native size, centered in the frame
		icon.visible = false
		add_child(icon)
		_icons.append(icon)

	cursor = AbilityCursor.new()
	cursor.setup(self)
	add_child(cursor)


func _make_rect(tex: Texture2D, y: float) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.position = Vector2(0.0, y)
	r.size = Vector2(FRAME_SIZE, FRAME_SIZE)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ----------------------------------------------
# geometry (used by the cursor)
# ----------------------------------------------

func _slot_y(i: int) -> float:
	return TITLE_HEIGHT + i * (FRAME_SIZE + SLOT_GAP)

func _shown_x() -> float:
	return EDGE_MARGIN if side == ScreenSide.LEFT else VIEW_WIDTH - EDGE_MARGIN - FRAME_SIZE

func _hidden_x() -> float:
	return -FRAME_SIZE - HIDDEN_MARGIN if side == ScreenSide.LEFT else VIEW_WIDTH + HIDDEN_MARGIN

## +1 for a left-side panel (arena is to the right), -1 for a right-side panel.
func inward() -> float:
	return 1.0 if side == ScreenSide.LEFT else -1.0

## Where the cursor arrow's tip sits for slot [param i], in panel-local coordinates.
func get_cursor_anchor(i: int) -> Vector2:
	var x: float = FRAME_SIZE + 3.0 if side == ScreenSide.LEFT else -3.0
	return Vector2(x, _slot_y(i) + FRAME_SIZE * 0.5)

## Top-left of slot [param i]'s frame in global coordinates (the cursor's held icon flies to/from here).
func get_slot_global_position(i: int) -> Vector2:
	return global_position + Vector2(0.0, _slot_y(i))


# ----------------------------------------------
# open / close
# ----------------------------------------------

func open() -> void:
	is_open = true
	visible = true
	_ensure_bound()
	refresh_icons()
	cursor.open()
	_slide_to(_shown_x(), false)

## Safety net: if nothing bound this panel to its player's entity yet, pick the entity up from PlayerManager.
func _ensure_bound() -> void:
	if _manager != null and is_instance_valid(_manager):
		return
	var ps: PlayerManager.PlayerSlot = PlayerManager.slots.get(slot)
	if ps != null and is_instance_valid(ps.entity):
		bind_entity(ps.entity)

func close() -> void:
	is_open = false
	cursor.close()
	_slide_to(_hidden_x(), true)

func _slide_to(x: float, hide_after: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:x", x, SLIDE_TIME)
	if hide_after:
		_tween.tween_callback(func() -> void: visible = false)


# ----------------------------------------------
# binding to the player's abilities
# ----------------------------------------------

func bind_entity(entity: Entity) -> void:
	unbind()
	_manager = entity.get_component(AbilityManager)
	if _manager:
		_manager.ability_registered.connect(_on_ability_registered)
		_manager.ability_unregistered.connect(_on_ability_unregistered)
	cursor.bind_manager(_manager)
	refresh_icons()

func unbind() -> void:
	if is_instance_valid(_manager):
		if _manager.ability_registered.is_connected(_on_ability_registered):
			_manager.ability_registered.disconnect(_on_ability_registered)
		if _manager.ability_unregistered.is_connected(_on_ability_unregistered):
			_manager.ability_unregistered.disconnect(_on_ability_unregistered)
	_manager = null
	cursor.bind_manager(null)
	refresh_icons()

func handle_input(action: StringName) -> void:
	cursor.handle_input(action)

func _on_ability_registered(_slot: int, _ability: Ability) -> void:
	refresh_icons()

func _on_ability_unregistered(_slot: int) -> void:
	refresh_icons()


# ----------------------------------------------
# icons
# ----------------------------------------------

## The held ability stays in the manager; its icon is just hidden while the cursor carries it.
func set_slot_hidden(i: int, hidden: bool) -> void:
	if hidden:
		_hidden_slot = i
	elif _hidden_slot == i:
		_hidden_slot = -1
	refresh_icons()

func clear_hidden_slot() -> void:
	_hidden_slot = -1
	refresh_icons()

func refresh_icons() -> void:
	var valid: bool = _manager != null and is_instance_valid(_manager)
	for i in SLOT_COUNT:
		var ability: Ability = null
		if valid and i < _manager.abilities.size():
			ability = _manager.get_ability(i)
		_icons[i].texture = ability.display_icon if ability else null
		_icons[i].visible = ability != null and i != _hidden_slot
	if cursor:
		cursor.validate_held()
