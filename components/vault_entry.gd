class_name VaultEntry
extends PanelContainer

signal password_copied
signal delete_request(ref: VaultEntry)

var entry_name: String = ""
var entry_username: String = ""
var entry_password: String = ""

@export var obfuscated: bool = false

@export_group("Internal")
@export var name_label: Label
@export var username_label: Label

@export var actual_container: VBoxContainer
@export var obfuscated_container: VBoxContainer

@export var filler_1: Panel
@export var filler_2: Panel
@export var glow: Panel
@export var bg_glow: Panel
@export var copy_button: Button
@export var delete_button: Button

var glow_tween: Tween
var bg_glow_tween: Tween


func _ready() -> void:
	if obfuscated:
		show_obfucsated()
	else:
		show_normal()
	Chroma.bind_color(bg_glow, "stylebox/panel", "bg_color")


func show_obfucsated() -> void:
	obfuscated_container.show()
	actual_container.hide()
	
	filler_1.custom_minimum_size.x = randi_range(90, 190)
	filler_2.custom_minimum_size.x = randi_range(60, 120)


func show_normal() -> void:
	actual_container.show()
	obfuscated_container.hide()
	
	name_label.text = entry_name
	username_label.text = entry_username


func animate_copy() -> void:
	glow.self_modulate = Color.TRANSPARENT
	glow.show()
	glow_tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
	glow_tween.tween_property(glow, ^"self_modulate", Color.WHITE, 0.15)
	
	await get_tree().create_timer(2).timeout
	
	if not glow_tween.is_running():
		glow_tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
	
	glow_tween.tween_property(glow, ^"self_modulate", Color.TRANSPARENT, 0.15)


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(entry_password)
	password_copied.emit()
	animate_copy()


func _on_mouse_entered() -> void:
	if bg_glow_tween and bg_glow_tween.is_running():
		bg_glow_tween.kill()
	
	bg_glow.self_modulate = Color.TRANSPARENT
	bg_glow.show()
	
	bg_glow_tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
	bg_glow_tween.tween_property(bg_glow, ^"self_modulate", Color.WHITE, 0.15)
	bg_glow_tween.tween_property(delete_button, ^"self_modulate", Color.WHITE, 0.15)


func _on_mouse_exited() -> void:
	if bg_glow_tween and bg_glow_tween.is_running():
		bg_glow_tween.kill()
	
	bg_glow_tween = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
	bg_glow_tween.tween_property(bg_glow, ^"self_modulate", Color.TRANSPARENT, 0.15)
	bg_glow_tween.tween_property(delete_button, ^"self_modulate", Color.TRANSPARENT, 0.15)


func _on_delete_button_pressed() -> void:
	delete_request.emit(self)
