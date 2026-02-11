class_name VaultHandler
extends Node

const MASTER_SALT_SIZE: int = 16
const MASTER_KEY_SIZE: int = 32

static var MASTER_KEY: String
static var MASTER_DERIVED_KEY: PackedByteArray
static var VAULTS_DATA: Array[Dictionary]
static var SELECTED_VAULT_INDEX: int = 0
const DATA_PATH: String = "user://vault.kbox"


class VaultData:
	var name: String
	var color: String
	var key_count: int
	var encrypted_data: PackedByteArray
	
	func _init(p_name: String = "", p_color: String = "#ffffff", p_key_count: int = 0, p_encrypted_data: PackedByteArray = PackedByteArray()) -> void:
		name = p_name
		color = p_color
		key_count = p_key_count
		encrypted_data = p_encrypted_data
	
	func to_dict() -> Dictionary:
		return {
			"name": name,
			"color": color,
			"key_count": key_count,
			"encrypted_data": encrypted_data
		}
	
	static func from_dict(data: Dictionary) -> VaultData:
		var vault: VaultData = VaultData.new()
		vault.name = data.get("name", "")
		vault.color = data.get("color", "#ffffff")
		vault.key_count = data.get("key_count", 0)
		vault.encrypted_data = data.get("encrypted_data", PackedByteArray())
		return vault


static func has_vault_file() -> bool:
	return FileAccess.file_exists("user://vault.kbox")


static func create_master_vault(master_key: String) -> void:
	MASTER_KEY = master_key
	
	var master_salt: PackedByteArray = Encryption.generate_salt()
	MASTER_DERIVED_KEY = Encryption.derive_key(master_key, master_salt)
	var master_verifier: PackedByteArray = Encryption.hash_key(MASTER_DERIVED_KEY)
	
	VAULTS_DATA = []
	SELECTED_VAULT_INDEX = 0
	
	_write_vault_file(master_salt, master_verifier)


static func unlock_vault(file_path: String, key: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	
	var derived_key: PackedByteArray = Encryption.derive_key(key, master_salt)
	var test_verifier: PackedByteArray = Encryption.hash_key(derived_key)
	
	if test_verifier.size() != master_verifier.size():
		file.close()
		return {}
	
	for i: int in test_verifier.size():
		if test_verifier[i] != master_verifier[i]:
			file.close()
			return {}
	
	var encrypted_container: PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
	file.close()
	
	if encrypted_container.is_empty():
		return {
			"vaults": [],
			"selected_vault": 0
		}
	
	var decrypted: PackedByteArray = Encryption.decrypt_data(encrypted_container, derived_key)
	if decrypted.is_empty():
		return {}
	
	var container: Dictionary = bytes_to_var_with_objects(decrypted)
	
	return {
		"vaults": container.get("vaults", []),
		"selected_vault": container.get("selected_vault", 0),
		"derived_key": derived_key
	}


static func unlock_master_vault(master_key: String) -> bool:
	if not has_vault_file():
		return false
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	if file == null:
		return false
	
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	var test_derived_key: PackedByteArray = Encryption.derive_key(master_key, master_salt)
	var test_verifier: PackedByteArray = Encryption.hash_key(test_derived_key)
	
	if test_verifier.size() != master_verifier.size():
		return false
	
	for i: int in test_verifier.size():
		if test_verifier[i] != master_verifier[i]:
			return false
	
	MASTER_KEY = master_key
	MASTER_DERIVED_KEY = test_derived_key
	_load_vaults_data()
	return true


static func create_vault(vault_name: String, color: String = "#ffffff") -> void:
	var encrypted: PackedByteArray = Encryption.encrypt_data(PackedByteArray(), MASTER_DERIVED_KEY)
	
	var vault: VaultData = VaultData.new(vault_name, color, 0, encrypted)
	VAULTS_DATA.append(vault.to_dict())
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)


static func select_vault(index: int) -> bool:
	if index < 0 or index >= VAULTS_DATA.size():
		return false
	
	SELECTED_VAULT_INDEX = index
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)
	return true


static func update_selected_vault(vault_name: String, vault_color: String) -> void:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return
	
	VAULTS_DATA[SELECTED_VAULT_INDEX]["name"] = vault_name
	VAULTS_DATA[SELECTED_VAULT_INDEX]["color"] = vault_color
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)


static func get_vault_names() -> Array[String]:
	var names: Array[String] = []
	for vault_dict: Dictionary in VAULTS_DATA:
		names.append(vault_dict.get("name", ""))
	return names


static func get_vault_count() -> int:
	return VAULTS_DATA.size()


static func get_selected_vault_name() -> String:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return ""
	return VAULTS_DATA[SELECTED_VAULT_INDEX].get("name", "")


static func get_selected_vault_color() -> String:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return "#ffffff"
	return VAULTS_DATA[SELECTED_VAULT_INDEX].get("color", "#ffffff")


static func get_selected_vault_key_count() -> int:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return 0
	return VAULTS_DATA[SELECTED_VAULT_INDEX].get("key_count", 0)


