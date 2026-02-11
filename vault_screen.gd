class_name VaultScreen
extends Control


const VAULT_ENTRY: PackedScene = preload("uid://dlvpgaeknnn70")
const VAULT_CHIP = preload("uid://ohekncr6mj6b")

@export var blur_container: Control
@export var auth_panel: AuthPanel
@export var new_entry_panel: NewEntry
@export var new_vault_panel: NewVaultPanel
@export var edit_entry_panel: EditEntryPanel
@export var edit_vault_panel: EditVaultPanel
@export var delete_confirmation: DeleteConfirmation
@export var flow_container: FlowContainer
@export var copied_toast: PanelContainer
@export var vault_selector_hbox: HBoxContainer
@export var create_vault_button: Button
@export var add_secret_button: Button
@export var new_profile_chip: VaultChip
@export var logo_bg: TextureRect
@export var panels: Array[Control]
@export var bg_blur: ColorRect
@export var zoom_tip: Label
@export var export_dialog: FileDialog
@export var import_dialog: FileDialog
@export var import_confirmation: PanelContainer


var panel_tween: Tween
var toast_tween: Tween
var vault_chips: Array[VaultChip] = []


func _ready() -> void:
	_setup_window()
	_setup_theme()
	_setup_signals()
	_initialize_vault()
	
	if OS.get_name() == "macOS":
		zoom_tip.text = zoom_tip.text.replace("CTRL", "CMD")
	if not Metadata.has_value(&"scale"):
		zoom_tip.show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_scale_in"):
		get_window().content_scale_factor += 0.25
		zoom_tip.hide()
		Metadata.set_value(&"scale", get_window().content_scale_factor)
	elif event.is_action_pressed("ui_scale_out"):
		get_window().content_scale_factor -= 0.25
		zoom_tip.hide()
		Metadata.set_value(&"scale", get_window().content_scale_factor)


func _setup_window() -> void:
	var window: Window = get_window()
	if not window: return
	
	var screen: int = window.get_current_screen()
	var screen_scale: float = DisplayServer.screen_get_scale(screen)
	
	window.content_scale_factor = screen_scale
	
	var screen_rect = DisplayServer.screen_get_usable_rect(screen)
	var window_size = window.get_size_with_decorations()
	var target_pos = screen_rect.position + (screen_rect.size - window_size) / 2
	
	window.position = target_pos


func _setup_theme() -> void:
	Chroma.bind_color(add_secret_button, "stylebox/normal", "bg_color", 1.0, 1.0)
	Chroma.bind_color(add_secret_button, "stylebox/pressed", "bg_color", 0.9, 1.0)
	Chroma.bind_color(add_secret_button, "stylebox/hover", "bg_color", 1.0, 1.0)
	Chroma.bind_color(logo_bg, "node/self_modulate", "", 1.0, 1.0)


func _setup_signals() -> void:
	if not auth_panel.first_vault_created.is_connected(_on_auth_panel_first_vault_created):
		auth_panel.first_vault_created.connect(_on_auth_panel_first_vault_created)
	if not auth_panel.access_granted.is_connected(_on_auth_panel_access_granted):
		auth_panel.access_granted.connect(_on_auth_panel_access_granted)
	if not auth_panel.new_vault_name_changed.is_connected(_on_auth_panel_new_vault_name_changed):
		auth_panel.new_vault_name_changed.connect(_on_auth_panel_new_vault_name_changed)
	if not new_entry_panel.created.is_connected(_on_new_entry_panel_created):
		new_entry_panel.created.connect(_on_new_entry_panel_created)
	if not new_entry_panel.canceled.is_connected(_on_new_entry_panel_canceled):
		new_entry_panel.canceled.connect(_on_new_entry_panel_canceled)
	if not new_vault_panel.created.is_connected(_on_new_vault_panel_created):
		new_vault_panel.created.connect(_on_new_vault_panel_created)
	if not new_vault_panel.canceled.is_connected(_on_new_vault_panel_canceled):
		new_vault_panel.canceled.connect(_on_new_vault_panel_canceled)
	if not edit_entry_panel.edit_confirmed.is_connected(_on_edit_entry_panel_edit_confirmed):
		edit_entry_panel.edit_confirmed.connect(_on_edit_entry_panel_edit_confirmed)
	if not edit_entry_panel.canceled.is_connected(_on_edit_entry_panel_canceled):
		edit_entry_panel.canceled.connect(_on_edit_entry_panel_canceled)
	if not edit_entry_panel.entry_moved_to_vault.is_connected(_on_entry_moved_to_vault):
		edit_entry_panel.entry_moved_to_vault.connect(_on_entry_moved_to_vault)


