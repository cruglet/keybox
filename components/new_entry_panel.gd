class_name NewEntry
extends AnimatedPanel

signal canceled
signal created(name: String, email: String, password: String)

@export var escape_cancel: bool = false

@export var name_edit: LineEdit
@export var user_edit: LineEdit
@export var password_edit: LineEdit
@export var error_label: Label
@export var save_button: Button


func _ready() -> void:
	Chroma.bind_color(save_button, "stylebox/normal", "bg_color")
	Chroma.bind_color(save_button, "stylebox/hover", "bg_color")
	Chroma.bind_color(save_button, "stylebox/pressed", "bg_color")


func clear_inputs() -> void:
	name_edit.text = ""
	user_edit.text = ""
	password_edit.text = ""
	error_label.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and escape_cancel and visible:
			canceled.emit()


func _on_generate_button_pressed() -> void:
	password_edit.text = _generate_password(16)


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
	var name_: String = name_edit.text.strip_edges()
	var user: String = user_edit.text.strip_edges()
	var password: String = password_edit.text.strip_edges()
	
	if name_ == "":
		_show_error("Name cannot be empty")
		return
	
	if user == "":
		_show_error("Username/Email cannot be empty")
		return
	
	if password == "":
		_show_error("Password cannot be empty")
		return
	
	created.emit(name_, user, password)


func _show_error(message: String) -> void:
	error_label.show()
	error_label.text = message
