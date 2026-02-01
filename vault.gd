class_name Vault
extends Control

const VAULT_ENTRY: PackedScene = preload("uid://dlvpgaeknnn70")

static var KEY: String
static var DERIVED_KEY: PackedByteArray
static var KEY_AMOUNT: int = 0

@export var blur_container: Control
@export var auth_panel: AuthPanel
@export var new_entry_panel: NewEntry
@export var flow_container: FlowContainer
@export var copied_toast: PanelContainer
@export var profile_button: Button
@export var add_secret_button: Button
@export var logo_bg: TextureRect

@onready var panels = [auth_panel, new_entry_panel]

var panel_tween: Tween
var toast_tweeen: Tween
var new_entry_tween: Tween


func _ready() -> void:
	get_window().content_scale_factor = DisplayServer.screen_get_scale()
	_theme_bindings()
	
	if FileAccess.file_exists("user://metadata.json"):
		var str_metadata: String = FileAccess.open("user://metadata.json", FileAccess.READ).get_as_text()
		var metadata: Dictionary = JSON.parse_string(str_metadata)
		var stored_keys_amount: int = metadata.get("stored_keys", 0)
		for i: int in stored_keys_amount:
			var vault_entry: VaultEntry = VAULT_ENTRY.instantiate()
			vault_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vault_entry.show_obfucsated()
			vault_entry.password_copied.connect(_on_password_copied)
			vault_entry.delete_request.connect(_on_delete_request)
			flow_container.add_child(vault_entry)
		KEY_AMOUNT = stored_keys_amount
	
	if FileAccess.file_exists("user://vault.kbox"):
		auth_panel.create_mode = false
		auth_panel.show_login_screen()
	else:
		auth_panel.create_mode = true
		auth_panel.show_create_screen()
	
	await get_tree().create_timer(0.1).timeout
	show_panel(auth_panel)
	

func _theme_bindings() -> void:
	Chroma.bind_color(profile_button, "color/icon_normal_color", "", 1.0, 1.0)
	Chroma.bind_color(profile_button, "color/icon_hover_color", "", 1.0, 1.0)
	Chroma.bind_color(profile_button, "color/icon_pressed_color", "", 1.0, 1.0)
	Chroma.bind_color(add_secret_button, "stylebox/normal", "bg_color", 1.0, 1.0)
	Chroma.bind_color(add_secret_button, "stylebox/pressed", "bg_color", 0.9, 1.0)
	Chroma.bind_color(add_secret_button, "stylebox/hover", "bg_color", 1.0, 1.0)
	Chroma.bind_color(profile_button, "stylebox/hover", "border_color", 1.0, 1.0)
	Chroma.bind_color(logo_bg, "node/self_modulate", "", 1.0, 1.0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_L:
			Chroma.set_accent_color(Color.INDIAN_RED)


func show_panel(panel: Control) -> void:
	for c: Control in panels:
		if c: c.hide()
	
	blur_container.modulate = Color.TRANSPARENT
	panel.scale = Vector2(0.8, 0.8)
	panel.show()
	blur_container.show()
	
	panel_tween = create_tween()
	panel_tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(blur_container, "modulate", Color.WHITE, 0.3)
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3)



func hide_panel(panel: Control) -> void:
	panel_tween = create_tween()
	panel_tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(blur_container, "modulate", Color.TRANSPARENT, 0.3)
	panel_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.3)
	panel_tween.finished.connect(func() -> void:
		blur_container.hide()
	, CONNECT_ONE_SHOT)


func fetch_vault() -> Array:
	if not FileAccess.file_exists("user://vault.kbox"):
		return []
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var salt: PackedByteArray = file.get_buffer(Encryption.SALT_SIZE)
	var verifier: PackedByteArray = file.get_buffer(Encryption.KEY_SIZE)
	var encrypted_vault: PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
	file.close()
	
	if not Encryption.verify_master_key(KEY, salt, verifier):
		push_error("Invalid key, cannot fetch vault")
		return []
	
	var derived_key_local: PackedByteArray = Encryption.derive_key(KEY, salt)
	var vault_data: PackedByteArray = Encryption.decrypt_data(encrypted_vault, derived_key_local)
	
	if vault_data.size() == 0:
		return []
	
	return bytes_to_var_with_objects(vault_data)


func write_to_vault(key: String, data: Variant, overwrite: bool = true) -> void:
	var new_data: PackedByteArray = var_to_bytes_with_objects(data)
	var vault_exists: bool = FileAccess.file_exists("user://vault.kbox")
	var salt: PackedByteArray
	var verifier: PackedByteArray
	var vault_data: PackedByteArray = PackedByteArray()
	
	if vault_exists:
		var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
		salt = file.get_buffer(Encryption.SALT_SIZE)
		verifier = file.get_buffer(Encryption.KEY_SIZE)
		var encrypted_vault_local: PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
		file.close()
		
		if not Encryption.verify_master_key(key, salt, verifier):
			push_error("Invalid key, cannot write to vault")
			return
		
		var derived_key_local: PackedByteArray = Encryption.derive_key(key, salt)
		vault_data = Encryption.decrypt_data(encrypted_vault_local, derived_key_local)
	else:
		salt = Encryption.generate_salt()
		verifier = Encryption.create_verifier(key, salt)
	
	if overwrite:
		vault_data = new_data
	else:
		vault_data.append_array(new_data)
	
	var derived_key: PackedByteArray = Encryption.derive_key(key, salt)
	var encrypted_vault: PackedByteArray = Encryption.encrypt_data(vault_data, derived_key)
	_write_vault_file(salt, verifier, encrypted_vault)
	_update_metadata(len(bytes_to_var_with_objects(vault_data)))


