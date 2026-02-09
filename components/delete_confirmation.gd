class_name DeleteConfirmation
extends PanelContainer

signal delete_request(ref: VaultEntry)
signal canceled

@export var cancel_button: Button
@export var delete_button: Button

@export var entry_name: Label
@export var entry_user: Label
@export var vault_name: Label

var entry_ref: VaultEntry


func assign(ref: VaultEntry) -> void:
	entry_ref = ref
	entry_name.text = entry_ref.entry_name
	entry_user.text = entry_ref.entry_username
	vault_name.text = "(%s)" % VaultHandler.get_selected_vault_name()


func _on_delete_button_pressed() -> void:
	delete_request.emit(entry_ref)


func _on_cancel_button_pressed() -> void:
	canceled.emit()
