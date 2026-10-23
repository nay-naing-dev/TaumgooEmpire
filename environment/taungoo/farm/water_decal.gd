extends Node2D
## Adds a painted water area (like the rice paddies) to the world's water, so you
## wade in it, reflect in it and leave ripple rings. `mask` alpha = water.

@export var mask: Texture2D
## How deep it counts for wading (0..1). Paddies are shallow.
@export var depth := 0.12
@export var sprite_path: NodePath = ^"Field"


func _ready() -> void:
	_register.call_deferred()


func _register() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or mask == null or game.get("water_image") == null:
		return
	var img: Image = game.water_image.duplicate()
	var pm: Image = mask.get_image()
	if pm.is_compressed():
		pm.decompress()
	var spr := get_node(sprite_path) as Node2D
	var o := Vector2i((spr.global_position - game.water_rect.position).round())
	for y in pm.get_height():
		for x in pm.get_width():
			if pm.get_pixel(x, y).a > 0.5:
				var q := o + Vector2i(x, y)
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
					img.set_pixelv(q, Color(depth, 0, 0, 1))
	game.set_world_water(ImageTexture.create_from_image(img), game.water_rect)
