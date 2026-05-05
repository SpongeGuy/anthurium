extends Component
class_name StateMachine

signal state_switched(old_state: BehaviorState, new_state: BehaviorState)

var current_state: BehaviorState

@export var initial_state: BehaviorState
@export var death_state: BehaviorState

func _ready() -> void:
	if not initial_state:
		push_error("Initial state not set")
	switch(initial_state)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	
func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func switch(new_state: BehaviorState) -> void:
	# if new state is on cooldown, then don't switch to it
	
	if new_state.cooldown_timer > 0:
		return
	
	if current_state:
		current_state.exit()
	
	state_switched.emit(current_state, new_state)
	current_state = new_state
	current_state.enter()
	
func switch_to_death_state() -> void:
	switch(death_state)
