extends Sprite2D
## A boat sailing back and forth between two points on the river.
## It bobs on the waves, turns around at each end, and leaves a wake.

@export var point_a: Vector2 = Vector2(100, 650)
@export var point_b: Vector2 = Vector2(300, 650)
## Pixels per second.
@export var speed: float = 12.0
## How much it rises and falls on the waves (pixels).
@export var bob_height: float = 1.0
## Wait this many seconds at each end before turning back.
@export var pause_time: float = 2.0
## Tick this if the picture of the boat faces left instead of right.
@export var art_faces_left: bool = false

var _to_b := true
var _wait := 0.0
var _t := 0.0
var _wake: CPUParticles2D


func _ready() -> void:
	position = point_a
	_t = randf() * 10.0
	_wake = get_node_or_null("Wake")


func _process(delta: float) -> void:
	_t += delta
	var target := point_b if _to_b else point_a
	var moving := false
	if _wait > 0.0:
		_wait -= delta
	else:
		var before := position
		position = position.move_toward(target, speed * delta)
		moving = position != before
		if position == target:
			_to_b = not _to_b
			_wait = pause_time
	# face the direction of travel
	var going_right := (target.x - position.x) >= 0.0
	flip_h = going_right == art_faces_left
	# gentle bobbing and rocking
	offset.y = round(sin(_t * 1.8) * bob_height)
	rotation = sin(_t * 1.3) * 0.015
	# keep smoke / wake attachments on the correct side when the boat turns
	for child in get_children():
		if child.has_meta("base_x"):
			child.position.x = float(child.get_meta("base_x")) * (-1.0 if flip_h else 1.0)
	if _wake:
		_wake.emitting = moving
		_wake.position.x = (-1.0 if going_right else 1.0) * texture.get_width() * 0.35
