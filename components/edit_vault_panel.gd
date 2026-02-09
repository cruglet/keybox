class_name EditVaultPanel
extends PanelContainer

signal delete_request
signal save_request(v_name: String, v_color: Color)
signal canceled

@export var vault_name_edit: LineEdit
@export var vault_color_selector: ColorListContainer
@export var colorscheme_label: Label
@export var edit_v_box: VBoxContainer
@export var delete_v_box: VBoxContainer
@export var are_you_sure: Label

@export var save_button: Button
var selected_vault_color: String
var curr_accent_color: Color


func assign() -> void:
	curr_accent_color = Chroma.accent_color
	vault_name_edit.text = VaultHandler.get_selected_vault_name()
	selected_vault_color = VaultHandler.get_selected_vault_color()
	
	var index: int = vault_color_selector.color_order.find(Color(selected_vault_color))
	vault_color_selector.selected_color = max(0, index)
	_update_save_button_color()
	_update_colorscheme_text()


func _update_save_button_color() -> void:
	var color: Color = Color(selected_vault_color)
	
	var normal_style: StyleBoxFlat = save_button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal_style.bg_color = color
	save_button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style: StyleBoxFlat = save_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	hover_style.bg_color = Chroma.modify_color(color, 1.1)
	save_button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style: StyleBoxFlat = save_button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	pressed_style.bg_color = Chroma.modify_color(color, 0.9)
	save_button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style: StyleBoxFlat = save_button.get_theme_stylebox("disabled").duplicate() as StyleBoxFlat
	disabled_style.bg_color = Chroma.modify_color(color, 0.9)
	save_button.add_theme_stylebox_override("disabled", disabled_style)


func _update_colorscheme_text() -> void:
	colorscheme_label.text = "Vault Colorscheme: " + vault_color_selector.get_selected_color_name()


func _on_vault_color_selector_color_changed(_color_name: String, color: Color) -> void:
	selected_vault_color = "#" + color.to_html()
	Chroma.set_accent_color(color)
	_update_save_button_color()
	_update_colorscheme_text()


func _on_cancel_button_pressed() -> void:
	Chroma.set_accent_color(curr_accent_color)
	canceled.emit()


func _on_save_button_pressed() -> void:
	var vault_name: String = vault_name_edit.text.strip_edges()
	save_request.emit(vault_name, Color(selected_vault_color))


func _on_delete_button_pressed() -> void:
	are_you_sure.text = "Are you sure you want to delete \"%s\"?\n\nThis \
is permanent, and all stored passwords under this vault will be deleted." % VaultHandler.get_selected_vault_name()
	delete_v_box.show()
	edit_v_box.hide()


func _on_vault_name_edit_text_changed(new_text: String) -> void:
	save_button.disabled = true
	
	var vault_name: String = new_text.strip_edges()
	if vault_name.is_empty():
		return
	if vault_name.length() > 32:
		return
	for c: int in vault_name.length():
		var ch: String = vault_name.substr(c, 1)
		if not ch.is_valid_identifier() and ch != " " and ch != "-":
			return
	
	save_button.disabled = false


func _on_delete_cancel_button_pressed() -> void:
	delete_v_box.hide()
	edit_v_box.show()


func _on_true_delete_button_pressed() -> void:
	delete_request.emit()
