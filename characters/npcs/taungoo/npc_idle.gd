extends StaticBody2D
## Townsperson / courtier / guard who stands in place: breathes, shifts
## weight now and then, and turns to face the player when they come close.

## Tick if the picture faces left (horses and riders in this set do).
@export var art_faces_left: bool = false
@export var notice_radius: float = 70.0
@export var turn_to_player: bool = true

@onready var sprite: Sprite2D = $Sprite2D
var _t := 0.0
var _base_scale := Vector2.ONE
var _start_flip := false


func _ready() -> void:
	add_to_group("actor")
	_t = randf() * 10.0
	_base_scale = sprite.scale
	_start_flip = sprite.flip_h


func _process(delta: float) -> void:
	_t += delta
	# breathing: tiny vertical stretch from the feet
	sprite.scale = _base_scale * Vector2(1.0, 1.0 + 0.018 * sin(_t * 2.1))
	if not turn_to_player:
		return
	var face_flip := _start_flip
	for p in get_tree().get_nodes_in_group("player"):
		var d: Vector2 = (p as Node2D).global_position - global_position
		if Vector2(d.x, d.y * 2.0).length() < notice_radius and absf(d.x) > 4.0:
			var player_left := d.x < 0.0
			face_flip = player_left != art_faces_left
	sprite.flip_h = face_flip
