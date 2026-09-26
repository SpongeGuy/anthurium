class_name EntityPool
extends Resource

@export var entries: Array[EntityPoolEntry] = []

var _cheapest_cost: float = -1.0 # cache, -1 = dirty

func pick_affordable(rng: RandomNumberGenerator, max_cost: float) -> EntityPoolEntry:
	var affordable: Array[EntityPoolEntry] = []
	var total_weight: float = 0.0
	for e in entries:
		if e.cost <= max_cost:
			affordable.append(e)
			total_weight += e.weight
	
	if affordable.is_empty():
		return null
	
	var roll: float = rng.randf() * total_weight
	var cursor: float = 0.0
	for e in affordable:
		cursor += e.weight
		if roll <= cursor:
			return e
	return affordable[-1]

## cheapest entry cost in the pool; lets the runtime know when it should give up early
func cheapest_cost() -> float:
	if _cheapest_cost < 0.0:
		_cheapest_cost = INF
		for e in entries:
			_cheapest_cost = minf(_cheapest_cost, e.cost)
	return _cheapest_cost
