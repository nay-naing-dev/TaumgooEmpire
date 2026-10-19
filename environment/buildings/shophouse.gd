extends StaticBody2D
## A building or prop the player can walk behind.
## The node's origin is where the building touches the ground (bottom centre),
## so a Y-sorted parent draws the player in front or behind automatically.
## When the player is hidden behind it, the building turns see-through.

## How see-through it gets when the player is behind (0 = invisible, 1 = solid).
@export_range(0.0, 1.0, 0.05) var faded_alpha: float = 0.5
@export var fade_speed: float = 4.0

@onready var _sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	var target := 1.0
	var rect := _sprite.get_rect()
	for p in get_tree().get_nodes_in_group("player"):
		var local := to_local((p as Node2D).global_position)
		# behind = above our ground line, and inside the picture
		if local.y < 0.0 and rect.has_point(local):
			target = faded_alpha
			break
	_sprite.modulate.a = move_toward(_sprite.modulate.a, target, delta * fade_speed)
