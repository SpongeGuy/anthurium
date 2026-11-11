class_name AbilityCursor extends Control
## One player's cursor inside their [AbilityPanel]: a colored arrow beside the panel that moves
## up/down the slots. Replaces UIHand for in-game ability management (every player has their own).
##
## Input (routed from PlayerManager.menu_input via UiController -> panel.handle_input):
##   up / down          move between slots
##   action_primary     grab the ability under the arrow; while holding, drop it onto a slot (swap/move)
##   action_secondary   while holding, put it back
##   action_ternary     while holding, toss it into the world as a shard
##
## The held icon visibly lifts out of its slot and travels to the cursor; dropping or putting back
## flies it into the target slot; tossing flicks it toward the arena and fades it out.
## The ability itself never leaves the AbilityManager until a swap/toss actually happens.

const SPEED: float = 20.0
const HELD_LABEL_WIDTH: float = 96.0
const GRAB_TIME: float = 0.12
const LAND_TIME: float = 0.1
const TOSS_TIME: float = 0.18

var index: int = 0

var _panel: AbilityPanel
var _manager: AbilityManager
var _held_slot: int = -1
var _held_ability: Ability
var _target: Vector2 = Vector2.ZERO
var _busy: bool = false # a grab/land/toss animation is playing; actions wait, movement doesn't
var _tween: Tween
var _held_rest: Vector2 = Vector2.ZERO # held icon position relative to the cursor

var _arrow: Polygon2D
var _arrow_outline: Polygon2D
var _held_icon: TextureRect
var _held_label: Label

var _navigate_sound: VoiceProfile = load("uid://ck7gjscvikr5")
var _activation_sound: VoiceProfile = load("uid://b1cwr2xunjytl")
var _place_sound: VoiceProfile = load("uid://bn0nptno78ae")
var _illegal_move_sound: VoiceProfile = load("uid://orxsqy4175p7")
var _toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")


func setup(panel: AbilityPanel) -> void:
	_panel = panel
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dir: float = _panel.inward()

	_arrow_outline = Polygon2D.new()
	_arrow_outline.color = Color.BLACK
	_arrow_outline.polygon = PackedVector2Array([Vector2(-1.5 * dir, 0.0), Vector2(6.0 * dir, -5.5), Vector2(6.0 * dir, 5.5)])
	add_child(_arrow_outline)

	_arrow = Polygon2D.new()
	_arrow.color = _panel.color
	_arrow.polygon = PackedVector2Array([Vector2(0.0, 0.0), Vector2(5.0 * dir, -4.0), Vector2(5.0 * dir, 4.0)])
	add_child(_arrow)

	_held_rest = Vector2(1.0 if dir > 0.0 else -1.0 - AbilityPanel.FRAME_SIZE, -AbilityPanel.FRAME_SIZE * 0.5)
	_held_icon = TextureRect.new()
	_held_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_held_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED # native size, same as in the slot
	_held_icon.size = Vector2(AbilityPanel.FRAME_SIZE, AbilityPanel.FRAME_SIZE)
	_held_icon.position = _held_rest
	_held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_icon.visible = false
	add_child(_held_icon)

	var settings: LabelSettings = LabelSettings.new()
	settings.font = load("uid://bnfnnxpb5a004")
	settings.font_size = 8
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	_held_label = Label.new()
	_held_label.label_settings = settings
	_held_label.size = Vector2(HELD_LABEL_WIDTH, 10.0)
	_held_label.position = Vector2(1.0 if dir > 0.0 else -1.0 - HELD_LABEL_WIDTH, AbilityPanel.FRAME_SIZE * 0.5 + 1.0)
	_held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if dir > 0.0 else HORIZONTAL_ALIGNMENT_RIGHT
	_held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_label.visible = false
	add_child(_held_label)

	_update_target()
	position = _target


func _process(delta: float) -> void:
	position = position.lerp(_target, 1.0 - exp(-SPEED * delta))


# ----------------------------------------------
# lifecycle
# ----------------------------------------------

func bind_manager(manager: AbilityManager) -> void:
	_release_held()
	_manager = manager

func open() -> void:
	index = clampi(index, 0, AbilityPanel.SLOT_COUNT - 1)
	_update_target()
	position = _target

func close() -> void:
	_release_held()

## Called by the panel whenever the manager's slots change. If something else removed or moved the
## ability we're carrying (consumed, destroyed, swapped by game logic), drop the carry visuals.
func validate_held() -> void:
	if _held_ability == null:
		return
	if not _manager_ok() or not is_instance_valid(_held_ability) or _manager.get_ability(_held_slot) != _held_ability:
		_release_held()


# ----------------------------------------------
# input
# ----------------------------------------------

func handle_input(action: StringName) -> void:
	if action == &"up":
		_move(-1)
		return
	if action == &"down":
		_move(1)
		return
	if _busy:
		return
	match action:
		&"action_primary":
			_activate()
		&"action_secondary":
			_put_back()
		&"action_ternary":
			_toss()

