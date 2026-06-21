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


@export var current: InteractableUI
@export var animator: SpriteAnimator
@export var grabbed_sprite: Sprite2D
@export var label: Label

enum State{DEFAULT, HOVER_OVER_ACTIVATEABLE, HOVER_OVER_LIST, HOLDING}

signal focus_changed(element: InteractableUI)
signal state_changed(to: State)

const DIR_ACTIONS = {
	Vector2i.LEFT: "west",
	Vector2i.RIGHT: "east",
	Vector2i.UP: "north",
	Vector2i.DOWN: "south"
}

const STATE_ANIMS = {
	State.DEFAULT: "default",
	State.HOVER_OVER_ACTIVATEABLE: "hov_activateable",
	State.HOVER_OVER_LIST: "hov_list",
	State.HOLDING: "holding",
}

var current_state: State = State.DEFAULT

var selected_element: InteractableUI

# The ability currently "held" visually, and the slot it came from.
# The ability is NOT extracted from the manager until a drop or toss confirms the action.
var _held_ability: Ability = null
var _held_slot: int = -1

var _ability_manager: AbilityManager = null

var _navigate_sound: AudioStream = load("res://assets/sounds/effects/put.wav")
var _activation_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var _place_sound: AudioStream = load("res://assets/sounds/effects/align.wav")
var _toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")

# ---------------------------------
# lifecycle
# ----------------------------------



func _ready() -> void:
	state_changed.connect(_on_state_changed)
	PlayerManager.player_set.connect(_on_player_set)

func _process(delta: float) -> void:
	if not current:
		return
	global_position = current.get_screen_position() + (current.size - Vector2(8, 4))
	
	if GameState.state != GameState.Status.PAUSED:
		return
		
	for dir in DIR_ACTIONS:
		if Input.is_action_just_pressed(DIR_ACTIONS[dir]):
			var next = current.get_neighbor(dir)
			if next:
				AudioManager.play_sound(_navigate_sound)
				current.deselect(self)
				current = next
				focus_changed.emit(current)
				current.select(self)
				
	if Input.is_action_just_pressed("ui_accept"):
		current.activate(self)

				
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
