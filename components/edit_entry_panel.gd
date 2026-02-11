class_name EditEntryPanel
extends PanelContainer

signal edit_confirmed(ref: VaultEntry)
signal entry_moved_to_vault(ref: VaultEntry, new_vault_index: int)
signal canceled

@export var name_edit: LineEdit
@export var user_edit: LineEdit
@export var password_edit: LineEdit
@export var save_button: Button
@export var option_button: OptionButton

var entry_ref: VaultEntry
var original_vault_index: int = 0


func _ready() -> void:
	option_button.get_popup().prefer_native_menu = true
	Chroma.bind_color(save_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(save_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(save_button, "stylebox/pressed", "bg_color", 0.9)


func assign(entry: VaultEntry) -> void:
	entry_ref = entry
	name_edit.text = entry_ref.entry_name
	user_edit.text = entry_ref.entry_username
	password_edit.text = entry_ref.entry_password
	
	option_button.clear()
	var vault_names: Array[String] = VaultHandler.get_vault_names()
	for i: int in vault_names.size():
		option_button.add_item(vault_names[i])
		if vault_names[i] == VaultHandler.get_selected_vault_name():
			option_button.selected = i
			original_vault_index = i
	
	_on_option_button_item_selected(option_button.selected)


func get_edited_name() -> String:
	return name_edit.text


func get_edited_username() -> String:
	return user_edit.text


func get_edited_password() -> String:
	return password_edit.text


func confirm() -> void:
	var entry_data: Dictionary = {
		"name": name_edit.text,
		"user": user_edit.text,
		"password": password_edit.text
	}
	
	var new_vault_index: int = option_button.selected
	
	VaultHandler.move_entry_to_vault(entry_data, original_vault_index, new_vault_index)
	
	entry_ref.entry_name = entry_data["name"]
	entry_ref.entry_username = entry_data["user"]
	entry_ref.entry_password = entry_data["password"]
	
	edit_confirmed.emit(entry_ref)
	
	if new_vault_index != original_vault_index:
		entry_moved_to_vault.emit(entry_ref, new_vault_index)


func _generate_password(length: int = 16) -> String:
	if length < 6:
		length = 6
	
	var upper: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var lower: String = "abcdefghijklmnopqrstuvwxyz"
	var letters: String = upper + lower
	var digits: String = "0123456789"
	var symbols: String = "!@#$%&*?"
	
	var all_chars: String = letters + digits + symbols
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var password: String = ""
	
	password += letters[rng.randi_range(0, letters.length() - 1)]
	
	var letter_count: int = 1
	var digit_count: int = 0
	
	for i: int in range(1, length):
		var char_: String = ""
		var t: int = -1
		
		while true:
			char_ = all_chars[rng.randi_range(0, all_chars.length() - 1)]
			
			if letters.find(char_) != -1:
				t = 0
			elif digits.find(char_) != -1:
				t = 1
			else:
				t = 2
			
			if t == 0 and letter_count >= 2:
				continue
			if t == 1 and digit_count >= 2:
				continue
			break
		
		password += char_
		
		if t == 0:
			letter_count += 1
			digit_count = 0
		elif t == 1:
			digit_count += 1
			letter_count = 0
		else:
			letter_count = 0
			digit_count = 0
	
	return password


func _on_cancel_button_pressed() -> void:
	canceled.emit()


func _on_save_button_pressed() -> void:
	confirm()


func _on_password_edit_focus_entered() -> void:
	password_edit.secret = false


func _on_password_edit_focus_exited() -> void:
	password_edit.secret = true


func _on_generate_button_pressed() -> void:
	password_edit.secret = false
	password_edit.text = _generate_password()


func _on_option_button_item_selected(index: int) -> void:
	var c: Color = VaultHandler.get_vault_color(option_button.get_item_text(index))
	
	var normal_style: StyleBoxFlat = save_button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	normal_style.bg_color = c
	save_button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style: StyleBoxFlat = save_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	hover_style.bg_color = Chroma.modify_color(c, 1.1)
	save_button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style: StyleBoxFlat = save_button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	pressed_style.bg_color = Chroma.modify_color(c, 0.9)
	save_button.add_theme_stylebox_override("pressed", pressed_style)
