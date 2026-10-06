class_name EntityPoolEntry
extends Resource
@export var entity_type: StringName
## points spent from the wave budget each time this entity is picked
@export var cost: float = 1.0
## weight once fully ramped in. higher = picked more often relative to other entries
@export var weight: float = 1.0

@export_group("Escalation Curve")
## escalation (wave_number) before which this entity never spawns
@export var unlock_at: float = 0.0
## escalation at which the weight reaches its full value, ramping smoothly up from unlock_at.
## leave at or below unlock_at for "full weight immediately".
@export var full_at: float = 0.0
## escalation at which the weight starts fading out. negative = never fades
@export var fade_start: float = -1.0
## how many escalation steps the fade takes
@export var fade_length: float = 10.0
## fraction of weight left once the fade completes (0 = disappears entirely)
@export_range(0.0, 1.0) var fade_floor: float = 0.15

#@export var escalation_curve: Curve


func weight_at(escalation: float) -> float:
	#return weight * escalation_curve.sample(escalation)
	if escalation < unlock_at:
		return 0.0
	
	var w: float = weight
	# ramp in: 0 -> full weight between unlock_at and full_at
	if full_at > unlock_at:
		w *= smoothstep(unlock_at, full_at, escalation)
		
	# fade out: full weight -> fade_floor over fade_length
	if fade_start >= 0.0 and escalation > fade_start:
		var f: float = clampf((escalation - fade_start) / maxf(fade_length, 0.001), 0.0, 1.0)
		w *= lerpf(1.0, fade_floor, f)
	
	return w
