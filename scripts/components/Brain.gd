extends Component
class_name Brain




func _on_registered() -> void:
	_memory_data.resize(Memory.size())
	_randomize_personality(RunRng.get_stream(&"personality"))
	for lobe in lobes:
		top_machine.add_state(lobe.state_name, lobe.blueprint.instantiate(entity, self))


func _physics_process(delta: float) -> void:
	_clear_invalid_memory_data()
	_reevaluate_periodically(delta)
	top_machine.physics_process(delta)
	_tick_decrement_boredom_values(delta)

# -------------------------------------------------------------------------------------
# brain -> lobe function
# --------------------------------------------------------------------------------------
@export var lobes: Array[BrainLobe] = []
var top_machine: BrainStateMachine = BrainStateMachine.new()
var boredom_values: Dictionary[BrainLobe, float] = {}
var current_lobe: BrainLobe

@export var reevaluation_interval: float = 0.5
@export var switch_priority_margin: float = 0.025 # hysteria (see below)
@export var boredom_growth_rate: float = 0.15
@export var boredom_decay_rate: float = 0.4
var _reeval_timer: float = 0.0

func _reevaluate_periodically(delta: float) -> void:
	_reeval_timer -= delta
	if _reeval_timer <= 0.0:
		_reeval_timer = reevaluation_interval
		_reevaluate_priorities()


func _reevaluate_priorities() -> void:
	var best_lobe: BrainLobe = null
	var best_score: float = -INF
	for lobe in lobes:
		var score: float = lobe.get_priority(entity)
		if score > best_score:
			best_score = score
			best_lobe = lobe
			
	if not best_lobe:
		return
	
	var target: StringName = best_lobe.state_name
	current_lobe = _lobe_by_name(top_machine.current_name)
	if not boredom_values.has(current_lobe):
		boredom_values[current_lobe] = 0.0
	if target == top_machine.current_name:
		var effectivity: float = current_lobe.boredom_effectivity if current_lobe else 1.0
		boredom_values[current_lobe] += _effective_boredom_growth() * effectivity * reevaluation_interval
		return
	
	# hysteresis: only interrupt current goal if new one clearly wins
	# so priorities don't flap on noisy scores near a tie
	var current_score: float = _score_of(top_machine.current_name) - boredom_values.get(current_lobe)
	if best_score - current_score < switch_priority_margin:
		return
	
	if current_lobe:
		current_lobe.on_disengage(entity, self)
	top_machine.transition_to(target)

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
