extends Component
class_name InteractableComponent

signal interacted(source: Entity)

@export var effect: EntityEffect
var recently_interacted: Entity

func interact(source: Entity) -> void:
	Log.info("%s, %s" % [entity, source])
	recently_interacted = source
	interacted.emit(source)
	if effect:
		effect.execute(entity)
	
	
	
