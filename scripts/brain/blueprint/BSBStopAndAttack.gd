class_name BSBStopAndAttack extends BrainStateBlueprint

@export var ability_use_timer: float = 2.0
@export var timer_jitter: float = 1.0
@export var ability_to_use: int = 0
@export var attack_effect: EntityEffect

func _init() -> void:
	state_script = StateStopAndAttack

func _configure(state: BrainState) -> void:
	var s: StateStopAndAttack = state as StateStopAndAttack
	s.ability_use_timer = ability_use_timer
	s.timer_jitter = timer_jitter
	s.ability_to_use = ability_to_use
	s.attack_effect = attack_effect
