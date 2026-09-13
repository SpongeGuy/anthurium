extends Component
class_name Brain




func _on_registered() -> void:
	_randomize_personality()
	for lobe in lobes:
		top_machine.add_state(lobe.state_name, lobe.blueprint.instantiate(entity, self))
		lobe._on_registered(entity)



# -------------------------------------------------------------------------------------
# brain -> lobe function
# --------------------------------------------------------------------------------------
@export var lobes: Array[BrainLobe] = []
var top_machine: BrainStateMachine = BrainStateMachine.new()

@export var reevaluation_interval: float = 0.5
@export var switch_priority_margin: float = 0.15 # hysteria (see below)
var _reeval_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_reeval_timer -= delta
	if _reeval_timer <= 0.0:
		_reeval_timer = reevaluation_interval
		_reevaluate_priorities()
	top_machine.physics_process(delta)

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
	if target == top_machine.current_name:
		return
		
	# hysteresis: only interrupt current goal if new one clearly wins
	# so priorities don't flap on noisy scores near a tie
	var current_score: float = _score_of(top_machine.current_name)
	if best_score - current_score < switch_priority_margin:
		return
	
	top_machine.transition_to(target)

func _score_of(state_name: StringName) -> float:
	for lobe in lobes:
		if lobe.state_name == state_name:
			return lobe.get_priority(entity)
	return -INF


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

func _randomize_personality() -> void:
	randomize()
	for i in personality.size():
		personality[i] = snapped(randf(), 0.001)

func get_personality_value(cat: PERSONALITY) -> float:
	return personality[cat]
