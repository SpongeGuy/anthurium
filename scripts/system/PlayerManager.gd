extends Node

# ------------------------------------
# 
# -----------------------------------

var player: Entity
var input: InputComponent
var facing: FacingComponent

func set_player(entity: Entity) -> void:
	if player:
		player.get_component(StateMachine).enable()
		input.player_controlled = false
		player = null
		input = null
		facing = null
	
	player = entity
	GameState.player = player
	input = player.get_component(InputComponent)
	input.player_controlled = true
	facing = player.get_component(FacingComponent)
	EventBus.player_spawned.emit(entity)


func _process(_delta: float) -> void:
	if not input:
		return
		
	
	for id in range(input.actions.size()):
		if Input.is_action_just_pressed(input.actions[id]):
			input.press_action(id)
		if Input.is_action_just_released(input.actions[id]):
			input.release_action(id)
			
	input.move_input_direction = Input.get_vector("west", "east", "north", "south")
	
	if facing:
		facing.change_direction(input.move_input_direction)
