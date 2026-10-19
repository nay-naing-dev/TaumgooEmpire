extends StaticBody2D
## Isometric Taungoo building or prop the player can walk around.
## - Draws the player in front of or behind it using the real front edges
##   (plain Y-sorting gets isometric buildings wrong near the sides).
## - Turns see-through when the player is hidden behind it.

## The building's front edges at ground level, left to right, in local pixels.
## The node origin is the front-most corner.
@export var front_edge: PackedVector2Array = PackedVector2Array([Vector2(-135, -61), Vector2(0, 0), Vector2(65, -39)])
@export_range(0.0, 1.0, 0.05) var faded_alpha: float = 0.45
@export var fade_speed: float = 4.0

@onready var _sprite: Sprite2D = $Sprite2D


func _edge_y(x: float) -> float:
	for i in front_edge.size() - 1:
		var a := front_edge[i]
		var b := front_edge[i + 1]
		if x >= a.x and x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.001))
	return 0.0


func _process(delta: float) -> void:
	var target := 1.0
	var rect := _sprite.get_rect()
	for p in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("actor"):
		var node := p as Node2D
		var local := to_local(node.global_position)
		var over_us := local.x >= front_edge[0].x and local.x <= front_edge[front_edge.size() - 1].x
		var in_front := (not over_us) or local.y >= _edge_y(local.x)
		if rect.has_point(local):
			node.z_index = 1 if in_front else 0
			if not in_front and p.is_in_group("player"):
				target = faded_alpha
		elif node.z_index == 1 and not rect.grow(8).has_point(local):
			node.z_index = 0
	_sprite.modulate.a = move_toward(_sprite.modulate.a, target, delta * fade_speed)
