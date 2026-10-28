extends Node2D
class_name UIHand



## Navigates gui elements.
## Performs actions depending on the [InteractableUI] element's methods.
## Has utility methods relating to [AbilityHudUI] elements for managing [AbilityManager] [Ability] references, which are called by ui elements on the [UIHud].
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

enum State{DEFAULT, HOVER_OVER_ACTIVATE, HOVER_OVER_LIST, HOLDING, HOVER_OVER_GRAB}

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

@export var animations: Dictionary[State, SpriteAnimation] = {}

var current_state: State = State.DEFAULT

var _held_ability: Ability = null
var _held_slot: int = -1
var _held_element: AbilityHudElement = null

var _ability_manager: AbilityManager = null

var _navigate_sound: VoiceProfile = load("uid://ck7gjscvikr5")
var _activation_sound: VoiceProfile = load("uid://b1cwr2xunjytl")
var _place_sound: VoiceProfile = load("uid://bn0nptno78ae")
var _illegal_move_sound: VoiceProfile = load("uid://orxsqy4175p7")
var _toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")

var target_position: Vector2 = Vector2.ZERO
var move_tween: Tween

# ---------------------------------
# lifecycle
# ----------------------------------

func _on_activating_unactivateable() -> void:
	AudioManager.play_voice(_illegal_move_sound, null, true, false)


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	PlayerManager.player_set.connect(_on_player_set)

func _process(delta: float) -> void:
	var speed: float = 15
	if selected_element:
		print(selected_element)
		target_position = _get_interactable_selection_position(selected_element)
	global_position = global_position.lerp(target_position, 1.0 - exp(delta * -speed))
	
func illegal_move() -> void:
	AudioManager.play_voice(_illegal_move_sound, null, true, false)

func go_invisible() -> void:
	target_position = get_viewport_rect().get_center()
	selected_element = null
	visible = false
		
func control(delta: float) -> void:
	if not is_instance_valid(selected_element):
		return
	for dir in DIR_ACTIONS:
		var strength: float = Input.get_action_raw_strength(DIR_ACTIONS[dir])
		var is_down: bool = strength >= DEADZONE
		if is_down and not _dir_pressed[dir]:
			var next = selected_element.get_neighbor(dir)
			if next:
				switch_selected_element(next)
		_dir_pressed[dir] = is_down
	if Input.is_action_just_pressed("action_primary"):
		selected_element.activate(self)
				
	
		
func switch_stages(stage: UIStage) -> void:
	if stage.last_selected_element:
		switch_selected_element(stage.last_selected_element)
	else:
		switch_selected_element(stage.starting_element)
	selected_stage = stage
	visible = true


func switch_selected_element(element: Control) -> void:
	
	if selected_element:
		AudioManager.play_voice(_navigate_sound, null, true, false)
		selected_element.deselect(self)
	if element is UIStage:
		switch_stages(element)
		return
	
	selected_element = element
	if selected_element.stage:
		selected_element.stage.last_selected_element = selected_element
		
	if current_state != State.HOLDING:
		change_state(selected_element.type) # switch animation based on the type of InteractableUI
	selected_element.select(self)
	focus_changed.emit(selected_element)

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
# binding to ability manager
# ---------------------------------
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
		animator.play_animation(animations.get(to, "default"))
	label.text = ""
	match current_state:
		State.DEFAULT:
			pass
		State.HOVER_OVER_ACTIVATE:
			pass
		State.HOVER_OVER_LIST:
			pass
		State.HOLDING:
			label.text = _held_ability.display_name
			
# ---------- ability hand operations -----------------------------------

## Really only used from [InteractableUI] elements.
## Used to store an ability reference to either swap it or drop it.
func grab_ability_from(element: AbilityHudElement) -> bool:
	if current_state == State.HOLDING:
		return false
	if not _ability_manager:
		return false
	var ability: Ability = _ability_manager.get_ability(element.slot)
	if ability == null:
		return false
	_held_ability = ability
	_held_slot = element.slot
	_held_element = element
	element.ability_icon.visible = false
	grabbed_sprite.texture = ability.display_icon
	AudioManager.play_voice(_activation_sound, null, true, false)
	change_state(State.HOLDING)
	return true
	
## Really only used from [InteractableUI] elements.
func drop_ability_onto(element: AbilityHudElement) -> void:
	if current_state != State.HOLDING or _held_ability == null:
		return
	if not _ability_manager:
		return
	_ability_manager.swap_slots(_held_slot, element.slot)
	_release_held()
	AudioManager.play_voice(_place_sound, null, true, false)
	change_state(selected_element.type)
	element.select(self)

## Really only used from [InteractableUI] elements.
func toss_held_ability() -> bool:
	if _held_ability == null or _held_slot < 0:
		return false
	if not _ability_manager:
		return false
		
	# capture the slot before releasing so drop_to_shard can find it
	var slot: int = _held_slot
	# use the manager's entity position
	var spawn_pos: Vector2 = _ability_manager.entity.global_position
	_release_held()
	_ability_manager.drop_to_shard(slot, spawn_pos)
	AudioManager.play_voice(_activation_sound, null, true, false)
	AudioManager.play_sound(_toss_sound)
	change_state(selected_element.type)
	return true
	
func _release_held() -> void:
	if _held_element:
		_held_element.ability_icon.visible = true
	_held_ability = null
	_held_slot = -1
	_held_element = null
	grabbed_sprite.texture = null
	label.text = ""