func _initialize_vault() -> void:
	if VaultHandler.has_vault_file():
		_initialize_existing_vault()
	else:
		_initialize_new_vault()
	
	await get_tree().create_timer(0.1).timeout
	show_panel(auth_panel)


func _initialize_existing_vault() -> void:
	new_profile_chip.queue_free()
	
	var stored_count: int = VaultHandler.get_selected_vault_key_count()
	
	for i: int in stored_count:
		var vault_entry: VaultEntry = _create_vault_entry()
		vault_entry.show_obfucsated()
		flow_container.add_child(vault_entry)
	
	auth_panel.show_auth_panel()


func _initialize_new_vault() -> void:
	new_profile_chip.use_chroma = true
	new_profile_chip.set_pressed_no_signal(true)
	auth_panel.show_new_vault_panel()


func show_panel(panel: Control) -> void:
	_hide_all_panels()
	
	blur_container.modulate = Color.TRANSPARENT
	panel.scale = Vector2(0.8, 0.8)
	panel.show()
	blur_container.show()
	
	panel_tween = create_tween()
	panel_tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(blur_container, "modulate", Color.WHITE, 0.3)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	panel_tween.tween_property(bg_blur.material, "shader_parameter/blur_amount", 2.0, 0.3)


func hide_panel(panel: Control) -> void:
	panel_tween = create_tween()
	panel_tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	panel_tween.tween_property(blur_container, "modulate", Color.TRANSPARENT, 0.3)
	panel_tween.tween_property(bg_blur.material, "shader_parameter/blur_amount", 0.0, 0.3)
	panel_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.3)
	panel_tween.finished.connect(func() -> void:
		blur_container.hide()
	, CONNECT_ONE_SHOT)


func _hide_all_panels() -> void:
	for c: Control in panels:
		if c:
			c.hide()


func _create_vault_entry() -> VaultEntry:
	var vault_entry: VaultEntry = VAULT_ENTRY.instantiate()
	vault_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vault_entry.username_copied.connect(_on_username_copied)
	vault_entry.password_copied.connect(_on_password_copied)
	vault_entry.delete_request.connect(_on_delete_request)
	vault_entry.edit_request.connect(_on_edit_request)
	return vault_entry


func _load_entries() -> void:
	for c: Node in flow_container.get_children():
		c.queue_free()
	
	var entries: Array = VaultHandler.fetch_entries()
	
	for entry: Dictionary in entries:
		var v_entry: VaultEntry = _create_vault_entry()
		v_entry.entry_name = entry["name"]
		v_entry.entry_username = entry["user"]
		v_entry.entry_password = entry["password"]
		v_entry.show_normal()
		flow_container.add_child(v_entry)


func _populate_vault_chips() -> void:
	for chip: VaultChip in vault_chips:
		chip.free()
	vault_chips = []
	
	
	for i: int in VaultHandler.get_vault_count():
		var vault_data: Dictionary = VaultHandler.VAULTS_DATA[i]
		var chip: VaultChip = VAULT_CHIP.instantiate()
		chip.vault_index = i
		chip.vault_name = vault_data["name"]
		chip.vault_color = vault_data["color"]
		chip.key_count = vault_data["key_count"]
		chip.is_selected = i == VaultHandler.SELECTED_VAULT_INDEX
		chip.vault_toggled.connect(_on_vault_chip_toggled)
		vault_selector_hbox.add_child(chip)
		vault_selector_hbox.move_child(chip, vault_selector_hbox.get_child_count() - 2)
		vault_chips.append(chip)
		
		if chip.is_selected:
			chip.use_chroma = true
		else:
			chip.use_chroma = false


func _update_selected_chip_count() -> void:
	for chip: VaultChip in vault_chips:
		if chip.vault_index == VaultHandler.SELECTED_VAULT_INDEX:
			chip.key_count = VaultHandler.get_selected_vault_key_count()
			break


func _apply_selected_vault_color() -> void:
	Chroma.set_accent_color(Color(VaultHandler.get_selected_vault_color()))


func _show_copied_toast() -> void:
	if toast_tween != null:
		return
	
	toast_tween = create_tween().set_ease(Tween.EASE_OUT)
	copied_toast.modulate = Color.TRANSPARENT
	copied_toast.show()
	toast_tween.tween_property(copied_toast, "modulate", Color.WHITE, 0.2)
	
	await get_tree().create_timer(2).timeout
	var hide_tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
	hide_tween.tween_property(copied_toast, "modulate", Color.TRANSPARENT, 0.2)
	toast_tween.kill()
	toast_tween = null


