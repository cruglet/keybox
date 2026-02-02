@tool
class_name ColorListContainer
extends FlowContainer

signal color_changed(color_name: String, color: Color)

const CIRCLE_FLAT = preload("uid://cl2w4dwu3w44v")

## Source of truth
@export var colors: Dictionary[String, Color]:
	set(c):
		colors = c
		_sync_color_order()


@export var selected_color: int = -1:
	set(sc):
		if color_order.size() > 0:
			selected_color = wrapi(sc, 0, color_order.size())
		else:
			selected_color = -1
		
		if Engine.is_editor_hint():
			_apply_selected_color()


@export_group("Color Orderer")
## Reorder-only
@export var color_order: Array[Color]:
	set(co):
		color_order = co
		if Engine.is_editor_hint():
			_rebuild_buttons()


@export var button_size: Vector2i = Vector2i(32, 32)


func _ready() -> void:
	if Engine.is_editor_hint():
		_rebuild_buttons()
		return
	
	_rebuild_buttons()


func create_color_button(color: Color) -> Button:
	var btn: Button = Button.new()
	btn.icon = CIRCLE_FLAT
	btn.expand_icon = true
	btn.toggle_mode = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = button_size
	btn.theme_type_variation = &"ColorButton"
	
	var normal_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	var hover_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	var pressed_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	
	normal_stylebox.draw_center = false
	normal_stylebox.border_color = Color.TRANSPARENT
	normal_stylebox.set_border_width_all(1)
	normal_stylebox.set_corner_radius_all(99)
	normal_stylebox.anti_aliasing = false
	btn.add_theme_color_override(&"icon_normal_color", color)
	btn.add_theme_stylebox_override(&"normal", normal_stylebox)
	
	var hover_bg_color: Color = color
	hover_bg_color.a = 0.1
	hover_stylebox.bg_color = hover_bg_color
	hover_stylebox.border_color = Color.TRANSPARENT
	hover_stylebox.set_border_width_all(1)
	hover_stylebox.set_corner_radius_all(99)
	hover_stylebox.anti_aliasing = false
	btn.add_theme_color_override(&"icon_hover_color", color)
	btn.add_theme_stylebox_override(&"hover", hover_stylebox)
	
	pressed_stylebox.bg_color = hover_bg_color
	pressed_stylebox.border_color = color
	pressed_stylebox.set_border_width_all(1)
	pressed_stylebox.set_corner_radius_all(99)
	pressed_stylebox.anti_aliasing = false
	btn.add_theme_color_override(&"icon_pressed_color", color)
	btn.add_theme_color_override(&"icon_hover_pressed_color", color)
	btn.add_theme_stylebox_override(&"pressed", pressed_stylebox)
	
	return btn


func get_selected_color_name() -> String:
	var color: Color = color_order[selected_color]
	for n: String in colors:
		if colors.get(n) == color:
			return n
	return ""


func _rebuild_buttons() -> void:
	for child: Node in get_children():
		child.queue_free()
	
	var index: int = 0
	
	for color: Color in color_order:
		var c_name: String = _get_color_name(color)
		if c_name.is_empty():
			index += 1
			continue
		
		var button: Button = create_color_button(color)
		button.toggled.connect(_on_toggle.bind(c_name, color, index, button))
		add_child(button)
		
		index += 1
	
	_apply_selected_color()


func _apply_selected_color() -> void:
	if selected_color < 0:
		return
	
	if selected_color >= get_child_count():
		return
	
	for i: int in get_child_count():
		var btn: Button = get_child(i) as Button
		btn.set_pressed_no_signal(i == selected_color)
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if i == selected_color else Control.MOUSE_FILTER_STOP


func _get_color_name(color: Color) -> String:
	for c_name: String in colors:
		if colors[c_name] == color:
			return c_name
	
	return ""


func _sync_color_order() -> void:
	if colors.is_empty():
		color_order.clear()
		return
	
	var new_order: Array[Color] = []
	
	for c: Color in color_order:
		if colors.values().has(c):
			new_order.append(c)
	
	for c: Color in colors.values():
		if not new_order.has(c):
			new_order.append(c)
	
	color_order = new_order


func _on_toggle(on: bool, c_name: String, color: Color, index: int, ref: Button) -> void:
	if not on:
		ref.set_pressed_no_signal(true)
		return
	
	for btn: Button in get_children():
		btn.set_pressed_no_signal(false)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	ref.set_pressed_no_signal(true)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	selected_color = index
	color_changed.emit(c_name, color)
