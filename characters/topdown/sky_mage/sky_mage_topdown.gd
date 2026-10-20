extends CharacterBody2D
## Sky mage for the top-down world. Uses her side-view frames and flips
## left/right; moves in 8 directions; J charges the orb and fires a bolt
## in the direction she last moved. Works with the HUD and the boss
## (same health / take_hit / died interface as player_topdown.gd).

signal health_changed(current: int, maximum: int)
signal died

@export var move_speed: float = 72.0
@export var acceleration: float = 900.0
@export var friction: float = 1200.0
@export var iso_vertical_ratio: float = 0.5
@export var max_health: int = 90
@export var bolt_damage: int = 14
@export var bolt_scene: PackedScene = preload("energy_bolt_td.tscn")
@export var fire_frame: int = 4
@export var cast_cooldown: float = 0.3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hand_light: PointLight2D = $HandLight

var health: int
var dead := false
var casting := false
var aim := Vector2.RIGHT          # screen-space direction, already iso-squashed
var _fired := false
var _cooldown := 0.0
var _invulnerable := 0.0
var _knockback := Vector2.ZERO


func _ready() -> void:
	health = max_health
	add_to_group("player")
	_ensure_input_actions()
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hand_light.energy = 0.0
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	if dead:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("attack") and not casting and _cooldown <= 0.0:
		casting = true
		_fired = false
		sprite.play("cast")
		sprite.frame = 0

	if casting:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	elif input != Vector2.ZERO:
		var dir := Vector2(input.x, input.y * iso_vertical_ratio)
		velocity = velocity.move_toward(dir * move_speed * (0.65 if Game.is_water(global_position) else 1.0), acceleration * delta)  # slower when wading
		aim = dir.normalized()
		if absf(input.x) > 0.1:
			sprite.flip_h = input.x < 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	var push := _knockback
	velocity += push
	move_and_slide()
	velocity -= push
	_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)

	if not casting:
		var anim := "walk" if velocity.length() > 8.0 else "idle"
		if sprite.animation != anim:
			sprite.play(anim)
	var target := 0.0
	if casting and sprite.animation == "cast":
		target = [0.0, 0.5, 0.9, 1.4, 0.8][clampi(sprite.frame, 0, 4)]
	hand_light.energy = move_toward(hand_light.energy, target, delta * 8.0)
	hand_light.position.x = 16.0 * (-1.0 if sprite.flip_h else 1.0)


func _on_frame_changed() -> void:
	if casting and sprite.animation == "cast" and sprite.frame == fire_frame and not _fired:
		_fired = true
		var bolt := bolt_scene.instantiate()
		bolt.direction = aim
		bolt.damage = bolt_damage
		bolt.shooter = self
		get_parent().add_child(bolt)
		bolt.global_position = global_position + aim * 18.0


func _on_animation_finished() -> void:
	if sprite.animation == "cast":
		casting = false
		_cooldown = cast_cooldown
		sprite.play("idle")


func take_hit(amount: int, from_position: Vector2) -> void:
	if dead or _invulnerable > 0.0:
		return
	health = max(health - amount, 0)
	_invulnerable = 0.6
	health_changed.emit(health, max_health)
	var away := global_position - from_position
	_knockback = (away.normalized() if away.length() > 0.1 else Vector2.DOWN) * 150.0
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.8, 0.5, 0.5), 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health == 0:
		dead = true
		casting = false
		sprite.stop()
		create_tween().tween_property(sprite, "modulate", Color(0.4, 0.2, 0.2, 0.0), 1.2)
		died.emit()


func _ensure_input_actions() -> void:
	_add("move_up", [KEY_W, KEY_UP])
	_add("move_down", [KEY_S, KEY_DOWN])
	_add("move_left", [KEY_A, KEY_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT])
	_add("attack", [KEY_J])


func _add(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
