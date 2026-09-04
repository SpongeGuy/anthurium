extends Node2D
class_name UIHand

## Navigates [InteractableUI] elements and performs ability inventory operations
## on behalf of the player.
##
## The hand is bound to a player's [AbilityManager] via [method bind_ability_manager]
## (called by [UIController] whenever the player entity changes). All ability slot
## mutations go through [AbilityManager]'s public API — the hand never writes to
## [code]abilities[][/code] directly.
##
## Lifecycle for a grab-and-drop:
##   1. Hand hovers over an [AbilityHudElement] → [method grab_ability_from] is called.
##      The ability stays in the manager; only the visual representation is "held."
##   2a. Hand activates another [AbilityHudElement] → [method drop_ability_onto] calls
##       [method AbilityManager.swap_slots], which handles both swap and move cases.
##   2b. Hand activates the [TossZone] → [method toss_held_ability] calls
##       [method AbilityManager.drop_to_shard], removing the ability from the manager
##       and spawning a world shard.

var selected_element: InteractableUI
var selected_stage: UIStage
@onready var grabbed_sprite: Sprite2D = $Grabbed
@onready var animator: SpriteAnimator = $SpriteAnimator
@onready var label: Label = $Control/Label

const DEADZONE: float = 0.75

var height: float = 8

enum State{DEFAULT, HOVER_OVER_ACTIVATEABLE, HOVER_OVER_LIST, HOLDING}

signal focus_changed(element: InteractableUI)
signal state_changed(to: State)

const DIR_ACTIONS = {
	Vector2i.LEFT: "west",
	Vector2i.RIGHT: "east",
	Vector2i.UP: "north",
	Vector2i.DOWN: "south"
}

var _dir_pressed: Dictionary = {
	Vector2i.LEFT: false,
	Vector2i.RIGHT: false,
	Vector2i.UP: false,
	Vector2i.DOWN: false
}

const STATE_ANIMS = {
	State.DEFAULT: "default",
	State.HOVER_OVER_ACTIVATEABLE: "hov_activateable",
	State.HOVER_OVER_LIST: "hov_list",
	State.HOLDING: "holding",
}

var current_state: State = State.DEFAULT

# The ability currently "held" visually, and the slot it came from.
# The ability is NOT extracted from the manager until a drop or toss confirms the action.
var _held_ability: Ability = null
var _held_slot: int = -1

var _ability_manager: AbilityManager = null

var _navigate_sound: VoiceProfile = load("uid://ck7gjscvikr5")
var _activation_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var _place_sound: AudioStream = load("res://assets/sounds/effects/align.wav")
var _toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")

var target_position: Vector2 = Vector2.ZERO
var move_tween: Tween

# ---------------------------------
# lifecycle
# ----------------------------------



func _ready() -> void:
	state_changed.connect(_on_state_changed)
	PlayerManager.player_set.connect(_on_player_set)

func _process(delta: float) -> void:
	var speed: float = 15
	if selected_element:
		target_position = _get_interactable_selection_position(selected_element)
	global_position = global_position.lerp(target_position, 1.0 - exp(delta * -speed))
		
func go_invisible() -> void:
	target_position = Vector2(-100, -100)
	selected_element = null
	visible = false
		
func control(delta: float) -> void:
	for dir in DIR_ACTIONS:
		var strength: float = Input.get_action_raw_strength(DIR_ACTIONS[dir])
		var is_down: bool = strength >= DEADZONE
		if is_down and not _dir_pressed[dir]:
			var next = selected_element.get_neighbor(dir)
			if next:
				AudioManager.play_voice(_navigate_sound, null, true, false)
				selected_element.deselect(self)
				switch_selected_element(next)
				focus_changed.emit(selected_element)
				selected_element.select(self)
		_dir_pressed[dir] = is_down
	if Input.is_action_just_pressed("action_primary"):
		selected_element.activate(self)
				
		
func switch_stages(stage: UIStage) -> void:
	if stage.last_selected_element:
		print(stage.last_selected_element)
		switch_selected_element(stage.last_selected_element)
	else:
		switch_selected_element(stage.starting_element)
	selected_stage = stage
	visible = true


