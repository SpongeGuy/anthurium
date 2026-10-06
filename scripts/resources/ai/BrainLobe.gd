extends Resource
class_name BrainLobe

## Resource file for defining a behavior for an [Entity].
## On entity registration, the [Brain] then generates new [BrainState] instances and adds them to a dictionary with [member state_name] as the key and [member blueprint] as the value.

@export var state_name: StringName
@export var blueprint: BrainStateBlueprint
## how fast boredom accrues per second while this lobe is active.
## 0.0 = never gets bored, will hold this tate indefinitely once won.
## higher values make a lobe naturally cede priority back after a while, even if nothing has changed to make a competing lobe score higher.
@export var boredom_effectivity: float

func get_priority(_entity: Entity) -> float:
	return 0.0

func on_disengage(_entity: Entity, _brain: Brain) -> void:
	pass
