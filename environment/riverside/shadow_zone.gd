extends Sprite2D
## A cast shadow on the ground. Anyone in the "player" group who stands
## inside it gets darker, so the shadow feels real.

@export var shade: Color = Color(0.68, 0.66, 0.78)
var _img: Image


func _ready() -> void:
	_img = texture.get_image()


func _process(delta: float) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		var node := p as CanvasItem
		var local := to_local((p as Node2D).global_position) - offset
		var inside := false
		if local.x >= 0 and local.y >= 0 and local.x < _img.get_width() and local.y < _img.get_height():
			inside = _img.get_pixel(int(local.x), int(local.y)).a > 0.1
		var target := shade if inside else Color.WHITE
		node.modulate = node.modulate.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
