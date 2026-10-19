extends Node2D
## Living Yangon harbour background: twinkling lamps, fitted camera.

## Keep the whole picture filling the game window.
@export var fit_to_window: bool = true

@onready var _camera: Camera2D = get_node_or_null("Camera2D")
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	for lamp in get_tree().get_nodes_in_group("city_lamp"):
		if is_ancestor_of(lamp):
			var s := float(lamp.get_index())
			lamp.modulate.a = 0.55 + 0.35 * (0.5 + 0.5 * sin(_t * (1.5 + fmod(s, 3.0) * 0.4) + s * 2.1))
	if _camera and fit_to_window:
		var vp := get_viewport_rect().size
		var z := maxf(vp.x / 1408.0, vp.y / 768.0)   # cover the window, no black bars
		_camera.zoom = Vector2(z, z)
		_camera.position = Vector2(704, 384)
