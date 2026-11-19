class_name AbilityDisplayComponent extends Component

@export var icon_offset: Vector2 = Vector2(0, -20)
var _icon: Sprite2D
var _label: Label

var theme: Theme = preload("res://assets/resources/themes/typecast.tres")

	

func _on_registered() -> void:
	_icon = Sprite2D.new()
	_icon.position = icon_offset
	_icon.visible = false
	entity.add_child(_icon)
	entity.register_z_node(_icon)

	_label = Label.new()
	_label.theme = theme
	_label.position = icon_offset + Vector2(-40, -26)
	_label.size = Vector2(80, 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.visible = false
	entity.add_child(_label)

	var interactable: InteractableComponent = entity.get_component(InteractableComponent)
	if interactable:
		interactable.focused.connect(func(_s: Entity) -> void: _label.visible = _icon.visible)
		interactable.unfocused.connect(func(_s: Entity) -> void: _label.visible = false)
	
	
func set_ability(id: StringName, price: float = 0.0) -> void:
	var def: AbilityDefinition = AbilityRegistry.get_ability_definition(id)
	_icon.texture = def.icon
	_icon.visible = true
	_label.text = "%s\n%s" % [def.display_name, def.description]
	if price > 0:
		_label.text += "\n%d pts" % int(price)
	



func clear() -> void:
	_icon.visible = false
	_label.visible = false