func _on_auth_panel_access_granted(key: String) -> void:
	Vault.KEY = key
	
	if auth_panel.create_mode:
		var salt: PackedByteArray = Encryption.generate_salt()
		Vault.DERIVED_KEY = Encryption.derive_key(key, salt)
		var verifier: PackedByteArray = Encryption.hash_key(Vault.DERIVED_KEY)
		var derived_key: PackedByteArray = Encryption.derive_key(key, salt)
		
		var vault_data: PackedByteArray = PackedByteArray()
		var encrypted_vault: PackedByteArray = Encryption.encrypt_data(vault_data, derived_key)
		
		_write_vault_file(salt, verifier, encrypted_vault)
		_update_metadata(0)
		hide_panel(auth_panel)
	else:
		_unlock_vault(key)


func _write_vault_file(salt: PackedByteArray, verifier: PackedByteArray, encrypted_vault: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.WRITE)
	file.store_buffer(salt)
	file.store_buffer(verifier)
	file.store_buffer(encrypted_vault)
	file.close()


func _unlock_vault(key: String) -> void:
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var salt: PackedByteArray = file.get_buffer(Encryption.SALT_SIZE)
	var verifier: PackedByteArray = file.get_buffer(Encryption.KEY_SIZE)
	var encrypted_vault: PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
	file.close()
	
	if not Encryption.verify_master_key(key, salt, verifier):
		auth_panel.show_invalid_error()
		return
	
	var derived_key: PackedByteArray = Encryption.derive_key(key, salt)
	var vault_data: PackedByteArray = Encryption.decrypt_data(encrypted_vault, derived_key)
	
	hide_panel(auth_panel)
	
	var entries: Array = bytes_to_var_with_objects(vault_data)
	var cleaned_entries: Array = []
	
	for entry: Dictionary in entries:
		if entry.has("name") and entry.has("user") and entry.has("password"):
			cleaned_entries.append(entry)
	
	for c: Node in flow_container.get_children(): c.queue_free()
	for entry: Dictionary in cleaned_entries:
		var v_entry: VaultEntry = VAULT_ENTRY.instantiate()
		v_entry.entry_name = entry.get("name")
		v_entry.entry_username = entry.get("user")
		v_entry.entry_password = entry.get("password")
		v_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_entry.password_copied.connect(_on_password_copied)
		v_entry.delete_request.connect(_on_delete_request)
		v_entry.show_normal()
		flow_container.add_child(v_entry)
	
	KEY_AMOUNT = cleaned_entries.size()
	_update_metadata(KEY_AMOUNT)


func _update_metadata(stored_keys: int) -> void:
	var metadata: Dictionary = {"stored_keys": stored_keys}
	var file: FileAccess = FileAccess.open("user://metadata.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata))
	file.close()


func _on_password_copied() -> void:
	if toast_tweeen != null:
		return
	
	toast_tweeen = create_tween().set_ease(Tween.EASE_OUT)
	
	copied_toast.modulate = Color.TRANSPARENT
	copied_toast.show()
	
	toast_tweeen.tween_property(copied_toast, "modulate", Color.WHITE, 0.2)
	
	await get_tree().create_timer(2).timeout
	var hide_tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	hide_tween.tween_property(copied_toast, "modulate", Color.TRANSPARENT, 0.2)
	toast_tweeen.kill()
	toast_tweeen = null


func _on_delete_request(ref: VaultEntry) -> void:
	# TODO prompt for confirmation
	ref.queue_free()
	var vault_data: Array = fetch_vault()
	vault_data = vault_data.filter(func(e):
		return not (e.get("name") == ref.entry_name and e.get("user") == ref.entry_username and e.get("password") == ref.entry_password)
	)
	write_to_vault(Vault.KEY, vault_data, true)
	KEY_AMOUNT = vault_data.size()
	_update_metadata(KEY_AMOUNT)



func _on_new_entry_panel_created(name_: String, user: String, password: String) -> void:
	var new_entry: VaultEntry = VAULT_ENTRY.instantiate()
	new_entry.entry_name = name_
	new_entry.entry_username = user
	new_entry.entry_password = password
	new_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_entry.password_copied.connect(_on_password_copied)
	new_entry.delete_request.connect(_on_delete_request)
	new_entry.show_normal()
	flow_container.add_child(new_entry)
	
	var data: Array = fetch_vault() 
	data.append({"name": name_, "user": user, "password": password})
	KEY_AMOUNT += 1
	
	write_to_vault(Vault.KEY, data)
	hide_panel(new_entry_panel)


func _on_new_entry_panel_canceled() -> void:
	hide_panel(new_entry_panel)


func _on_add_secret_button_pressed() -> void:
	show_panel(new_entry_panel)


func _on_search_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		for entry in flow_container.get_children():
			entry.show()
		return
	
	var search: String = new_text.to_lower()
	
	for entry in flow_container.get_children():
		if entry is VaultEntry:
			var name_match: bool = entry.entry_name.to_lower().findn(search) != -1
			var user_match: bool = entry.entry_username.to_lower().findn(search) != -1
			
			entry.visible = name_match or user_match
