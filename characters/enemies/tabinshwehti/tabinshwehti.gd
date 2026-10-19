extends CharacterBody2D
## Boss: the cursed king. Sits meditating in his ritual circle until the
## player comes close, then rises and fights. Leave the arena and he returns
## to his seat and heals. Below half health he becomes faster and angrier.

signal engaged(boss: Node)
signal health_changed(current: int, maximum: int)
signal defeated

enum State { DORMANT, AWAKEN, CHASE, WINDUP, STRIKE, RECOVER, RETURN, DEAD }

@export var display_name: String = "King Tabinshwehti, the Undying"
@export var max_health: int = 220
@export var damage: int = 18
## The fight starts when the player comes this close (ground pixels).
@export var aggro_radius: float = 150.0
## He gives up and goes home if the player runs this far from his seat.
@export var leash_radius: float = 460.0
@export var speed: float = 52.0
@export var attack_range: float = 58.0
@export var windup_time: float = 0.5
@export var strike_time: float = 0.2
@export var recover_time: float = 0.55

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aura: Node2D = $Aura
@onready var aura_light: PointLight2D = $AuraLight

var state: State = State.DORMANT
var health: int
var _home: Vector2
var _timer := 0.0
var _t := 0.0
var _hit_done := false
var _knockback := Vector2.ZERO
var _enraged := false


func _ready() -> void:
	health = max_health
	_home = global_position
	add_to_group("enemy")
	add_to_group("boss")
	sprite.play("meditate")


func _player() -> Node2D:
	var ps := get_tree().get_nodes_in_group("player")
	for p in ps:
		if not p.get("dead"):
			return p
	return null


static func ground(v: Vector2) -> Vector2:
	return Vector2(v.x, v.y * 2.0)          # undo the iso squash


func _physics_process(delta: float) -> void:
	_t += delta
	_timer -= delta
	# the circle lies flat on the ground: pulse it instead of spinning it
	var pulse := 0.5 + 0.5 * sin(_t * (5.0 if _enraged else 2.2))
	aura.modulate.a = (0.45 + 0.35 * pulse) if state != State.DEAD else aura.modulate.a
	var p := _player()
	var to_p := Vector2.ZERO
	if p:
		to_p = p.global_position - global_position

	match state:
		State.DORMANT:
			velocity = Vector2.ZERO
			sprite.offset.y = -55 - 3.0 - 3.0 * sin(_t * 2.0)        # floating in meditation
			aura_light.energy = 0.6 + 0.2 * sin(_t * 2.0)
			if p and ground(to_p).length() < aggro_radius:
				_awaken()
		State.AWAKEN:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.CHASE
		State.CHASE:
			if p == null or ground(p.global_position - _home).length() > leash_radius:
				state = State.RETURN
			elif ground(to_p).length() <= attack_range:
				_start_attack()
			else:
				velocity = to_p.normalized() * speed * (1.35 if _enraged else 1.0)
				_face(to_p.x)
				_play("run")
		State.WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.STRIKE
				_timer = strike_time
				_play("attack_strike")
				velocity = Vector2(signf(-1.0 if sprite.flip_h else 1.0), 0.25) * 140.0    # lunge
		State.STRIKE:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if not _hit_done and p:
				var d := ground(p.global_position - global_position)
				var front := (d.x >= -12.0) if not sprite.flip_h else (d.x <= 12.0)
				if d.length() <= attack_range + 10.0 and front:
					_hit_done = true
					p.take_hit(damage, global_position)
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time * (0.6 if _enraged else 1.0)
				_play("attack_recover")
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.CHASE
		State.RETURN:
			var home := _home - global_position
			if home.length() < 4.0:
				health = max_health
				health_changed.emit(health, max_health)
				state = State.DORMANT
				sprite.play("meditate")
				var tw := create_tween()
				tw.tween_property(aura, "scale", Vector2.ONE, 0.6)
			else:
				velocity = home.normalized() * speed
				_face(home.x)
				_play("run")
				if p and ground(to_p).length() < aggro_radius:
					state = State.CHASE
		State.DEAD:
			velocity = Vector2.ZERO

	var push := _knockback
	velocity += push
	move_and_slide()
	velocity -= push
	_knockback = _knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	if state != State.DORMANT:
		sprite.offset.y = -55


func _awaken() -> void:
	state = State.AWAKEN
	_timer = 1.1
	sprite.play("stand")
	engaged.emit(self)
	health_changed.emit(health, max_health)
	var tw := create_tween().set_parallel()
	tw.tween_property(aura, "scale", Vector2(1.15, 1.15), 0.5)
	tw.tween_property(aura_light, "energy", 1.6, 0.3)
	$Roar.restart()
	_shake_camera(6.0)


func _start_attack() -> void:
	state = State.WINDUP
	_timer = windup_time * (0.65 if _enraged else 1.0)
	_hit_done = false
	_play("attack_windup")


func _face(dx: float) -> void:
	if absf(dx) > 2.0:
		sprite.flip_h = dx < 0.0


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


func take_hit(amount: int, from_position: Vector2) -> void:
	if state == State.DEAD:
		return
	if state == State.DORMANT:
		_awaken()
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	var away := global_position - from_position
	_knockback = (away.normalized() if away.length() > 0.1 else Vector2.UP) * 90.0
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3, 3, 3), 0.04)
	tw.tween_property(sprite, "modulate", Color(1.2, 0.85, 0.85) if _enraged else Color.WHITE, 0.15)
	$HitSpark.restart()
	if not _enraged and health <= max_health / 2:
		_enraged = true
		aura_light.color = Color(1.0, 0.15, 0.1)
		_shake_camera(5.0)
	if health == 0:
		_die()


func _die() -> void:
	state = State.DEAD
	collision_layer = 0
	remove_from_group("enemy")
	sprite.play("stand")
	$DeathBurst.restart()
	_shake_camera(10.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(sprite, "modulate", Color(2.0, 0.6, 0.4, 0.0), 1.6)
	tw.tween_property(sprite, "position:y", -30.0, 1.6)
	tw.tween_property(aura, "modulate:a", 0.0, 1.6)
	tw.tween_property(aura_light, "energy", 0.0, 1.6)
	defeated.emit()


func _shake_camera(strength: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := cam.create_tween()
	for i in 8:
		tw.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)
