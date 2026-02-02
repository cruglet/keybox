class_name Chroma
extends Node


static var accent_color: Color = Color.DODGER_BLUE

static var _bindings: Array[Dictionary] = []
static var _stylebox_cache: Dictionary = {}


static func modify_color(base: Color, brightness: float = 1.0, alpha: float = 1.0) -> Color:
	var modified: Color = base * brightness
	modified.a = alpha
	return modified
	

static func bind_color(
	control: Control,
	theme_path: String,
	property: String,
	brightness: float = 1.0,
	alpha: float = 1.0
) -> void:
	if not is_instance_valid(control):
		return
		
	var parts: PackedStringArray = theme_path.split("/")
	var theme_type: String = parts[0]
	var theme_name: String = parts[1] if parts.size() > 1 else ""
	
	var binding: Dictionary = {
		"control": control,
		"theme_type": theme_type,
		"theme_name": theme_name,
		"property": property,
		"brightness": brightness,
		"alpha": alpha
	}
	
	if theme_type == "stylebox":
		var control_id: int = control.get_instance_id()
		
		if not _stylebox_cache.has(control_id):
			_stylebox_cache[control_id] = {}
		
		if not _stylebox_cache[control_id].has(theme_name):
			var base_stylebox: StyleBox = control.get_theme_stylebox(theme_name)
			if base_stylebox == null:
				return
				
			var stylebox: StyleBox = base_stylebox.duplicate()
			control.add_theme_stylebox_override(theme_name, stylebox)
			_stylebox_cache[control_id][theme_name] = stylebox
		
		binding["stylebox"] = _stylebox_cache[control_id][theme_name]
	
	elif theme_type == "node":
		binding["node_property"] = theme_name
	
	_bindings.append(binding)
	_apply_binding(binding)
	

static func set_accent_color(color: Color) -> void:
	accent_color = color
	_refresh_all_bindings()
	

static func _apply_binding(binding: Dictionary) -> void:
	var control: Control = binding["control"]
	if not is_instance_valid(control):
		return
		
	var final_color: Color = modify_color(
		accent_color,
		binding["brightness"],
		binding["alpha"]
	)
	
	if binding["theme_type"] == "stylebox":
		var stylebox: StyleBox = binding["stylebox"]
		if is_instance_valid(stylebox):
			stylebox.set(binding["property"], final_color)
	
	elif binding["theme_type"] == "color":
		control.add_theme_color_override(binding["theme_name"], final_color)
	
	elif binding["theme_type"] == "node":
		var node_property: String = binding["node_property"]
		if control.get(node_property) != null:
			control.set(node_property, final_color)
	

static func _refresh_all_bindings() -> void:
	var i: int = _bindings.size() - 1
	while i >= 0:
		var binding: Dictionary = _bindings[i]
		if is_instance_valid(binding["control"]):
			_apply_binding(binding)
		else:
			_bindings.remove_at(i)
		i -= 1
