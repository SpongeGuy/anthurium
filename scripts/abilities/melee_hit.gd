extends Ability
class_name AbilityMeleeHit

@export var hurtbox: Hurtbox
@export var active_start: float
@export var active_end: float
@export var sprite: Sprite2D
@export var locomotion: LocomotionHandler


var _timer: float = 0
var time_to_use_ability: float = 0.8

func on_pressed(modifier: bool) -> void:
	locomotion.disabled = true
	
func on_held(hold_duration: float, delta: float, modifier: bool) -> void:
	_timer += delta
	if _timer >= time_to_use_ability:
		_timer = 0 - randf_range(0, 1)
		execute()
	
	sprite.position = floor(sin(GameMaster.time * 15)) * (Vector2.RIGHT * 2)
		
func on_released(hold_duration: float, modifier: bool) -> void:
	_timer = 0
	locomotion.disabled = false
	sprite.position = Vector2.ZERO

func _execute() -> void:
	await hurtbox.activate(active_start, active_end)
	finished.emit()
