extends Node2D
## Living cave background: flickering torches, twinkling crystals and an
## optional slow camera pan (nice for a title screen).

## Pan the camera slowly from the sunset down to the glowing pool and back.
@export var intro_pan: bool = true
## Seconds for one pan from top to bottom.
@export var pan_time: float = 14.0

@onready var _camera: Camera2D = get_node_or_null("Camera2D")
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	for glow in get_tree().get_nodes_in_group("torch_glow"):
		if is_ancestor_of(glow):
			var seed_ := float(glow.get_index())
			var f := 0.85 + 0.1 * sin(_t * 9.0 + seed_) + 0.08 * sin(_t * 23.0 + seed_ * 3.0)
			glow.modulate.a = clampf(f, 0.6, 1.0)
			glow.scale = Vector2.ONE * glow.get_meta("base_scale", 1.0) * (0.95 + 0.06 * sin(_t * 13.0 + seed_))
	for glow in get_tree().get_nodes_in_group("crystal_glow"):
		if is_ancestor_of(glow):
			var s := float(glow.get_index())
			glow.modulate.a = 0.25 + 0.75 * pow(0.5 + 0.5 * sin(_t * 1.7 + s * 1.9), 3.0)

	if _camera and intro_pan:
		var view_h := get_viewport_rect().size.y / _camera.zoom.y
		var top := view_h * 0.5
		var bottom := 1367.0 - view_h * 0.5
		if bottom > top:
			var k := 0.5 - 0.5 * cos(_t / pan_time * PI)   # smooth ping-pong
			_camera.position.y = lerpf(top, bottom, k)
