extends Area2D
## Top-down teal bolt. The node travels along the ground (so it hits
## enemies' feet colliders); the glowing part is drawn higher up.

@export var speed: float = 300.0
@export var max_distance: float = 360.0
## Gently curves toward an enemy in front of it (radians per second).
@export var homing: float = 3.0
var direction := Vector2.RIGHT
var damage := 14
var shooter: Node = null
var _travelled := 0.0
var _dead := false


func _ready() -> void:
	$Visual.rotation = direction.angle()
	body_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var target := _nearest_enemy()
	if target:
		var want := (target.global_position + Vector2(0, -4) - global_position).normalized()
		direction = direction.rotated(clampf(direction.angle_to(want), -homing * delta, homing * delta))
		$Visual.rotation = direction.angle()
	var step := speed * delta
	position += direction * step
	_travelled += step
	$Visual/Light.energy = 1.3 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
	if _travelled > max_distance:
		_burst()


func _on_hit(body: Node) -> void:
	if _dead or body == shooter or body.is_in_group("player"):
		return
	if body.is_in_group("enemy") and body.has_method("take_hit"):
		body.take_hit(damage, global_position - direction * 10.0)
	_burst()


func _burst() -> void:
	_dead = true
	$Visual/Sprite2D.visible = false
	$Visual/Trail.emitting = false
	$Visual/Burst.restart()
	var tw := create_tween()
	tw.tween_property($Visual/Light, "energy", 0.0, 0.35)
	tw.tween_callback(queue_free).set_delay(0.3)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := 260.0
	for e in get_tree().get_nodes_in_group("enemy"):
		var to: Vector2 = (e as Node2D).global_position - global_position
		var d := to.length()
		if d < best_d and direction.dot(to / maxf(d, 0.001)) > 0.5:
			best = e
			best_d = d
	return best
