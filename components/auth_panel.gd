class_name AuthPanel
extends AnimatedPanel

signal access_granted(key: String)
signal first_vault_created(vault_name: String, vault_color: String, key: String)
signal new_vault_name_changed(vault_name: String)

@export var next_button: Button
@export var access_button: Button

@export var vault_name_input: LineEdit
@export var new_key_input: LineEdit
@export var verify_new_key_input: LineEdit
@export var auth_key_input: LineEdit

@export var new_vault_v_box: VBoxContainer
@export var new_key_v_box: VBoxContainer
@export var auth_key_v_box: VBoxContainer

@export var new_key_error_label: Label
@export var auth_key_error_label: Label

@export var main_label: Label
@export var sub_label: Label
@export var lock_bg: TextureRect
@export var colorscheme_label: Label
@export var color_list_container: ColorListContainer

var _is_first_vault_setup: bool = false
var _pending_vault_color: String = "#" + Chroma.accent_color.to_html()


func _ready() -> void:
	Chroma.set_accent_color(color_list_container.get_selected_color().to_html())
	Chroma.bind_color(lock_bg, "node/self_modulate", "")
	
	Chroma.bind_color(access_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(access_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(access_button, "stylebox/pressed", "bg_color", 0.9)
	
	Chroma.bind_color(next_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(next_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(next_button, "stylebox/pressed", "bg_color", 0.9)


func show_error(message: String, panel_type: String) -> void:
	match panel_type:
		"new_key":
			new_key_error_label.text = message
			new_key_error_label.show()
		"auth_key":
			auth_key_error_label.text = message
			auth_key_error_label.show()


func hide_error() -> void:
	new_key_error_label.hide()
	auth_key_error_label.hide()


func show_new_vault_panel() -> void:
	_is_first_vault_setup = true
	_pending_vault_color = "#" + Chroma.accent_color.to_html()
	new_vault_v_box.show()
	new_key_v_box.hide()
	auth_key_v_box.hide()
	hide_error()


func show_new_key_panel() -> void:
	new_vault_v_box.hide()
	new_key_v_box.show()
	auth_key_v_box.hide()
	hide_error()


func show_auth_panel() -> void:
	_is_first_vault_setup = false
	new_vault_v_box.hide()
	new_key_v_box.hide()
	auth_key_v_box.show()
	hide_error()


func validate_new_vault_name() -> bool:
	var vault_name: String = vault_name_input.text
	if vault_name.length() == 0:
		next_button.disabled = true
		return false
	
	var parsed: String = _parse_vault_name(vault_name)
	if parsed != vault_name:
		vault_name_input.text = parsed
		vault_name_input.caret_column = parsed.length()
	
	new_vault_name_changed.emit(parsed if parsed != "" else "Vault")
	next_button.disabled = false
	return true


func validate_new_key() -> bool:
	if new_key_input.text.length() <= 5:
		show_error("Please input a key greater than 5 characters.", "new_key")
		return false
	
	if new_key_input.text != verify_new_key_input.text:
		show_error("Keys do not match. Please try again.", "new_key")
		return false
	
	hide_error()
	return true


func validate_auth_key() -> bool:
	if auth_key_input.text.length() <= 5:
		show_error("Invalid key. Please try again.", "auth_key")
		return false
	
	hide_error()
	return true


func _on_next_button_pressed() -> void:
	if validate_new_vault_name():
		var next_tween: Tween = create_tween()
		next_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		next_tween.tween_property(new_vault_v_box, "modulate", Color.TRANSPARENT, 0.2)
		next_tween.tween_property(new_vault_v_box, "visible", false, 0)
		
		next_tween.tween_property(new_key_v_box, "modulate", Color.TRANSPARENT, 0)
		next_tween.tween_property(new_key_v_box, "visible", true, 0)
		next_tween.tween_property(new_key_v_box, "modulate", Color.WHITE, 0.2)


func _on_enter_button_pressed() -> void:
	if validate_new_key():
		if _is_first_vault_setup:
			first_vault_created.emit(
				vault_name_input.text,
				_pending_vault_color,
				new_key_input.text
			)
		else:
			access_granted.emit(new_key_input.text)


func _on_access_button_pressed() -> void:
	if validate_auth_key():
		access_granted.emit(auth_key_input.text)


func _on_vault_name_input_text_changed(_new_text: String) -> void:
	validate_new_vault_name()


func _on_new_key_input_text_changed(new_text: String) -> void:
	if new_text == verify_new_key_input.text and new_text.length() > 5:
		hide_error()


func _on_verify_new_key_input_text_changed(new_text: String) -> void:
	if new_text == new_key_input.text and new_text.length() > 5:
		hide_error()


func _on_new_key_input_text_submitted(_new_text: String) -> void:
	if verify_new_key_input.visible:
		verify_new_key_input.grab_focus(true)


func _on_verify_new_key_input_text_submitted(_new_text: String) -> void:
	_on_enter_button_pressed()


func _on_auth_key_input_text_submitted(_new_text: String) -> void:
	_on_access_button_pressed()


func _on_color_list_container_color_changed(color_name: String, color: Color) -> void:
	colorscheme_label.text = "Vault Color: " + color_name
	_pending_vault_color = "#" + color.to_html()
	Chroma.set_accent_color(color)


func _parse_vault_name(text: String) -> String:
	var result: String = ""
	var length: int = min(text.length(), 32)
	
	for i: int in length:
		var c: String = text[i]
		if c.is_valid_unicode_identifier():
			result += c
	
	return result
