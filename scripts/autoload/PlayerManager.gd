## Autoload: PlayerManager
##
## Tracks which [Entity] is the current player and routes raw [Input] into
## that entity's [InputComponent]/[FacingComponent] each frame. Call
## [method control_player] from [code]AppController._process()[/code] only
## while the [enum AppController.Controller] mode is [code]PLAYER[/code].
extends Node

# ------------------------------------
# 
# -----------------------------------

## The [Entity] currently controlled by the player, or [code]null[/code] if
## none is set.
var player: Entity
## The current player's [InputComponent], cached by [method set_player].
var input: InputComponent
## The current player's [FacingComponent], cached by [method set_player].
var facing: FacingComponent

## Emitted whenever a new entity is assigned as the player via
## [method set_player].
signal player_set(entity: Entity)
## Emitted when the current player's [HealthComponent] reports death.
signal player_died(entity: Entity)


## Assigns [param entity] as the controlled player: re-enables the previous
## player's [StateMachine] and releases input control from it, then hands
## input control to [param entity] and connects its [HealthComponent] (if
## any) to [method _on_player_death]. Emits [signal player_set].
func set_player(entity: Entity) -> void:
	if player:
		player.get_component(StateMachine).enable()
		input.player_controlled = false
		player = null
		input = null
		facing = null
	
	player = entity
	input = player.get_component(InputComponent)
	input.player_controlled = true
	facing = player.get_component(FacingComponent)
	player_set.emit(player)
	
	var health: HealthComponent = player.get_component(HealthComponent)
	if health:
		health.died.connect(_on_player_death)
	
## Polls the action/modifier/interact inputs and movement axis each frame
## and forwards them to the current player's [InputComponent] and
## [FacingComponent]. No-op if no player is set.
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
	
## Connected to the player's [HealthComponent.died]; logs the death and
## emits [signal player_died].
func _on_player_death() -> void:
	Log.debug("Player %s died." % player)
	player_died.emit(player)