static func get_vault_color(p_vault_name: String) -> Color:
	for vault_dict: Dictionary in VAULTS_DATA:
		if vault_dict.get("name", "") == p_vault_name:
			var color_hex: String = vault_dict.get("color", "#ffffff")
			return Color.from_string(color_hex, Color.WHITE)
	
	return Color.WHITE


static func fetch_entries() -> Array:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return []
	
	var vault_dict: Dictionary = VAULTS_DATA[SELECTED_VAULT_INDEX]
	var vault: VaultData = VaultData.from_dict(vault_dict)
	
	var decrypted: PackedByteArray = Encryption.decrypt_data(vault.encrypted_data, MASTER_DERIVED_KEY)
	if decrypted.is_empty():
		return []
	
	var entries: Array = bytes_to_var_with_objects(decrypted)
	return entries.filter(func(e: Variant) -> bool:
		return e is Dictionary and e.has("name") and e.has("user") and e.has("password")
	)


static func write_entries(entries: Array) -> void:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return
	
	var data: PackedByteArray = var_to_bytes_with_objects(entries)
	var encrypted: PackedByteArray = Encryption.encrypt_data(data, MASTER_DERIVED_KEY)
	
	VAULTS_DATA[SELECTED_VAULT_INDEX]["encrypted_data"] = encrypted
	VAULTS_DATA[SELECTED_VAULT_INDEX]["key_count"] = entries.size()
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)


static func delete_selected_vault() -> bool:
	if SELECTED_VAULT_INDEX < 0 or SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		return false
	
	VAULTS_DATA.remove_at(SELECTED_VAULT_INDEX)
	
	if VAULTS_DATA.is_empty():
		SELECTED_VAULT_INDEX = 0
	elif SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		SELECTED_VAULT_INDEX = VAULTS_DATA.size() - 1
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)
	return true


static func get_vault_key_count(vault_index: int) -> int:
	if vault_index < 0 or vault_index >= VAULTS_DATA.size():
		return 0
	return VAULTS_DATA[vault_index].get("key_count", 0)


static func move_entry_to_vault(p_entry_dict: Dictionary, p_old_vault_index: int, p_new_vault_index: int) -> void:
	if p_old_vault_index != p_new_vault_index:
		var old_entries: Array = _fetch_entries_at(p_old_vault_index)
		for i: int in range(old_entries.size() - 1, -1, -1):
			if old_entries[i]["name"] == p_entry_dict["name"]:
				old_entries.remove_at(i)
				break
		_write_entries_at(old_entries, p_old_vault_index)

	var new_entries: Array = _fetch_entries_at(p_new_vault_index)
	var found: bool = false
	for i: int in new_entries.size():
		if new_entries[i]["name"] == p_entry_dict["name"]:
			new_entries[i] = p_entry_dict
			found = true
			break
	
	if not found:
		new_entries.append(p_entry_dict)
		
	_write_entries_at(new_entries, p_new_vault_index)


static func merge_vault(external_vault_data: Dictionary) -> bool:
	if external_vault_data.is_empty():
		return false
	
	var external_vaults: Array = external_vault_data.get("vaults", [])
	if external_vaults.is_empty():
		return false
	
	var external_derived_key: PackedByteArray = external_vault_data.get("derived_key", PackedByteArray())
	if external_derived_key.is_empty():
		return false
	
	var total_merged: int = 0
	
	for external_vault_dict: Dictionary in external_vaults:
		var external_vault_name: String = external_vault_dict.get("name", "")
		var external_vault_color: String = external_vault_dict.get("color", "#ffffff")
		
		var matching_vault_index: int = -1
		for i: int in VAULTS_DATA.size():
			if VAULTS_DATA[i].get("name", "") == external_vault_name:
				matching_vault_index = i
				break
		
		var external_encrypted: PackedByteArray = external_vault_dict.get("encrypted_data", PackedByteArray())
		var external_entries: Array = []
		
		if not external_encrypted.is_empty():
			var external_decrypted: PackedByteArray = Encryption.decrypt_data(external_encrypted, external_derived_key)
			if not external_decrypted.is_empty():
				external_entries = bytes_to_var_with_objects(external_decrypted)
				external_entries = external_entries.filter(func(e: Variant) -> bool:
					return e is Dictionary and e.has("name") and e.has("user") and e.has("password")
				)
		
		if matching_vault_index != -1:
			var current_entries: Array = _fetch_entries_at(matching_vault_index)
			
			var existing_signatures: Dictionary = {}
			for entry: Dictionary in current_entries:
				var signature: String = "%s|%s|%s" % [entry.get("name", ""), entry.get("user", ""), entry.get("password", "")]
				existing_signatures[signature] = true
			
			var merged_count: int = 0
			for entry: Dictionary in external_entries:
				var signature: String = "%s|%s|%s" % [entry.get("name", ""), entry.get("user", ""), entry.get("password", "")]
				if not existing_signatures.has(signature):
					current_entries.append(entry)
					merged_count += 1
			
			if merged_count > 0:
				_write_entries_at(current_entries, matching_vault_index)
				total_merged += merged_count
		else:
			var data: PackedByteArray = var_to_bytes_with_objects(external_entries)
			var encrypted: PackedByteArray = Encryption.encrypt_data(data, MASTER_DERIVED_KEY)
			
			var new_vault: VaultData = VaultData.new(external_vault_name, external_vault_color, external_entries.size(), encrypted)
			VAULTS_DATA.append(new_vault.to_dict())
			total_merged += external_entries.size()
	
	if total_merged > 0:
		var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
		var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
		var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
		file.close()
		_write_vault_file(master_salt, master_verifier)
	
	return total_merged > 0


