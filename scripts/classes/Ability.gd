extends Node
class_name Ability

# ----------------------------------------------
# the Ability base class.
# use this to give custom logic to special abilities that creatures may possess.
# abilities can override on_pressed, on_held, on_released, and _execute.
# abiltiies should make use of cast_time when making an ability that executes when held for long enough.
# -----------------------------------------------

@export var cooldown: float = 0
@export var cast_time: float = 0
@export var disabled: bool = false
@export var icon: Texture2D

signal finished

var _cd: float = 0

func on_pressed() -> void:
	pass
	
func on_held(hold_duration: float, delta: float) -> void:
	pass
	
func on_released(hold_duration: float) -> void:
	pass

func _process(delta: float) -> void:
	if _cd > 0.0:
		_cd = max(_cd - delta, 0.0)

## try to execute, will not call _execute() if on cooldown
func execute() -> void:
	if disabled:
		return
	if _cd > 0.0:
		return
	_execute()
	_cd = cooldown

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	pass
