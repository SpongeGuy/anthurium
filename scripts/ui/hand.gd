extends Node2D
class_name Hand

@export var current: InteractableUI
@export var animator: SpriteAnimator
@export var grabbed_sprite: Sprite2D
@export var label: Label

enum State{DEFAULT, HOVER_OVER_ACTIVATEABLE, HOVER_OVER_LIST, HOLDING}

signal focus_changed(element: InteractableUI)
signal state_changed(to: State)

var navigate_sound: AudioStream = load("res://assets/sounds/effects/put.wav")

var current_state: State = State.DEFAULT

var selected_element: AbilityHudElement
var holding: Dictionary = {}

var activation_sound: AudioStream = load("res://assets/sounds/effects/pickup.wav")
var place_sound: AudioStream = load("res://assets/sounds/effects/align.wav")
var toss_sound: AudioStream = load("res://assets/sounds/effects/throw.wav")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_changed.connect(_on_state_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not current:
		return
	global_position = current.get_screen_position() + (current.size - Vector2(8, 4))
	
	if GameState.state != GameState.Status.PAUSED:
		return
		
	for dir in DIR_ACTIONS:
		if Input.is_action_just_pressed(DIR_ACTIONS[dir]):
			print(Time.get_ticks_msec())
			var next = current.get_neighbor(dir)
			if next:
				AudioManager.play_sound(navigate_sound)
				current.deselect(self)
				current = next
				focus_changed.emit(current)
				current.select(self)
				
	if Input.is_action_just_pressed("ui_accept"):
		current.activate(self)

				
	
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


func change_state(state: State) -> void:
	if current_state == state:
		return
		
	current_state = state
	state_changed.emit(state)


func _on_state_changed(to: State) -> void:
	label.text = ""
	match current_state:
		State.DEFAULT:
			pass
		State.HOVER_OVER_ACTIVATEABLE:
			pass
		State.HOVER_OVER_LIST:
			pass
		State.HOLDING:
			label.text = holding.ability.display_name

func grab_ability() -> void:
	if current_state == State.HOLDING:
		return
	if selected_element is not AbilityHudElement:
		return
	
	var ability_manager: AbilityManager = PlayerManager.player.get_component(AbilityManager)
	if not ability_manager.abilities.get(selected_element.slot):
		return
	holding.ability = ability_manager.abilities[selected_element.slot]
	holding.slot = selected_element.slot
	#ability_manager.abilities[selected_element.slot] = null
	
	grabbed_sprite.texture = selected_element.ability_icon.texture
	AudioManager.play_sound(activation_sound)
	change_state(State.HOLDING)
	
func drop_ability() -> void:
	if current_state != State.HOLDING:
		return
	if selected_element is not AbilityHudElement:
		return
		
	var ability_manager: AbilityManager = PlayerManager.player.get_component(AbilityManager)
	if not ability_manager:
		return
	
	var swap = ability_manager.abilities[selected_element.slot]
	ability_manager.abilities[selected_element.slot] = holding.ability
	if selected_element.slot != holding.slot:
		ability_manager.abilities[holding.slot] = swap
	
	holding.ability = null
	holding.erase("slot")
	
	grabbed_sprite.texture = null
	AudioManager.play_sound(place_sound)
	change_state(State.HOVER_OVER_ACTIVATEABLE)
	selected_element.select(self)

func toss_ability() -> void:
	if not holding.has("ability") or not holding.has("slot"):
		return
	var ability_manager: AbilityManager = PlayerManager.player.get_component(AbilityManager)
	if not ability_manager:
		return
	
	ability_manager.abilities[holding.slot] = null
	ability_manager.drop_ability_shard_from_ability(holding.ability, PlayerManager.player.global_position)
	
	grabbed_sprite.texture = null
	holding.ability = null
	holding.erase("slot")
	label.text = ""
	current_state = Hand.State.HOVER_OVER_ACTIVATEABLE
	AudioManager.play_sound(toss_sound)
