extends Node2D
class_name DebugUIHelper

@export var show: bool = false
@export var vbox: VBoxContainer
@export var title: Label
@export var l1: Label
@export var l2: Label
@export var l3: Label
@export var l4: Label

var coords: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	show = true
	if not show:
		visible = false
		return
		
	if not CameraController.camera:
		return
	
	title.text = ""
	l1.text = ""
	l2.text = ""
	l3.text = ""
	l4.text = ""
	
	var screen_pos: Vector2 = get_viewport().get_mouse_position()
	vbox.position = screen_pos + Vector2(5, 2)
	coords = CameraController.get_world_mouse_position()
	
	
	var space = AppController.world_2d.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = coords
	query.collide_with_bodies = true
	var results = space.intersect_point(query)
	
	if results.is_empty():
		l4.text = ""
		return
	
	var subject: Node2D = results[0].collider
	if subject is not Entity:
		return
	
	var entity: Entity = subject as Entity
	
	display_base_stats(title, entity)
	
	if entity.has_component(Brain):
		display_entity_brain_state(l1, entity)
	
	if entity.has_component(HeartbeatEmitter) or entity.has_component(ArteryComponent) or entity.has_component(HeartbeatReceptor):
		update_anthurium(entity)
	
	
func update_anthurium(entity: Entity) -> void:
	display_coordinates(l2)
	display_anthurium_esoterica(l3, entity)
	
func display_base_stats(label: Label, entity: Entity) -> void:
	var string: String = ""
	string += str(entity.get_basename(), "\n")
	if entity.has_component(HealthComponent):
		string += str("hp: ", entity.get_component(HealthComponent).health, "\n")
	if entity.has_component(PhysicsComponent):
		string += str("physv: ", entity.get_component(PhysicsComponent).physics_velocity, "\n")
	string += str("v: ", entity.velocity, "\n")
	if entity.has_component(IchorComponent):
		var ich: IchorComponent = entity.get_component(IchorComponent)
		var s: String = "ich: %d/%d \n" % [ich.ichor, ich.max_ichor] 
		string += s
	label.text = string
	
func display_coordinates(label: Label) -> void:
	label.text = str(WorldGrid.world_to_tile(coords))
	
	
func display_anthurium_esoterica(label: Label, entity: Entity) -> void:
	var string: String = ""
	string += str(AnthuriumInterface.esoterica.get_string(), "\n")
	
	var bloom: BloomPotentialComponent = entity.get_component(BloomPotentialComponent)
	if bloom:
		string += str("bloom: %f" % bloom.value)
	label.text = string


func display_entity_brain_state(label: Label, entity: Entity) -> void:
	var brain: Brain = entity.get_component(Brain)
	if not brain:
		return

	var lines: Array[String] = []
	_append_state_path(brain.top_machine, lines, 0)

	var string: String = "PERSONALITY:\n"
	string += _format_personality(brain)
	string += "\nBRAIN STATE:\n"
	string += "\n".join(lines)
	string += "\n\nLOBES:\n"
	string += _format_lobe_priorities(brain, entity)
	label.text = string

func _format_lobe_priorities(brain: Brain, entity: Entity) -> String:
	var scored: Array[Dictionary] = []
	for lobe in brain.lobes:
		scored.append({"lobe": lobe, "score": lobe.get_priority(entity)})

	scored.sort_custom(func(a, b): return a["score"] > b["score"])

	var lines: Array[String] = []
	for entry in scored:
		var lobe: BrainLobe = entry["lobe"]
		var score: float = entry["score"]
		var marker: String = " <-- active" if lobe.state_name == brain.top_machine.current_name else ""
		lines.append("  %s: %.3f%s" % [lobe.state_name, score, marker])

	return "\n".join(lines)

func _append_state_path(machine: BrainStateMachine, lines: Array[String], depth: int) -> void:
	if machine.current_name == &"" or not machine.current_state:
		lines.append("%s(idle)" % "  ".repeat(depth))
		return

	var indent: String = "  ".repeat(depth)
	lines.append("%s%s" % [indent, machine.current_name])

	if machine.current_state is ContainerState:
		var container: ContainerState = machine.current_state
		_append_state_path(container.inner_machine, lines, depth + 1)

func _format_personality(brain: Brain) -> String:
	var parts: Array[String] = []
	for i in Brain.PERSONALITY.size():
		var key: String = Brain.PERSONALITY.keys()[i]
		var value: float = brain.personality[i]
		if i == 3:
			parts.append("\n")
		parts.append("%s:%.2f" % [key, value])
	return ", ".join(parts)
	