func _on_auth_panel_access_granted(key: String) -> void:
	if not VaultHandler.has_vault_file():
		return
	
	if not VaultHandler.unlock_master_vault(key):
		auth_panel.show_error("Invalid key. Please try again.", "auth_key")
		return
	
	if VaultHandler.get_vault_count() == 0:
		auth_panel.show_new_vault_panel()
		show_panel(auth_panel)
	else:
		_apply_selected_vault_color()
		_populate_vault_chips()
		_load_entries()
		hide_panel(auth_panel)


func _on_auth_panel_first_vault_created(vault_name: String, vault_color: String, key: String) -> void:
	VaultHandler.create_master_vault(key)
	VaultHandler.create_vault(vault_name, vault_color)
	VaultHandler.select_vault(0)
	
	if new_profile_chip and is_instance_valid(new_profile_chip):
		new_profile_chip.queue_free()
	
	_apply_selected_vault_color()
	_populate_vault_chips()
	_load_entries()
	hide_panel(auth_panel)


func _on_auth_panel_new_vault_name_changed(vault_name: String) -> void:
	if new_profile_chip and is_instance_valid(new_profile_chip):
		new_profile_chip.vault_name = vault_name if not vault_name.is_empty() else "Vault"
		new_profile_chip.key_count = 0


func _on_vault_chip_toggled(vault_index: int) -> void:
	if vault_index == VaultHandler.SELECTED_VAULT_INDEX:
		return
	
	if VaultHandler.select_vault(vault_index):
		for chip: VaultChip in vault_chips:
			if chip.is_selected:
				chip.use_chroma = false
			chip.is_selected = chip.vault_index == vault_index
		
		_apply_selected_vault_color()
		
		for chip: VaultChip in vault_chips:
			if chip.is_selected:
				chip.use_chroma = true
				break
		
		_load_entries()


func _on_username_copied() -> void:
	_show_copied_toast()


func _on_password_copied() -> void:
	_show_copied_toast()


func _on_delete_request(ref: VaultEntry) -> void:
	delete_confirmation.assign(ref)
	show_panel(delete_confirmation)


func _on_edit_request(ref: VaultEntry) -> void:
	edit_entry_panel.assign(ref)
	show_panel(edit_entry_panel)


func _on_new_entry_panel_created(name_: String, user: String, password: String) -> void:
	var new_entry: VaultEntry = _create_vault_entry()
	new_entry.entry_name = name_
	new_entry.entry_username = user
	new_entry.entry_password = password
	new_entry.show_normal()
	flow_container.add_child(new_entry)
	
	var data: Array = VaultHandler.fetch_entries()
	data.append({"name": name_, "user": user, "password": password})
	VaultHandler.write_entries(data)
	_update_selected_chip_count()
	hide_panel(new_entry_panel)


func _on_new_entry_panel_canceled() -> void:
	hide_panel(new_entry_panel)


func _on_edit_entry_panel_edit_confirmed(ref: VaultEntry) -> void:
	var entries: Array = VaultHandler.fetch_entries()
	var updated_name: String = edit_entry_panel.get_edited_name()
	var updated_user: String = edit_entry_panel.get_edited_username()
	var updated_password: String = edit_entry_panel.get_edited_password()
	
	VaultHandler.write_entries(entries)
	
	ref.entry_name = updated_name
	ref.entry_username = updated_user
	ref.entry_password = updated_password
	ref.update_display()
	
	hide_panel(edit_entry_panel)


func _on_entry_moved_to_vault(ref: VaultEntry, new_vault_index: int) -> void:
	ref.queue_free()
	
	var entries: Array = VaultHandler.fetch_entries()
	var filtered_entries: Array = []
	for e: Variant in entries:
		var entry_dict: Dictionary = e as Dictionary
		var matches: bool = (
			entry_dict["name"] == ref.entry_name and
			entry_dict["user"] == ref.entry_username and
			entry_dict["password"] == ref.entry_password
		)
		if not matches:
			filtered_entries.append(e)
	
	VaultHandler.write_entries(filtered_entries)
	
	_update_selected_chip_count()
	
	for chip: VaultChip in vault_chips:
		if chip.vault_index == new_vault_index:
			chip.key_count = VaultHandler.get_vault_key_count(new_vault_index)
			break
	
	hide_panel(edit_entry_panel)


func _on_edit_entry_panel_canceled() -> void:
	hide_panel(edit_entry_panel)


