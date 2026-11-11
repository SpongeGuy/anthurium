class_name EscalationCurve extends Resource

## a 0..1 multiplier over escalation. [br]
## ramps in, holds, then optionally fades out.[br]
## shared by spawn entries (scales weight) and spawn modifiers (scales chance).

## escalation before which multiplier is 0
@export var unlock_at: float = 0.0
## escalation at which the multiplier reaches 1, ramping smoothly up from unlock_at
## leave at or below unlock_at for "full strength immediately"
@export var full_at: float = 0.0
## escalation at which the multplier starts fading out. negative = never fades
@export var fade_start: float = -1.0
## how many escalation steps the fade takes
@export var fade_length: float = 10.0
## fraction of strength left once fade complets (0 = disappears entirely)
@export_range(0.0, 1.0) var fade_floor: float = 0.15


func evaluate(escalation: float) -> float:
	if escalation < unlock_at:
		return 0.0
	
	var m: float = 1.0
	if full_at > unlock_at:
		m *= smoothstep(unlock_at, full_at, escalation)
	
	if fade_start >= 0.0 and escalation > fade_start:
		var f: float = clampf((escalation - fade_start) / maxf(fade_length, 0.001), 0.0, 1.0)
		m *= lerpf(1.0, fade_floor, f)
		
	return m
