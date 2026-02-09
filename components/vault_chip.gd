class_name VaultChip
extends Button


signal vault_toggled(vault_index: int)
signal vault_edit(vault_index: int)
signal vault_delete(vault_index: int)

@export var is_preview: bool

var use_chroma: bool = false:
	set(value):
		use_chroma = value
		if is_node_ready():
			if value:
				_bind_chroma()
			else:
				_unbind_chroma()
				_apply_vault_color()

var vault_index: int = -1

var vault_name: String = "":
	set(value):
		vault_name = value
		_update_display()

var vault_color: String = "#ffffff":
	set(value):
		vault_color = value
		if not use_chroma:
			_apply_vault_color()

var key_count: int = 0:
	set(value):
		key_count = value
		_update_display()

var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selected_state()


func _ready() -> void:
	pressed.connect(_on_pressed)
	if use_chroma:
		_bind_chroma()
	else:
		_apply_vault_color()
	_update_display()
	_update_selected_state()


func _bind_chroma() -> void:
	Chroma.bind_color(self, "stylebox/normal", "border_color", 1.0, 1.0)
	Chroma.bind_color(self, "stylebox/normal", "bg_color", 1.0, 0.0)
	Chroma.bind_color(self, "stylebox/hover", "border_color", 1.0, 1.0)
	Chroma.bind_color(self, "stylebox/hover", "bg_color", 1.0, 0.15)
	Chroma.bind_color(self, "stylebox/pressed", "border_color", 1.0, 1.0)
	Chroma.bind_color(self, "stylebox/pressed", "bg_color", 1.0, 0.3)
	Chroma.bind_color(self, "color/icon_normal_color", "", 1.0, 1.0)
	Chroma.bind_color(self, "color/icon_hover_color", "", 1.0, 1.0)
	Chroma.bind_color(self, "color/icon_pressed_color", "", 1.0, 1.0)
	Chroma.bind_color(self, "color/icon_hover_pressed_color", "", 1.0, 1.0)


func _unbind_chroma() -> void:
	Chroma.unbind_color(self, "stylebox/normal", "border_color")
	Chroma.unbind_color(self, "stylebox/normal", "bg_color")
	Chroma.unbind_color(self, "stylebox/hover", "border_color")
	Chroma.unbind_color(self, "stylebox/hover", "bg_color")
	Chroma.unbind_color(self, "stylebox/pressed", "border_color")
	Chroma.unbind_color(self, "stylebox/pressed", "bg_color")
	Chroma.unbind_color(self, "color/icon_normal_color", "")
	Chroma.unbind_color(self, "color/icon_hover_color", "")
	Chroma.unbind_color(self, "color/icon_pressed_color", "")
	Chroma.unbind_color(self, "color/icon_hover_pressed_color", "")


func _apply_vault_color() -> void:
	if not is_node_ready():
		return
	
	var color: Color = Color(vault_color)
	
	var normal_style: StyleBoxFlat = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal_style.border_color = color
	normal_style.bg_color = Color(color.r, color.g, color.b, 0.0)
	add_theme_stylebox_override("normal", normal_style)
	
	var hover_style: StyleBoxFlat = get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	hover_style.border_color = color
	hover_style.bg_color = Color(color.r, color.g, color.b, 0.15)
	add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style: StyleBoxFlat = get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	pressed_style.border_color = color
	pressed_style.bg_color = Color(color.r, color.g, color.b, 0.3)
	add_theme_stylebox_override("pressed", pressed_style)
	
	add_theme_color_override("icon_normal_color", color)
	add_theme_color_override("icon_hover_color", color)
	add_theme_color_override("icon_pressed_color", color)
	add_theme_color_override("icon_hover_pressed_color", color)


func _update_display() -> void:
	if vault_name.is_empty():
		text = "Vault (%d)" % key_count
	else:
		text = "%s (%d)" % [vault_name, key_count]


func _update_selected_state() -> void:
	if not is_node_ready():
		return
	
	mouse_filter = MOUSE_FILTER_IGNORE if is_selected else MOUSE_FILTER_STOP
	button_pressed = is_selected


func _on_pressed() -> void:
	vault_toggled.emit(vault_index)


func _on_popup_id_pressed(id: int) -> void:
	match id:
		0:
			vault_edit.emit(vault_index)
		1:
			vault_delete.emit(vault_index)