func _on_new_vault_panel_created(vault_name: String, vault_color: String) -> void:
	VaultHandler.create_vault(vault_name, vault_color)
	VaultHandler.select_vault(VaultHandler.get_vault_count() - 1)
	_apply_selected_vault_color()
	_populate_vault_chips()
	_load_entries()
	hide_panel(new_vault_panel)


func _on_new_vault_panel_canceled() -> void:
	hide_panel(new_vault_panel)


func _on_add_secret_button_pressed() -> void:
	new_entry_panel.clear_inputs()
	show_panel(new_entry_panel)


func _on_create_vault_button_pressed() -> void:
	if new_vault_panel:
		show_panel(new_vault_panel)


func _on_search_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		for entry: Node in flow_container.get_children():
			entry.show()
		return
	
	var search: String = new_text.to_lower()
	
	for entry: Node in flow_container.get_children():
		if entry is VaultEntry:
			var vault_entry: VaultEntry = entry as VaultEntry
			var name_match: bool = vault_entry.entry_name.to_lower().findn(search) != -1
			var user_match: bool = vault_entry.entry_username.to_lower().findn(search) != -1
			entry.visible = name_match or user_match


func _on_delete_confirmation_delete_request(ref: VaultEntry) -> void:
	ref.queue_free()
	
	var entries: Array = VaultHandler.fetch_entries()
	var filtered_entries: Array = []
	for e: Variant in entries:
		var entry_dict: Dictionary = e as Dictionary
		var matches: bool = (
			entry_dict["name"] == ref.entry_name and
			entry_dict["user"] == ref.entry_username and
			entry_dict["password"] == ref.entry_password
		)
		if not matches:
			filtered_entries.append(e)
	
	VaultHandler.write_entries(filtered_entries)
	_update_selected_chip_count()
	hide_panel(delete_confirmation)


func _on_delete_confirmation_canceled() -> void:
	hide_panel(delete_confirmation)


func _on_edit_vault_button_pressed() -> void:
	edit_vault_panel.assign()
	show_panel(edit_vault_panel)


func _on_edit_vault_panel_canceled() -> void:
	hide_panel(edit_vault_panel)


func _on_edit_vault_panel_save_request(v_name: String, v_color: Color) -> void:
	VaultHandler.update_selected_vault(v_name, "#" + v_color.to_html(false))
	_apply_selected_vault_color()
	_populate_vault_chips()
	hide_panel(edit_vault_panel)


func _on_edit_vault_panel_delete_request() -> void:
	var old_index: int = VaultHandler.SELECTED_VAULT_INDEX
	var vault_count: int = VaultHandler.get_vault_count()
	
	if vault_count == 0:
		return
	
	var next_index: int = -1
	
	if old_index > 0:
		next_index = old_index - 1
	elif old_index < vault_count - 1:
		next_index = old_index + 1
	
	if not VaultHandler.delete_selected_vault():
		return
	
	for c: Node in flow_container.get_children():
		c.queue_free()
	
	if VaultHandler.get_vault_count() > 0 and next_index != -1:
		VaultHandler.select_vault(min(next_index, VaultHandler.get_vault_count() - 1))
		_apply_selected_vault_color()
		_populate_vault_chips()
		_load_entries()
	else:
		vault_chips.clear()
		Chroma.set_accent_color(Color.WHITE)
		_populate_vault_chips()
	
	hide_panel(edit_vault_panel)


func _on_export_button_pressed() -> void:
	export_dialog.show()


func _on_export_dialog_file_selected(path: String) -> void:
	var buf: PackedByteArray = FileAccess.get_file_as_bytes(VaultHandler.DATA_PATH)
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(buf)


func _on_import_button_pressed() -> void:
	import_dialog.show()


func _on_import_dialog_file_selected(path: String) -> void:
	import_confirmation.assign(path)
	show_panel(import_confirmation)


func _on_import_confirmation_canceled() -> void:
	hide_panel(import_confirmation)


func _on_import_confirmation_merge_request() -> void:
	VaultHandler._load_vaults_data() 
	_apply_selected_vault_color()
	_populate_vault_chips()
	_load_entries()
	hide_panel(import_confirmation)


func _on_import_confirmation_replace_request(file_path: String, key: String) -> void:
	var external_data: Dictionary = VaultHandler.unlock_vault(file_path, key)
	
	if external_data.is_empty():
		return
	
	if VaultHandler.replace_vault(external_data):
		_apply_selected_vault_color()
		_populate_vault_chips()
		_load_entries()
	
	hide_panel(import_confirmation)
