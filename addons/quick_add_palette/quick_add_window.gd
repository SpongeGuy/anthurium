@tool
extends Window

## Curated list shown in the palette, in order. A dict with a "divider" key
## starts a new labelled section; everything until the next divider (or the
## end of the list) belongs to it. Non-divider entries need "path" (a
## .tscn/.gd file, or a res:// uid); "name"/"description" are optional —
## name falls back to the file's basename, description falls back to
## blank. Section breaks below are placeholders — group/label them however
## makes sense to you.
const ENTRIES: Array[Dictionary] = [
	{"divider": "Packages"},
	{
		"path": "uid://britq7hc1nr0f",
		"name": "Health Package",
		"description": "has health, ichor, damage animation"
	},
	{
		"path": "uid://dqo7ynomdlqrv",
		"name": "Behavior Package",
		"description": "has brain, physics, locomotion, facing, ability manager, and input",
	},
	{"divider": "Stats"},
	{
		"path": "uid://rhl072pc6k5q",
		"name": "Health Component",
		"description": "Tracks HP, handles damage and death.",
	},
	{
		"path": "uid://cfrmrclnx8ldt",
		"name": "Ichor Component",
		"description": "Tracks an entity's ichor pool, including senescence-driven capacity decay.",
	},
	{
		"path": "uid://bfeyy2elbrj4b",
		"name": "Damage Animation Component",
		"description": "Plays a flash/knockback animation when the entity's Hurtbox is hit.",
	},
	{
		"class": "CollisionShape2D"
	},
	{"divider": "Combat"},
	{
		"path": "uid://bs06n3lj8bn1s",
		"name": "Hitbox",
	},
	{
		"path": "uid://dbcds6snlgl8h",
		"name": "Hurtbox",
	},
	{"divider": "Movement & Behavior"},
	{
		"path": "uid://bm176fnqfiea6",
		"name": "Physics Component",
	},
	{
		"path": "uid://dwy74leu2y8cr",
		"name": "Brain",
	},
	{
		"path": "uid://bmipqa5sa8rwt",
		"name": "Locomotion Handler",
	},
	{
		"path": "uid://bolv5v2qg2xl0",
		"name": "Facing Component",
	},
	{
		"class": "NavigationAgent2D",
	},
	{
		"path": "uid://bcbkki6gbrkma",
		"name": "Navigation Helper",
	},
	{
		"path": "uid://byeskwmhfllnd",
		"name": "Ability Manager",
	},
	{
		"path": "uid://dmr1e3ur3lqop",
		"name": "Input Component",
	},
	{"divider": "Interaction"},
	{
		"path": "uid://cpjm187a6ashx",
		"name": "Interactor",
	},
	{
		"path": "uid://dfj8s4mm1ck6t",
		"name": "Interactable",
	},
	{
		"path": "uid://dqikotd5sv8r6",
		"name": "Interaction Chain Component"
	},
	{"divider": "Display"},
	{
		"class": "Sprite2D"
	},
	{
		"path": "uid://carvudot6oer3",
		"name": "Sprite Animator",
	},
	{
		"path": "uid://cw28uq3fxf7i4",
		"name": "Directional Sprite Animator",
	},
	{
		"path": "uid://bkky2iu1meoku",
		"name": "Jump On Timer",
	},
	{
		"path": "uid://dqvhy2uty2seb",
		"name": "Cosmetic Glow"
	},
	{"divider": "Miscellaneous"},
	{
		"path": "uid://4neiv211rec6",
		"name": "Item Stage Manager",
	},
	{
		"path": "uid://d0066k548lth5",
		"name": "Baby Creator Helper",
	},
	{
		"path": "uid://cnaxik0pjumv5",
		"name": "Align When Idle"
	},
]

## Set by plugin.gd right after instantiation — needed to read the editor
## theme (for icons/fonts) and the edited scene's root.
var editor_interface: EditorInterface

var _search_box: LineEdit
var _rows_container: VBoxContainer
var _description_label: RichTextLabel
var _bold_font: FontVariation

