class_name AuthPanel
extends AnimatedPanel

@warning_ignore("unused_signal")
signal access_granted(key: String)

@export var error_label: Label
@export var access_button: Button
@export var primary_key_input: LineEdit
@export var verify_key_input: LineEdit
@export var main_label: Label
@export var sub_label: Label
@export var lock_bg: TextureRect

var create_mode: bool = false


func _ready() -> void:
	Chroma.bind_color(lock_bg, "node/self_modulate", "")
	Chroma.bind_color(access_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(access_button, "stylebox/hover", "bg_color")
	Chroma.bind_color(access_button, "stylebox/pressed", "bg_color", 0.9)


func show_mismatch_error() -> void:
	error_label.text = "Keys do not match. Please try again."
	error_label.show()


func show_tiny_error() -> void:
	error_label.text = "Please input a key greater than 5 characters."
	error_label.show()


func show_invalid_error() -> void:
	error_label.text = "Invalid key. Please try again."
	error_label.show()


func hide_error() -> void:
	error_label.hide()


func show_create_screen() -> void:
	create_mode = true
	
	primary_key_input.show()
	verify_key_input.show()
	
	main_label.text = "Setup Keybox"
	sub_label.text = "Set a master key to start securing your data."
	
	primary_key_input.text = ""
	verify_key_input.text = ""
	
	primary_key_input.placeholder_text = "Create Master Key"
	verify_key_input.placeholder_text = "Verify Master Key"
	
	access_button.text = "Create Vault"
	
	hide_error()


func show_login_screen() -> void:
	create_mode = false
	
	primary_key_input.show()
	verify_key_input.hide()
	
	main_label.text = "Open Keybox"
	sub_label.text = "Enter your master key to access your data."
	
	primary_key_input.text = ""
	verify_key_input.text = ""
	
	primary_key_input.placeholder_text = "Master Key"
	
	access_button.text = "Access Vault"
	
	hide_error()


func check_auth() -> bool:
	if primary_key_input.text.length() <= 5:
		show_tiny_error()
		return false
	
	if create_mode:
		if primary_key_input.text != verify_key_input.text:
			show_mismatch_error()
			return false
	
	hide_error()
	return true


func _on_access_button_pressed() -> void:
	if check_auth():
		access_granted.emit(primary_key_input.text)


func _on_verify_key_input_text_changed(new_text: String) -> void:
	if not create_mode:
		return
	
	if new_text == primary_key_input.text and new_text.length() > 5:
		hide_error()


func _on_verify_key_input_text_submitted(_new_text: String) -> void:
	_on_access_button_pressed()


func _on_primary_key_input_text_submitted(_new_text: String) -> void:
	if not verify_key_input.visible:
		_on_access_button_pressed()