func switch_selected_element(element: Control) -> void:
	if element is UIStage:
		switch_stages(element)
		return
	
	selected_element = element
	if selected_element.stage:
		selected_element.stage.last_selected_element = selected_element
	if move_tween:
		move_tween.kill()

func _get_interactable_selection_position(element: InteractableUI) -> Vector2:
	if not element.selection_location:
		return _get_control_screen_position(element)
	return element.selection_location.global_position
				
func _get_control_screen_position(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas().origin
	
func _get_control_center(control: Control) -> Vector2:
	var transform: Transform2D = control.get_global_transform_with_canvas()
	return transform.origin + transform.basis_xform(control.size * 0.5)
	
func _get_settled_position(control: Control) -> Vector2:
	if control.is_inside_tree() and control.size != Vector2.ZERO:
		return _get_control_center(control)
	await control.resized
	return _get_control_center(control)
# --------------------------------
# binding
# ---------------------------------
## Binds this hand to [param manager]. Called by [UIController] on player change.
## Clears any held ability from the previous session before switching.
func bind_ability_manager(manager: AbilityManager) -> void:
	if _held_ability != null:
		_release_held()
		change_state(State.DEFAULT)
	_ability_manager = manager
	
func _on_player_set(entity: Entity) -> void:
	var ability_manager: AbilityManager = entity.get_component(AbilityManager)
	if ability_manager:
		bind_ability_manager(ability_manager)

# -------------- state ------------------------------------------

func change_state(state: State) -> void:
	if current_state == state:
		return
	current_state = state
	state_changed.emit(state)


func _on_state_changed(to: State) -> void:
	if animator:
		animator.load_and_reset_animation(STATE_ANIMS.get(to, "default"))
	label.text = ""
	match current_state:
		State.DEFAULT:
			pass
		State.HOVER_OVER_ACTIVATEABLE:
			pass
		State.HOVER_OVER_LIST:
			pass
		State.HOLDING:
			label.text = _held_ability.display_name
			
# ---------- ability hand operations -----------------------------------

## Visually picks up the ability in [param element]'s slot.
##
## The ability is not removed from [AbilityManager]; it remains active and
## usable while held. Call [method drop_ability_onto] or [method toss_held_ability]
## to confirm the action.
func grab_ability_from(element: AbilityHudElement) -> void:
	if current_state == State.HOLDING:
		return
	if not _ability_manager:
		return
	var ability: Ability = _ability_manager.get_ability(element.slot)
	if ability == null:
		return
	_held_ability = ability
	_held_slot = element.slot
	grabbed_sprite.texture = ability.icon
	AudioManager.play_sound(_activation_sound)
	change_state(State.HOLDING)
	
## Drops the held ability onto [param element]'s slot.
##
## Delegates to [method AbilityManager.swap_slots], which handles both cases:
## - Target slot occupied  → abilities swap positions between the two slots.
## - Target slot empty     → held ability moves to the target slot, origin becomes empty.
func drop_ability_onto(element: AbilityHudElement) -> void:
	if current_state != State.HOLDING or _held_ability == null:
		return
	if not _ability_manager:
		return
	_ability_manager.swap_slots(_held_slot, element.slot)
	_release_held()
	AudioManager.play_sound(_place_sound)
	change_state(State.HOVER_OVER_ACTIVATEABLE)
	element.select(self)

## Tosses the held ability to the world as an [AbilityShard].
##
## Calls [method AbilityManager.drop_to_shard], which extracts the ability from
## its slot (emitting [signal AbilityManager.ability_unregistered] so the HUD
## updates automatically) and spawns a shard at the owning entity's feet.
func toss_held_ability() -> void:
	if _held_ability == null or _held_slot < 0:
		return
	if not _ability_manager:
		return
		
	# capture the slot before releasing so drop_to_shard can find it
	var slot: int = _held_slot
	# use the manager's entity position
	var spawn_pos: Vector2 = _ability_manager.entity.global_position
	_release_held()
	_ability_manager.drop_to_shard(slot, spawn_pos)
	AudioManager.play_sound(_toss_sound)
	change_state(State.HOVER_OVER_ACTIVATEABLE)
	
func _release_held() -> void:
	_held_ability = null
	_held_slot = -1
	grabbed_sprite.texture = null
	label.text = ""
