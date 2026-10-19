extends Sprite2D
## Soft flickering glow for a gas lamp.

var _t := randf() * 10.0
@onready var _base_scale := scale


func _process(delta: float) -> void:
	_t += delta
	var f := 0.9 + 0.06 * sin(_t * 7.0) + 0.04 * sin(_t * 17.0)
	modulate.a = f
	scale = _base_scale * (0.97 + 0.03 * sin(_t * 5.0))
