extends Ability
class_name AbilityTryPickUpEntity

@export var hand: HandComponent


func on_pressed() -> void:
	execute()

func _execute() -> void:
	hand.try_pick_up_item_in_area()
	finished.emit()
