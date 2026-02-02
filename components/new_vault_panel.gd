class_name NewVaultPanel
extends AnimatedPanel


signal created(vault_name: String, vault_color: String)
signal canceled

@export var new_vault_color_selector: ColorListContainer
@export var new_vault_error_label: Label
@export var new_vault_cancel_button: Button
@export var new_vault_create_button: Button
@export var colorscheme_label: Label

var selected_vault_name: String = ""
var selected_vault_color: String = "#ffffff"


func _ready() -> void:
	await owner.ready
	selected_vault_color = "#" + new_vault_color_selector.get_selected_color().to_html()
	new_vault_error_label.hide()
	new_vault_create_button.disabled = true
	_update_create_button_color()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE:
		canceled.emit()


func _on_new_vault_name_edit_text_changed(new_text: String) -> void:
	selected_vault_name = new_text.strip_edges()
	_validate_input()


func _on_new_vault_color_selector_color_changed(_color_name: String, color: Color) -> void:
	selected_vault_color = "#" + color.to_html()
	colorscheme_label.text = "Vault Colorscheme: %s" % new_vault_color_selector.get_selected_color_name()
	_update_create_button_color()


func _on_new_vault_create_button_pressed() -> void:
	if selected_vault_name.is_empty():
		_show_error("Vault name cannot be empty.")
		return
	
	var existing_names: Array[String] = VaultHandler.get_vault_names()
	if selected_vault_name in existing_names:
		_show_error("A vault with this name already exists.")
		return
	
	created.emit(selected_vault_name, selected_vault_color)
	_reset_panel()


func _on_new_vault_cancel_button_pressed() -> void:
	canceled.emit()
	_reset_panel()


func _validate_input() -> void:
	var is_valid: bool = not selected_vault_name.is_empty()
	new_vault_create_button.disabled = not is_valid
	
	if is_valid:
		new_vault_error_label.hide()


func _show_error(message: String) -> void:
	new_vault_error_label.text = message
	new_vault_error_label.show()


func _update_create_button_color() -> void:
	var color: Color = Color(selected_vault_color)
	
	var normal_style: StyleBoxFlat = new_vault_create_button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal_style.bg_color = color
	new_vault_create_button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style: StyleBoxFlat = new_vault_create_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	hover_style.bg_color = Chroma.modify_color(color, 1.1)
	new_vault_create_button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style: StyleBoxFlat = new_vault_create_button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	pressed_style.bg_color = Chroma.modify_color(color, 0.9)
	new_vault_create_button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style: StyleBoxFlat = new_vault_create_button.get_theme_stylebox("disabled").duplicate() as StyleBoxFlat
	disabled_style.bg_color = Chroma.modify_color(color, 0.9)
	new_vault_create_button.add_theme_stylebox_override("disabled", disabled_style)



func _reset_panel() -> void:
	selected_vault_name = ""
	new_vault_error_label.hide()
	new_vault_create_button.disabled = true
