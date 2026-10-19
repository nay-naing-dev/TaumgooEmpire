extends StaticBody2D
## Training dummy: wobbles and flashes when the heroine hits it.

@onready var sprite: Sprite2D = $Sprite2D
var _wobble := 0.0
var _flash := 0.0
var _dir := 1


func take_hit(combo: int, from_dir: int) -> void:
	_wobble = 0.35 + 0.15 * combo
	_flash = 0.12
	_dir = from_dir
	var spark := $Spark as CPUParticles2D
	spark.restart()


func _process(delta: float) -> void:
	_wobble = move_toward(_wobble, 0.0, delta * 1.2)
	sprite.rotation = sin(Time.get_ticks_msec() * 0.025) * _wobble * 0.5 * _dir
	_flash = maxf(_flash - delta, 0.0)
	sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else Color.WHITE