var _item_lists: Array[ItemList] = []          # one per currently visible section
var _section_entries: Array = []               # parallel: [i] -> that section's Array[Dictionary]

const DIVIDER_HEIGHT: int = 12

func _ready() -> void:
	# get_editor_theme() is the documented way to fetch the actual editor
	# theme from a plugin; get_base_control().theme is an older, less
	# reliable fallback for versions that don't have it.
	theme = editor_interface.get_editor_theme() if editor_interface.has_method("get_editor_theme") \
		else editor_interface.get_base_control().theme

	title = "Quick Add"
	close_requested.connect(hide)
	size = Vector2i(420, 900)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search..."
	_search_box.text_changed.connect(_on_search_changed)
	layout.add_child(_search_box)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_rows_container)

	var desc_panel: PanelContainer = PanelContainer.new()
	desc_panel.custom_minimum_size = Vector2(0, 100)
	layout.add_child(desc_panel)

	_description_label = RichTextLabel.new()
	_description_label.bbcode_enabled = true
	_description_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_panel.add_child(_description_label)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

## Rebuilds the list from ENTRIES and clears any previous search filter.
## Called each time the window opens.
func refresh_list() -> void:
	_search_box.text = ""
	_populate_filtered("")
	_search_box.grab_focus()

func _on_search_changed(new_text: String) -> void:
	_populate_filtered(new_text)

## Rebuilds every section from ENTRIES. Each section becomes a small header
## Label plus its own ItemList (auto-sized to its own row count), so a
## header can be genuinely shorter than the rows below it — a single
## ItemList can't vary row height per-item. Sections with no filter matches
## are skipped entirely, header included.
func _populate_filtered(filter: String) -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	_item_lists.clear()
	_section_entries.clear()
	_description_label.text = ""

	var filter_lower: String = filter.to_lower()
	var current_header: String = ""
	var current_entries: Array[Dictionary] = []

	for entry in ENTRIES:
		if entry.has("divider"):
			_flush_section(current_header, current_entries)
			current_header = entry["divider"]
			current_entries = []
			continue
		var display_name: String = entry.get("name", _default_display_name(entry))   # CHANGED
		if filter_lower != "" and not display_name.to_lower().contains(filter_lower):
			continue
		current_entries.append(entry)
	_flush_section(current_header, current_entries)

	if not _item_lists.is_empty():
		_item_lists[0].select(0)
		_show_description(_section_entries[0][0])

func _flush_section(header: String, entries: Array[Dictionary]) -> void:
	if entries.is_empty():
		return
	if header != "":
		_add_header(header)
	_add_section_list(entries)

func _add_header(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, DIVIDER_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.961, 0.851, 0.572, 1.0))
	label.add_theme_font_override("font", _get_bold_font())
	_rows_container.add_child(label)

func _add_section_list(entries: Array[Dictionary]) -> void:
	var list: ItemList = ItemList.new()
	list.auto_height = true
	list.add_theme_font_size_override("font_size", 13)
	for entry in entries:
		var display_name: String = entry.get("name", _default_display_name(entry))
		list.add_item(display_name, _get_icon(entry))

	var index: int = _item_lists.size()
	list.item_selected.connect(_on_item_selected.bind(index))
	list.item_activated.connect(_on_item_activated.bind(index))

	_rows_container.add_child(list)
	_item_lists.append(list)
	_section_entries.append(entries)
	
func _default_display_name(entry: Dictionary) -> String:
	if entry.has("class"):
		return entry["class"]
	return _resolve_path(entry["path"]).get_file().get_basename()
	


## Only one selection across all sections at a time — clicking a row in one
## ItemList clears selection in every other one, so the description panel
## always reflects a single, unambiguous pick.
func _on_item_selected(row: int, list_index: int) -> void:
	for i in _item_lists.size():
		if i != list_index:
			_item_lists[i].deselect_all()
	_show_description(_section_entries[list_index][row])

