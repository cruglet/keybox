class_name AnimatedPanel
extends PanelContainer

@export var content: Control

@export var fade_duration: float = 0.3
@export var start_scale: Vector2 = Vector2(0.8, 0.8)
@export var end_scale: Vector2 = Vector2.ONE

var tween: Tween


func show_panel() -> void:
	modulate = Color.TRANSPARENT
	content.scale = start_scale
	show()
	
	tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	tween.tween_property(content, "scale", end_scale, fade_duration)


func hide_panel() -> void:
	tween = create_tween()
	tween.set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	tween.tween_property(content, "scale", start_scale, fade_duration)
	tween.finished.connect(func() -> void:
		hide()
	, CONNECT_ONE_SHOT)
