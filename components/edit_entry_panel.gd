class_name EditEntryPanel
extends PanelContainer


signal edit_confirmed(ref: VaultEntry)
signal canceled

@export var name_edit: LineEdit
@export var user_edit: LineEdit
@export var password_edit: LineEdit
@export var save_button: Button

var entry_ref: VaultEntry


func _ready() -> void:
	Chroma.bind_color(save_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(save_button, "stylebox/hover", "bg_color", 1.1)
	Chroma.bind_color(save_button, "stylebox/pressed", "bg_color", 0.9)


func assign(entry: VaultEntry) -> void:
	entry_ref = entry
	name_edit.text = entry_ref.entry_name
	user_edit.text = entry_ref.entry_username
	password_edit.text = entry_ref.entry_password


func get_edited_name() -> String:
	return name_edit.text


func get_edited_username() -> String:
	return user_edit.text


func get_edited_password() -> String:
	return password_edit.text


func confirm() -> void:
	edit_confirmed.emit(entry_ref)


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
