class_name Metadata

static var _md: Dictionary = {}
static var _loaded: bool = false


static func set_value(id: StringName, value: Variant) -> void:
	_load()
	_md[id] = value
	_save()


static func get_value(id: StringName, default: Variant = null) -> Variant:
	_load()
	return _md.get(id, default)


static func has_value(id: StringName) -> bool:
	_load()
	return _md.has(id)


static func _load() -> void:
	if _loaded:
		return
	
	if not FileAccess.file_exists("user://metadata.bin"):
		_md = {}
		_loaded = true
		return
	
	var file: FileAccess = FileAccess.open("user://metadata.bin", FileAccess.READ)
	if file == null:
		_md = {}
		_loaded = true
		return
	
	var data: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	
	if data.is_empty():
		_md = {}
	else:
		_md = bytes_to_var(data)
	
	_loaded = true


static func _save() -> void:
	var data: PackedByteArray = var_to_bytes(_md)
	
	var file: FileAccess = FileAccess.open("user://metadata.bin", FileAccess.WRITE)
	if file == null:
		return
	
	file.store_buffer(data)
	file.close()
