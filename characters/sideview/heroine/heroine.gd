extends CharacterBody2D
class_name Heroine
## Side-view platformer swordswoman.
##   A / D or arrows : run
##   Space / W / Up  : jump (hold for a higher jump)
##   J               : sword combo (press again during a swing for the next hit)

signal hit(target: Node)

enum State { IDLE, RUN, JUMP, FALL, LAND, ATTACK }

@export_group("Movement")
@export var run_speed: float = 150.0
@export var acceleration: float = 1100.0
@export var friction: float = 1400.0
@export var air_control: float = 0.75

@export_group("Jump")
@export var jump_velocity: float = -340.0
@export var gravity: float = 980.0
## Falling is a bit faster than rising, which feels snappier.
@export var fall_gravity_multiplier: float = 1.45
## Let go of jump early for a short hop.
@export var short_hop_cut: float = 0.45
## Seconds you can still jump after running off a ledge.
@export var coyote_time: float = 0.1
## Seconds a jump press is remembered before landing.
@export var jump_buffer: float = 0.12

@export_group("Combat")
## Small forward step on each sword hit.
@export var attack_lunge: Array[float] = [60.0, 70.0, 140.0]
## Animation frame (0-based) where each hit is active.
@export var active_frames: Array[int] = [2, 2, 2]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var state: State = State.IDLE
var facing := 1
var combo := 0
var _queued_attack := false
var _coyote := 0.0
var _buffer := 0.0
var _hit_this_swing: Array[Node] = []


func _ready() -> void:
	_ensure_input_actions()
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hitbox.body_entered.connect(_on_hitbox_body)
	hitbox.monitoring = false
	_play("idle")


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")

	# timers for forgiving jumps
	_coyote = coyote_time if is_on_floor() else maxf(_coyote - delta, 0.0)
	_buffer = jump_buffer if Input.is_action_just_pressed("jump") else maxf(_buffer - delta, 0.0)

	# gravity (heavier when falling, cut short when jump is released)
	var g := gravity * (fall_gravity_multiplier if velocity.y > 0.0 else 1.0)
	velocity.y += g * delta
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= short_hop_cut

	if Input.is_action_just_pressed("attack"):
		if state == State.ATTACK:
			_queued_attack = true
		else:
			_start_attack(1)

	match state:
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, friction * 0.6 * delta)
		_:
			_move(dir, delta)
			if _buffer > 0.0 and _coyote > 0.0:
				velocity.y = jump_velocity
				_buffer = 0.0
				_coyote = 0.0
				_set_state(State.JUMP)

	move_and_slide()
	_update_state(dir)


func _move(dir: float, delta: float) -> void:
	var control := 1.0 if is_on_floor() else air_control
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * run_speed, acceleration * control * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
	sprite.flip_h = facing < 0
	hitbox.scale.x = facing


func _update_state(dir: float) -> void:
	if state == State.ATTACK:
		return
	if not is_on_floor():
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
		return
	if state == State.FALL or (state == State.JUMP and velocity.y >= 0.0):
		_set_state(State.LAND)
		return
	if state == State.LAND:
		if dir != 0.0:
			_set_state(State.RUN)
		return
	_set_state(State.RUN if absf(velocity.x) > 10.0 else State.IDLE)


func _set_state(s: State) -> void:
	if s == state:
		return
	state = s
	match s:
		State.IDLE: _play("idle")
		State.RUN: _play("run")
		State.JUMP: _play("jump")
		State.FALL: _play("fall")
		State.LAND: _play("land")


func _start_attack(n: int) -> void:
	combo = n
	_queued_attack = false
	_hit_this_swing.clear()
	state = State.ATTACK
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	sprite.flip_h = facing < 0
	hitbox.scale.x = facing
	velocity.x = facing * attack_lunge[n - 1]
	_play("attack_%d" % n, true)


func _on_frame_changed() -> void:
	if state == State.ATTACK:
		hitbox.monitoring = sprite.frame == active_frames[combo - 1] or sprite.frame == active_frames[combo - 1] + 1


func _on_animation_finished() -> void:
	if state == State.ATTACK:
		hitbox.monitoring = false
		if _queued_attack and combo < 3:
			_start_attack(combo + 1)
		else:
			combo = 0
			state = State.IDLE
			_play("idle")
	elif state == State.LAND:
		state = State.IDLE
		_play("idle")


func _on_hitbox_body(body: Node) -> void:
	if body == self or _hit_this_swing.has(body):
		return
	_hit_this_swing.append(body)
	hit.emit(body)
	if body.has_method("take_hit"):
		body.take_hit(combo, facing)


func _play(anim: String, restart: bool = false) -> void:
	if restart or sprite.animation != anim:
		sprite.play(anim)
		if restart:
			sprite.frame = 0


func _ensure_input_actions() -> void:
	_add("move_left", [KEY_A, KEY_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT])
	_add("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add("attack", [KEY_J])


func _add(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
