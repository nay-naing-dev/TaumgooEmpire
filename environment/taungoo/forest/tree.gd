extends StaticBody2D
## Forest tree: canopy sways, and it turns see-through when the player
## walks behind it so they never get lost under the leaves.

@export_range(0.0, 1.0, 0.05) var faded_alpha: float = 0.42
@export var fade_speed: float = 4.0
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var ph := randf() * TAU
	for s in [$Sprite2D, $CastShadow]:
		if s.material:
			s.material = s.material.duplicate()
			s.material.set_shader_parameter("phase", ph)


func _process(delta: float) -> void:
	var target := 1.0
	var rect := _sprite.get_rect()
	if _sprite.flip_h:
		rect.position.x = -rect.end.x
	for p in get_tree().get_nodes_in_group("player"):
		var local := to_local((p as Node2D).global_position)
		if local.y < -2.0 and rect.grow(-6).has_point(local + Vector2(0, -20)):
			target = faded_alpha
			break
	_sprite.modulate.a = move_toward(_sprite.modulate.a, target, delta * fade_speed)
