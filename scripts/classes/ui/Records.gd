class_name Records extends Control

var record_box: VBoxContainer
var entries: Array[Control] = []

func _ready() -> void:
	record_box = find_child("RECORDS", true, true)
	clear_entries()

func clear_entries() -> void:
	for i in range(entries.size()):
		entries[i].queue_free()
	entries.clear()


func add_entry(name: String, score: int) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	
	var name_l: Label = Label.new()
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.text = name
	
	var space: PanelContainer = PanelContainer.new()
	space.custom_minimum_size = Vector2(25, 0)
	
	var score_l: Label = Label.new()
	score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_l.text = str(score)
	
	hbox.add_child(name_l)
	hbox.add_child(space)
	hbox.add_child(score_l)
	
	entries.append(hbox)
	record_box.add_child(hbox)
	
		
