class_name CharacterSelector extends UIStage

var name_l: Label
var origin: Control

var speed: float = 8

var playables: Array[StringName] = [
	"focks", 
	"splitshroom", 
	"gnawlfy", 
	"drooler", 
	"maw"
]

var index: int = 0

const LEFT: Vector2 = Vector2(-100, 0)
const CENTER: Vector2 = Vector2(0, 0)
const RIGHT: Vector2 = Vector2(100, 0)

var old_e: Entity
var new_e: Entity

var old_e_target_pos: Vector2
var new_e_target_pos: Vector2

func _ready() -> void:
	name_l = find_child("NAME", true, true)
	origin = find_child("ORIGIN", true, true)

func _process(delta: float) -> void:
	if old_e:
		old_e.position = lerp(old_e.position, old_e_target_pos, delta * speed/2)
	if new_e:
		new_e.position = lerp(new_e.position, new_e_target_pos, delta * speed * 2)

func get_selected_playable_name() -> StringName:
	return playables[index]
	
func decrement() -> void:
	index -= 1
	if index < 0:
		index = playables.size() - 1

func increment() -> void:
	index += 1
	if index > playables.size() - 1:
		index = 0

func appear() -> void:
	set_up_display(CENTER)

func disappear() -> void:
	if old_e:
		old_e.queue_free()
	if new_e:
		new_e.queue_free()

func cycle_right() -> void:
	increment()
	if old_e:
		old_e.queue_free()
	old_e = new_e
	old_e_target_pos = LEFT
	new_e_target_pos = CENTER
	set_up_display(RIGHT)

func cycle_left() -> void:
	decrement()
	if old_e:
		old_e.queue_free()
	old_e = new_e
	old_e_target_pos = RIGHT
	new_e_target_pos = CENTER
	set_up_display(LEFT)

func set_up_display(e_location: Vector2) -> void:
	var e: Entity = EntityManager.create_entity(playables[index])
	e.position = e_location
	e.process_mode = Node.PROCESS_MODE_DISABLED
	e.hide_in_invisible_cells = false
	origin.add_child(e)
	new_e = e
	name_l.text = e.basename
	
