extends Ability
class_name AbilityMeleeHit

@export var hurtbox: Hurtbox
@export var active_start: float
@export var active_end: float



func on_pressed() -> void:
	execute()

func _execute() -> void:
	await hurtbox.activate(active_start, active_end)
	finished.emit()

