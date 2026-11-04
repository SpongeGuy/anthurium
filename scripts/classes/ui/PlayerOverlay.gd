class_name PlayerOverlay extends Node2D
## World-space clues attached to a player entity (no always-on health/ichor bars):
##  - a blinking arrow above the head in the player's color
##  - a short row of hearts that pops up for a moment whenever health changes, then fades
## Attached by UiController when PlayerManager binds an entity to a slot.

const HEART_PIXELS: Array[String] = [
	".XX.XX.",
	"XXXXXXX",
	"XXXXXXX",
	".XXXXX.",
	"..XXX..",
	"...X...",
]
const HEART_W: int = 7
const HEART_H: int = 6
const HEART_FULL: Color = Color(1.0, 0.23, 0.31)
const HEART_EMPTY: Color = Color(0.3, 0.3, 0.36)

@export var blink_interval: float = 0.35
## Hearts shown are a fraction of max health, so this works with any health scale.
@export var heart_count: int = 3
@export var heart_gap: int = 1
@export var heart_show_time: float = 1.6
@export var heart_fade_time: float = 0.4

var slot: int = 0
var color: Color = Color.WHITE

var _entity: Entity
var _health: HealthComponent
var _arrow_on: bool = true
var _blink_t: float = 0.0
var _heart_t: float = 0.0
var _fraction: float = 1.0
var _last_health: float = -1.0


## Adds (or re-colors) the overlay on [param entity]. Safe to call on every bind: players carried
## between levels keep their existing overlay.
static func attach(entity: Entity, slot: int) -> PlayerOverlay:
	var existing: PlayerOverlay = entity.get_node_or_null("PlayerOverlay") as PlayerOverlay
	if existing:
		existing.slot = slot
		existing.color = PlayerPalette.color_for(slot)
		existing.queue_redraw()
		return existing
	var overlay: PlayerOverlay = PlayerOverlay.new()
	overlay.name = "PlayerOverlay"
	overlay.slot = slot
	overlay.color = PlayerPalette.color_for(slot)
	entity.add_child(overlay)
	return overlay


func _ready() -> void:
	_entity = get_parent() as Entity
	if _entity == null:
		queue_free()
		return
	z_index = 20
	position = Vector2(0.0, _compute_top() - 2.0)
	_entity.register_z_node(self) # rides along with jumps
	_health = _entity.get_component(HealthComponent)
	if _health:
		_last_health = _health.health
		_health.health_changed.connect(_on_health_changed)

func _compute_top() -> float:
	var v: Sprite2D = _entity.visual
	if v == null or v.texture == null:
		return -8.0
	var h: float = v.texture.get_height() / float(maxi(v.vframes, 1))
	return v.position.y - (h * 0.5 if v.centered else 0.0) + v.offset.y

func _on_health_changed(value: float, max_value: float) -> void:
	if is_equal_approx(value, _last_health):
		return
	_last_health = value
	_fraction = value / max_value if max_value > 0.0 else 0.0
	_heart_t = heart_show_time
	queue_redraw()

func _process(delta: float) -> void:
	_blink_t += delta
	if _blink_t >= blink_interval:
		_blink_t = 0.0
		_arrow_on = not _arrow_on
		queue_redraw()
	if _heart_t > 0.0:
		_heart_t -= delta
		queue_redraw()

func _draw() -> void:
	if _arrow_on:
		draw_colored_polygon(PackedVector2Array([Vector2(-4.5, -5.0), Vector2(4.5, -5.0), Vector2(0.0, 1.5)]), Color.BLACK)
		draw_colored_polygon(PackedVector2Array([Vector2(-3.0, -4.0), Vector2(3.0, -4.0), Vector2(0.0, 0.0)]), color)
	if _heart_t > 0.0:
		_draw_hearts()

func _draw_hearts() -> void:
	var alpha: float = clampf(_heart_t / heart_fade_time, 0.0, 1.0)
	var filled: int = ceili(_fraction * heart_count)
	if _fraction > 0.0:
		filled = maxi(filled, 1)
	var total_w: int = heart_count * HEART_W + (heart_count - 1) * heart_gap
	var x0: float = -floorf(total_w / 2.0)
	var y0: float = -7.0 - HEART_H
	for h in heart_count:
		var col: Color = HEART_FULL if h < filled else HEART_EMPTY
		col.a = alpha
		var hx: float = x0 + h * (HEART_W + heart_gap)
		for py in HEART_H:
			var row: String = HEART_PIXELS[py]
			for px in HEART_W:
				if row[px] == "X":
					draw_rect(Rect2(hx + px, y0 + py, 1.0, 1.0), col)
