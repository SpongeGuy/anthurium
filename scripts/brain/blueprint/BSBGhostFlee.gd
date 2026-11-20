class_name BSBGhostFlee extends BrainStateBlueprint

# provide exported variables to be set in _configure()

func _init() -> void:
	state_script = StateGhostFlee

# set state's values to the exported values here
func _configure(_state: BrainState) -> void:
	pass