func _show_description(entry: Dictionary) -> void:
	var display_name: String = entry.get("name", _default_display_name(entry))
	var description: String = entry.get("description", "")
	var footer: String = entry.get("class", entry.get("path", ""))
	_description_label.text = "[b]%s[/b]\n%s\n[i]%s[/i]" % [display_name, description, footer]

func _on_item_activated(row: int, list_index: int) -> void:
	_activate_entry(_section_entries[list_index][row])

## Synthetic bold via a FontVariation of the editor's default font, so this
## needs no bundled bold font file.
func _get_bold_font() -> FontVariation:
	if not _bold_font:
		_bold_font = FontVariation.new()
		_bold_font.base_font = theme.default_font if theme else ThemeDB.fallback_font
		_bold_font.variation_embolden = 1.0
	return _bold_font

## Resolves an editor icon for an entry without instantiating anything:
## .tscn reads its root node's type straight off SceneState, .gd reads the
## script's base engine type. Falls back to the generic Node icon if the
## editor theme has nothing registered for that type.
func _get_icon(entry: Dictionary) -> Texture2D:
	var class_str: String = "Node"

	if entry.has("class"):
		class_str = entry["class"]
	else:
		var path: String = entry["path"]
		var resolved_path: String = _resolve_path(path)
		if resolved_path.ends_with(".tscn"):
			var packed: PackedScene = load(path)
			if packed:
				class_str = packed.get_state().get_node_type(0)
		elif resolved_path.ends_with(".gd"):
			var script: Script = load(path)
			if script:
				class_str = script.get_instance_base_type()

	if theme and theme.has_icon(class_str, "EditorIcons"):
		return theme.get_icon(class_str, "EditorIcons")
	return editor_interface.get_base_control().get_theme_icon("Node", "EditorIcons")

## Resolves a uid:// string to its real res:// path; passes any other
## path string through unchanged.
static func _resolve_path(path: String) -> String:
	if not path.begins_with("uid://"):
		return path
	var resolved: String = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	if resolved == "":
		push_warning("Quick Add: could not resolve UID '%s'" % path)
	return resolved

## Double-click handler. Deliberately does NOT hide the window, and
## deliberately does NOT select the newly added node — either would make
## rapid-fire adds nest under whatever was just added instead of always
## landing on the scene root.
func _activate_entry(entry: Dictionary) -> void:
	var root: Node = editor_interface.get_edited_scene_root()
	if not root:
		push_warning("Quick Add: no scene open to add to.")
		return

	var instance: Node
	var default_name: String

	if entry.has("class"):
		var class_name_str: String = entry["class"]
		if not ClassDB.class_exists(class_name_str) or not ClassDB.can_instantiate(class_name_str):
			push_warning("Quick Add: '%s' is not an instantiable engine class." % class_name_str)
			return
		instance = ClassDB.instantiate(class_name_str)
		default_name = class_name_str
	else:
		var path: String = entry["path"]
		var resolved_path: String = _resolve_path(path)
		if resolved_path.ends_with(".tscn"):
			instance = load(path).instantiate()
			default_name = resolved_path.get_file().get_basename()
		else:
			var script: Script = load(path)
			if not script:
				push_warning("Quick Add: failed to load script at '%s'" % path)
				return
			var base_type: String = script.get_instance_base_type()
			instance = ClassDB.instantiate(base_type)
			instance.set_script(script)
			default_name = resolved_path.get_file().get_basename()

	instance.name = entry.get("name", default_name).replace(" ", "")

	root.add_child(instance)
	_claim_ownership(instance, root)

	if entry.has("path") and _resolve_path(entry["path"]).ends_with(".tscn"):
		root.set_editable_instance(instance, true)

## Newly added nodes (and, for .tscn, their whole subtree) need their
## owner set to the scene root or they look fine until you save and
## reload the scene, then silently vanish.
func _claim_ownership(node: Node, root: Node) -> void:
	node.owner = root
	if node.scene_file_path != "":
		return
	for child in node.get_children():
		_claim_ownership(child, root)
