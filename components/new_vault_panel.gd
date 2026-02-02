class_name NewVaultPanel
extends AnimatedPanel


signal created(vault_name: String, vault_color: String)
signal canceled

@export var new_vault_color_selector: ColorListContainer
@export var new_vault_error_label: Label
@export var new_vault_cancel_button: Button
@export var new_vault_create_button: Button

var selected_vault_name: String = ""
var selected_vault_color: String = "#ffffff"


func _ready() -> void:
	new_vault_error_label.hide()
	new_vault_create_button.disabled = true


func _on_new_vault_name_edit_text_changed(new_text: String) -> void:
	selected_vault_name = new_text.strip_edges()
	_validate_input()


func _on_new_vault_color_selector_color_changed(_color_name: String, color: Color) -> void:
	selected_vault_color = "#" + color.to_html()


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


func _reset_panel() -> void:
	selected_vault_name = ""
	selected_vault_color = "#ffffff"
	new_vault_error_label.hide()
	new_vault_create_button.disabled = true
