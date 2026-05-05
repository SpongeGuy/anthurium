extends Component
class_name RecentlyInteracted

# -----------------------------------------
# gets various sources (a collision box, an area, etc).
# connects up signals to set a recently_interacted variable.
# this recently_interacted variable gets set to null if it hasnt been set for an amount of time.
# other scripted components will have to interact with this component manually.
# -----------------------------------------

@export var proximity_area: ProximityDetector
@export var collider: CollisionShape2D

@export var expire_time: float = 3
var _timer: float = 0.0
var recently_interacted: Entity


func _ready() -> void:
	if proximity_area:
		proximity_area.detected.connect(_on_detected)
	
func _on_detected(source: Entity, other: Entity) -> void:
	interact(other)

func _process(delta: float) -> void:
	if _timer > 0:
		_timer -= delta

func interact(e: Entity) -> void:
	_timer = expire_time
	recently_interacted = e


# resolution chain
# recently_interacted -> follow that entity's OwnedBy chain -> return root
# if no recently_interacted,
# self -> follow self's OwnedBy's chain -> return root


# call this on the affected entity
# returns the originator of the effect
static func resolve_attribution(object: Entity) -> Entity:
	if object == null:
		return null
	
	# priority 1: someone recently interacted with this object
	var ri: RecentlyInteracted = object.get_component(RecentlyInteracted) as RecentlyInteracted
	if ri and ri.recently_interacted:
		return _follow_owner_chain(ri.recently_interacted)
		
	# priority 2: the object itself has an owner (e.g. it was thrown directly)
	return _follow_owner_chain(object)
	

static func _follow_owner_chain(e: Entity) -> Entity:
	var visited: Array[Entity] = []
	var current: Entity = e
	
	while current != null:
		if current in visited:
			break
		visited.append(current)
		
		var owned_by: OwnedBy = current.get_component(OwnedBy) as OwnedBy
		if owned_by and owned_by.owner_entity and owned_by.owner_entity != current:
			current = owned_by.owner_entity
		else:
			break
			
	# only return a root entity, one with no OwnedBy or an expired/null owner
	# a root entity is a "real" actor, not a projectile or effect
	var has_owner: bool = current.has_component(OwnedBy)
	return current if not has_owner else null