func _move(step: int) -> void:
	index = posmod(index + step, AbilityPanel.SLOT_COUNT)
	_update_target()
	AudioManager.play_voice(_navigate_sound, null, true, false)

func _update_target() -> void:
	_target = _panel.get_cursor_anchor(index)

func _is_holding() -> bool:
	return _held_ability != null

func _manager_ok() -> bool:
	return _manager != null and is_instance_valid(_manager)


# ----------------------------------------------
# actions
# ----------------------------------------------

func _activate() -> void:
	if not _manager_ok():
		_illegal()
		return
	if _is_holding():
		_drop_onto(index)
	else:
		_grab(index)

func _grab(slot: int) -> void:
	var ability: Ability = _manager.get_ability(slot)
	if ability == null:
		_illegal()
		return
	_held_ability = ability
	_held_slot = slot
	_held_icon.texture = ability.display_icon
	_held_label.text = ability.display_name
	_panel.set_slot_hidden(slot, true) # the slot's own icon is the one being lifted
	AudioManager.play_voice(_activation_sound, null, true, false)

	# start exactly on top of the slot's icon, then travel to the cursor
	_kill_tween()
	_busy = true
	_set_arrow_visible(false)
	_held_label.visible = false
	_held_icon.visible = true
	_held_icon.modulate.a = 1.0
	_held_icon.global_position = _panel.get_slot_global_position(slot)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_held_icon, "position", _held_rest, GRAB_TIME)
	_tween.tween_callback(_finish_grab)

func _finish_grab() -> void:
	_held_label.visible = _is_holding()
	_busy = false

func _drop_onto(target_slot: int) -> void:
	var from: int = _held_slot
	# the ability is no longer "held": from here on the icon is just flying into place
	_held_ability = null
	_held_slot = -1
	if target_slot != from:
		_manager.swap_slots(from, target_slot) # handles swap and move-to-empty; emits slot signals
	_fly_into(from, target_slot)
	AudioManager.play_voice(_place_sound, null, true, false)

func _put_back() -> void:
	if not _is_holding():
		return
	var from: int = _held_slot
	_held_ability = null
	_held_slot = -1
	_fly_into(from, from)
	AudioManager.play_voice(_place_sound, null, true, false)

func _toss() -> void:
	if not _is_holding() or not _manager_ok():
		return
	var from: int = _held_slot
	var spawn_pos: Vector2 = _manager.entity.global_position
	_held_ability = null
	_held_slot = -1
	_panel.set_slot_hidden(from, false)
	_manager.drop_to_shard(from, spawn_pos)
	AudioManager.play_voice(_activation_sound, null, true, false)
	AudioManager.play_sound(_toss_sound)

	_kill_tween()
	_busy = true
	_held_label.visible = false
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_held_icon, "position:x", _held_icon.position.x + AbilityPanel.FRAME_SIZE * _panel.inward(), TOSS_TIME)
	_tween.tween_property(_held_icon, "modulate:a", 0.0, TOSS_TIME)
	_tween.chain().tween_callback(_finish_toss)

func _finish_toss() -> void:
	_held_icon.visible = false
	_held_icon.modulate.a = 1.0
	_held_icon.position = _held_rest
	_set_arrow_visible(true)
	_busy = false


# ----------------------------------------------
# animation helpers
# ----------------------------------------------

## Flies the held icon into [param landing]'s slot. The icon in that slot stays hidden until it lands.
func _fly_into(from: int, landing: int) -> void:
	_kill_tween()
	_busy = true
	_held_label.visible = false
	if from != landing:
		_panel.set_slot_hidden(from, false) # the origin shows its new contents right away
	_panel.set_slot_hidden(landing, true)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_held_icon, "global_position", _panel.get_slot_global_position(landing), LAND_TIME)
	_tween.tween_callback(_finish_land.bind(landing))

func _finish_land(landing: int) -> void:
	_held_icon.visible = false
	_held_icon.position = _held_rest
	_panel.set_slot_hidden(landing, false)
	_set_arrow_visible(true)
	_busy = false

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

func _set_arrow_visible(on: bool) -> void:
	_arrow.visible = on
	_arrow_outline.visible = on

func _illegal() -> void:
	AudioManager.play_voice(_illegal_move_sound, null, true, false)

## Instantly drops all carry state and visuals (no animation). Used on close, rebind, and when
## the carried ability disappears from under us.
func _release_held() -> void:
	_kill_tween()
	_held_ability = null
	_held_slot = -1
	_busy = false
	_held_icon.visible = false
	_held_icon.modulate.a = 1.0
	_held_icon.texture = null
	_held_icon.position = _held_rest
	_held_label.visible = false
	_held_label.text = ""
	_set_arrow_visible(true)
	_panel.clear_hidden_slot()
