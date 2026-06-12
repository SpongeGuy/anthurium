extends Node

# ------------------------------------
# 
# -----------------------------------

var player: Entity
var input: InputComponent
var facing: FacingComponent

signal player_set(entity: Entity)

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
	player_set.emit(player)
	CameraController.change_camera_target(player)
	CameraController.go_instantly_to(player.global_position)

func _process(_delta: float) -> void:
	if not input:
		return
		
	if not GameState.state == GameState.Status.PLAYING:
		return
	
	
	for id in range(input.actions.size()):
		if Input.is_action_just_pressed(input.actions[id]):
			input.press_action(id)
		if Input.is_action_just_released(input.actions[id]):
			input.release_action(id)
		
		if Input.is_action_just_pressed("action_modifier"):
			input.press_modifier()
		if Input.is_action_just_released("action_modifier"):
			input.release_modifier()
			
		if Input.is_action_just_pressed("action_interact"):
			input.press_interact()
		if Input.is_action_just_released("action_interact"):
			input.release_interact()
			
	input.move_input_direction = Input.get_vector("west", "east", "north", "south")
	
	if facing:
		facing.change_direction(input.move_input_direction)
