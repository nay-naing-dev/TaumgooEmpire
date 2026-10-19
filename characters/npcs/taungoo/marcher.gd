extends Node2D
## Moves along a list of points and loops (ping-pong). Used for the marching
## spear squad and for patrolling riders. Children named "Unit*" bob in step;
## riders gallop. Sprites flip to face the way they are going.

@export var points: PackedVector2Array = PackedVector2Array()
@export var speed: float = 22.0
## Steps per second (soldiers ~2.2, horses ~3.5).
@export var step_rate: float = 2.2
@export var bob_pixels: float = 1.5
@export var pause_at_ends: float = 2.5
## Tick if the pictures face left.
@export var art_faces_left: bool = false

var _i := 1
var _dir := 1
var _wait := 0.0
var _t := 0.0
var _units: Array[Node2D] = []
var _base_y: Array[float] = []


func _ready() -> void:
	add_to_group("actor")
	if points.size() > 0:
		global_position = points[0]
	for c in get_children():
		if c is Node2D and c.name.begins_with("Unit"):
			_units.append(c)
			_base_y.append(c.get_node("Sprite2D").position.y)


func _process(delta: float) -> void:
	if points.size() < 2:
		return
	var moving := false
	var target := points[_i]
	if _wait > 0.0:
		_wait -= delta
	else:
		var before := global_position
		global_position = global_position.move_toward(target, speed * delta)
		moving = global_position != before
		if global_position.distance_to(target) < 0.5:
			if _i + _dir >= points.size() or _i + _dir < 0:
				_dir = -_dir
				_wait = pause_at_ends
			_i += _dir
		var going_left := (points[_i].x - global_position.x) < 0.0
		for u in _units:
			u.get_node("Sprite2D").flip_h = going_left != art_faces_left
	_t += delta
	for k in _units.size():
		var spr: Sprite2D = _units[k].get_node("Sprite2D")
		var phase := _t * step_rate * TAU
		var b := absf(sin(phase)) * bob_pixels if moving else 0.0
		spr.position.y = _base_y[k] - round(b)
		spr.rotation = (sin(phase) * 0.03) if moving else 0.0
