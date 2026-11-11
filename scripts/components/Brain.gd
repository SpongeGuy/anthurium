extends Component
class_name Brain

## Driver for entity behavior. Contains [BrainLobe] instances, which calculate a `priority`.
## When registered, the brain generates [BrainState] instances from [BrainStateBlueprint]s.[br]
## Every [member reevaluation_interval], the Brain loops through all lobes and picks the highest priority lobe. The Brain's [member top_machine] then switches to the cooresponding state registered in [member BainStateMachine.states].
## It is possible to define a hierarchical state machine using [ContainerState], which defines its own [BrainStateMachine] and cooresponding states, which use [method BrainStateMachine.transition_to] to switch between them.


func _on_registered() -> void:
	_memory_data.resize(Memory.size())
	_randomize_personality(RunRng.get_stream(&"personality"))
	for lobe in lobes:
		var state: BrainState = lobe.blueprint.instantiate(entity, self)
		state.lobe = lobe
		top_machine.add_state(lobe.state_name, state)


func _physics_process(delta: float) -> void:
	_clear_invalid_memory_data()
	_reevaluate_periodically(delta)
	top_machine.physics_process(delta)
	_tick_decrement_boredom_values(delta)
	_tick_lobe_cooldowns(delta)



# -------------------------------------------------------------------------------------
# brain -> lobe function
# --------------------------------------------------------------------------------------
@export var lobes: Array[BrainLobe] = []
var top_machine: BrainStateMachine = BrainStateMachine.new()
var boredom_values: Dictionary[BrainLobe, float] = {}
var lobe_cooldowns: Dictionary[BrainLobe, float] = {}
var current_lobe: BrainLobe

@export var reevaluation_interval: float = 0.5
@export var switch_priority_margin: float = 0.025 # hysteria (see below)
@export var boredom_growth_rate: float = 0.1
@export var boredom_decay_rate: float = 0.1
var _reeval_timer: float = 0.0

func _reevaluate_periodically(delta: float) -> void:
	_reeval_timer -= delta
	if _reeval_timer <= 0.0:
		_reeval_timer = reevaluation_interval
		_reevaluate_priorities()


func _reevaluate_priorities() -> void:
	var best_lobe: BrainLobe = null
	var best_score: float = -INF
	var current_score: float = -INF
	for lobe in lobes:
		var score: float = lobe.get_priority(entity)
		if is_lobe_on_cooldown(lobe):
			continue
		if lobe == current_lobe:
			score -= boredom_values.get(lobe, 0.0)
			current_score = score
		if score > best_score:
			best_score = score
			best_lobe = lobe
	if not best_lobe:
		return
	
	if best_lobe == current_lobe:
		boredom_values[current_lobe] = boredom_values.get(current_lobe, 0.0) + _effective_boredom_growth() * current_lobe.boredom_effectivity * reevaluation_interval
		return
	if best_score - current_score < switch_priority_margin:
		return	
	
	if current_lobe:
		current_lobe.on_disengage(entity, self)
	top_machine.transition_to(best_lobe.state_name)
	current_lobe = best_lobe

func _lobe_by_name(state_name: StringName) -> BrainLobe:
	for lobe in lobes:
		if lobe.state_name == state_name:
			return lobe
	return null

func _score_of(state_name: StringName) -> float:
	for lobe in lobes:
		if lobe.state_name == state_name:
			return lobe.get_priority(entity)
	return -INF

# ----------------- BOREDOM -----------------------------------------------------------------
# boredom is accumulated when a lobe is active, the rate of which depending on the lobe's boredom_effectivity

func _effective_boredom_growth() -> float:
	# aggressive creatures stay locked on longer, nervous ones break off sooner
	var aggression: float = get_personality_value(PERSONALITY.AGGRESSION)
	var nervous: float = get_personality_value(PERSONALITY.NERVOUS)
	return boredom_growth_rate * (1.0 + nervous - aggression)

func _tick_decrement_boredom_values(delta: float) -> void:
	for lobe in boredom_values.keys():
		if lobe == current_lobe:
			continue
		boredom_values[lobe] = maxf(0.0, boredom_values[lobe] - delta * (boredom_decay_rate))
	
# ----------------------- COOLDOWN ------------------------------------------------------
# cooldowns are gained in special cases. states can call cooldown_lobe to put the lobe it is under on cooldown

func set_lobe_cooldown(lobe: BrainLobe, seconds: float, reevaluate_now: bool = true) -> void:
	var was_on_cooldown: bool = is_lobe_on_cooldown(lobe)
	lobe_cooldowns[lobe] = maxf(seconds, lobe_cooldowns.get(lobe, 0.0))
	if reevaluate_now and not was_on_cooldown:
		_reeval_timer = 0.0

func is_lobe_on_cooldown(lobe: BrainLobe) -> bool:
	return lobe_cooldowns.get(lobe, 0.0) > 0.0

func _tick_lobe_cooldowns(delta: float)  -> void:
	for lobe in lobe_cooldowns.keys():
		var left: float = lobe_cooldowns[lobe] - delta
		if left <= 0.0:
			lobe_cooldowns.erase(lobe)
		else:
			lobe_cooldowns[lobe] = left

# --------------------------------------------------------------------------------------
# personality
# ---------------------------------------------------------------------------------------

# [0] = aggression
# [1] = bravery
# [2] = dominance
# [3] = energy
# [4] = nervous
# [5] = sympathy
var personality: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

enum PERSONALITY{AGGRESSION, BRAVERY, DOMINANCE, ENERGY, NERVOUS, SYMPATHY}

func _randomize_personality(rng: RandomNumberGenerator) -> void:
	for i in personality.size():
		personality[i] = snapped(rng.randf(), 0.001)

func get_personality_value(cat: PERSONALITY) -> float:
	return personality[cat]


# ------------------------------------------------------------------------------------------
# memory
# ---------------------------------------------------------------------------------------------------

## Use this to store and retrieve information that needs to travel between [BrainLobe]s.
enum Memory{
	TARGET,
	THREAT,
	NEMESIS,
	FAVORITE_ITEM,
	FRIEND,
	HOME_POSITION,
	LAST_THREAT_LOCATION,
	LAST_FOOD_LOCATION,
	SHORT_TERM_DESTINATION,
	LONG_TERM_DESTINATION,
	FOOD_SOURCE_POSITION,
}

var _ignored_entities: Array = []
var _memory_data: Array = []
			
func _clear_invalid_memory_data() -> void:
	for i in _memory_data.size():
		if not is_instance_valid(_memory_data[i]):
			_memory_data[i] = null
	
func set_memory(key: Brain.Memory, value: Variant) -> void:
	_memory_data[key] = value
	
func get_memory(key: Brain.Memory) -> Variant:
	return _memory_data[key]
	
func has_memory(key: Brain.Memory) -> bool:
	return _memory_data[key] != null
	
func erase_memory(key: Brain.Memory) -> void:
	_memory_data[key] = null
