extends Component
class_name InteractableComponent

signal interacted(source: Entity)

@export var effect: EntityEffect
var recently_interacted: Entity

func interact(source: Entity) -> void:
	recently_interacted = source
	if effect:
		effect.execute(entity)
	
	interacted.emit(source)
	

