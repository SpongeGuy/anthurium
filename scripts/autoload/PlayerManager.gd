extends Node

var player: Entity
var input: InputComponent
var facing: FacingComponent


signal player_set(entity: Entity)
signal player_died(entity: Entity)


func set_player(entity: Entity) -> void:
	if player:
		input.player_controlled = false
		player = null
		input = null
		facing = null
	
	player = entity
	input = player.get_component(InputComponent)
	input.player_controlled = true
	facing = player.get_component(FacingComponent)
	player_set.emit(player)
	player.died.connect(_on_player_death)
	
## Called by [AppController] when `Controller.PLAYER` is the `active_controller`
func control_player(_delta: float) -> void:
	if not (input and player):
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
		facing.set_direction_vector(input.move_input_direction)
	

func _on_player_death() -> void:
	Log.debug("Player %s died." % player)
	player_died.emit(player)
