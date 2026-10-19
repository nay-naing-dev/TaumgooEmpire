extends Area2D
## Teal energy bolt. Flies straight, lights up the world around it,
## leaves a sparkling trail, and bursts on whatever it hits.

@export var speed: float = 420.0
@export var max_distance: float = 520.0
var direction := 1
var _travelled := 0.0
var _dead := false


func _ready() -> void:
	$Sprite2D.flip_h = direction < 0
	body_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step := speed * delta
	position.x += step * direction
	_travelled += step
	$Light.energy = 1.4 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
	if _travelled > max_distance:
		_burst()


func _on_hit(body: Node) -> void:
	if _dead or body.is_in_group("player"):
		return
	if body.has_method("take_hit"):
		body.take_hit(1, direction)
	_burst()


func _burst() -> void:
	_dead = true
	$Sprite2D.visible = false
	$Trail.emitting = false
	$Burst.restart()
	var tw := create_tween()
	tw.tween_property($Light, "energy", 0.0, 0.35)
	tw.tween_callback(queue_free).set_delay(0.3)