static func replace_vault(external_vault_data: Dictionary) -> bool:
	if external_vault_data.is_empty():
		return false
	
	var external_vaults: Array = external_vault_data.get("vaults", [])
	if external_vaults.is_empty():
		return false
	
	var external_derived_key: PackedByteArray = external_vault_data.get("derived_key", PackedByteArray())
	if external_derived_key.is_empty():
		return false
	
	VAULTS_DATA.clear()
	
	for external_vault_dict: Dictionary in external_vaults:
		var vault_name: String = external_vault_dict.get("name", "")
		var vault_color: String = external_vault_dict.get("color", "#ffffff")
		
		var external_encrypted: PackedByteArray = external_vault_dict.get("encrypted_data", PackedByteArray())
		var entries: Array = []
		
		if not external_encrypted.is_empty():
			var external_decrypted: PackedByteArray = Encryption.decrypt_data(external_encrypted, external_derived_key)
			if not external_decrypted.is_empty():
				entries = bytes_to_var_with_objects(external_decrypted)
				entries = entries.filter(func(e: Variant) -> bool:
					return e is Dictionary and e.has("name") and e.has("user") and e.has("password")
				)
		
		var data: PackedByteArray = var_to_bytes_with_objects(entries)
		var encrypted: PackedByteArray = Encryption.encrypt_data(data, MASTER_DERIVED_KEY)
		
		var new_vault: VaultData = VaultData.new(vault_name, vault_color, entries.size(), encrypted)
		VAULTS_DATA.append(new_vault.to_dict())
	
	SELECTED_VAULT_INDEX = external_vault_data.get("selected_vault", 0)
	if SELECTED_VAULT_INDEX >= VAULTS_DATA.size():
		SELECTED_VAULT_INDEX = 0
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var master_salt: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var master_verifier: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(master_salt, master_verifier)
	
	return true


static func _fetch_entries_at(index: int) -> Array:
	if index < 0 or index >= VAULTS_DATA.size():
		return []
	
	var vault: VaultData = VaultData.from_dict(VAULTS_DATA[index])
	var decrypted: PackedByteArray = Encryption.decrypt_data(vault.encrypted_data, MASTER_DERIVED_KEY)
	if decrypted.is_empty():
		return []
	
	return bytes_to_var_with_objects(decrypted)


static func _write_entries_at(entries: Array, index: int) -> void:
	var data: PackedByteArray = var_to_bytes_with_objects(entries)
	VAULTS_DATA[index]["encrypted_data"] = Encryption.encrypt_data(data, MASTER_DERIVED_KEY)
	VAULTS_DATA[index]["key_count"] = entries.size()
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	var s: PackedByteArray = file.get_buffer(MASTER_SALT_SIZE)
	var v: PackedByteArray = file.get_buffer(MASTER_KEY_SIZE)
	file.close()
	
	_write_vault_file(s, v)


static func _load_vaults_data() -> void:
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.READ)
	file.get_buffer(MASTER_SALT_SIZE)
	file.get_buffer(MASTER_KEY_SIZE)
	
	var encrypted_container: PackedByteArray = file.get_buffer(file.get_length() - file.get_position())
	file.close()
	
	if encrypted_container.is_empty():
		VAULTS_DATA = []
		SELECTED_VAULT_INDEX = 0
		return
	
	var decrypted: PackedByteArray = Encryption.decrypt_data(encrypted_container, MASTER_DERIVED_KEY)
	if decrypted.is_empty():
		VAULTS_DATA = []
		SELECTED_VAULT_INDEX = 0
		return
	
	var container: Dictionary = bytes_to_var_with_objects(decrypted)
	VAULTS_DATA = container.get("vaults", [])
	SELECTED_VAULT_INDEX = container.get("selected_vault", 0)


static func _write_vault_file(master_salt: PackedByteArray, master_verifier: PackedByteArray) -> void:
	var container: Dictionary = {
		"vaults": VAULTS_DATA,
		"selected_vault": SELECTED_VAULT_INDEX
	}
	
	var container_data: PackedByteArray = var_to_bytes_with_objects(container)
	var encrypted_container: PackedByteArray = Encryption.encrypt_data(container_data, MASTER_DERIVED_KEY)
	
	var file: FileAccess = FileAccess.open("user://vault.kbox", FileAccess.WRITE)
	file.store_buffer(master_salt)
	file.store_buffer(master_verifier)
	file.store_buffer(encrypted_container)
	file.close()
