extends Component
class_name InteractorComponent

@export var proximity: ProximityDetector
@export var input: InputComponent
@export var effect: EntityEffect

var _nearby: Array[Entity]

func _on_registered() -> void:
	proximity.detected.connect(_on_entity_detected)
	proximity.lost.connect(_on_entity_lost)

func _process(delta: float) -> void:
	if input.interact_just_pressed:
		print(_nearby)
		if effect:
			effect.execute(entity)
		var target: Entity
		var dist: float
		for e in _nearby:
			if not target:
				target = e
				dist = entity.global_position.distance_to(target.global_position)
				continue
			else:
				var new_dist: float = entity.global_position.distance_to(e.global_position)
				if new_dist < dist:
					target = e
					dist = new_dist
					continue
		
		if target:
			var interactable: InteractableComponent = target.get_component(InteractableComponent)
			interactable.interact(entity)
	
# THIS PROBABLY HAS TERRIABLE PEORFERMANCE
func _on_entity_detected(source: Entity, target: Entity) -> void:
	_nearby.append(target)
	
func _on_entity_lost(source: Entity, target: Entity) -> void:
	_nearby.erase(target)
