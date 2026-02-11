extends PanelContainer

signal canceled
signal replace_request
signal merge_request

@export var unlock_v_box: VBoxContainer
@export var import_v_box: VBoxContainer
@export var line_edit: LineEdit

@export var unlock_button: Button
@export var merge_button: Button
@export var error_label: Label
@export var vaults_label: Label

var vault_path: String
var external_vault_data: Dictionary


func _ready() -> void:
	Chroma.bind_color(unlock_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(unlock_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(unlock_button, "stylebox/pressed", "bg_color", 0.9)
	
	Chroma.bind_color(merge_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(merge_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(merge_button, "stylebox/pressed", "bg_color", 0.9)
	


func assign(path: String) -> void:
	vault_path = path
	external_vault_data = {}
	error_label.hide()
	line_edit.clear()
	
	unlock_v_box.show()
	import_v_box.hide()


func _on_cancel_button_pressed() -> void:
	canceled.emit()


#func _on_replace_button_pressed() -> void:
	#VaultHandler.replace_vault(external_vault_data)
	#replace_request.emit()


func _on_merge_button_pressed() -> void:
	VaultHandler.merge_vault(external_vault_data)
	merge_request.emit()


func _on_unlock_button_pressed() -> void:
	external_vault_data = VaultHandler.unlock_vault(vault_path, line_edit.text)
	if external_vault_data:
		unlock_v_box.hide()
		import_v_box.show()
		
		var vault_names: PackedStringArray
		for vault_data: Dictionary in external_vault_data.get("vaults"):
			var v_name: String = vault_data.get("name")
			var v_key_count: int = vault_data.get("key_count")
			vault_names.append("%s (%s)" % [v_name, v_key_count])
		
		vaults_label.text = ", ".join(vault_names)
	else:
		error_label.text = "Could not unlock file. Check that the password is correct or the file is valid."
		error_label.show()
