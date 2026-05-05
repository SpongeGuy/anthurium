extends Component
class_name OwnedBy

# ---------------------------------------------------
# used in resolving attribution chains when trying to determine the causality of events
# if an entity is spawning a projectile or explosion, set owner_entity to that entity
# it is up to your discretion if you want to set an owner to living entities, this could cause some unintended behavior
# or it could be funy haha :)))))
# ---------------------------------------------------

var owner_entity: Entity

func _init(owned_by: Entity = null) -> void:
	if owned_by:
		give_owner(owned_by)

func give_owner(owned_by: Entity) -> void:
	owner_entity = owned_by

