extends CharacterBody2D
## Sky mage: side-view platformer heroine who fires teal energy bolts.
##   A / D or arrows : walk
##   Space / W / Up  : jump (hold for higher)
##   J               : charge the orb in her hand and fire a bolt

@export_group("Movement")
@export var walk_speed: float = 95.0
@export var acceleration: float = 900.0
@export var friction: float = 1200.0
@export var air_control: float = 0.8

@export_group("Jump")
@export var jump_velocity: float = -330.0
@export var gravity: float = 980.0
@export var fall_gravity_multiplier: float = 1.45
@export var short_hop_cut: float = 0.45
@export var coyote_time: float = 0.1
@export var jump_buffer: float = 0.12

@export_group("Magic")
@export var bolt_scene: PackedScene = preload("energy_bolt.tscn")
## Cast animation frame (0-based) on which the bolt leaves her hand.
@export var fire_frame: int = 4
@export var cast_cooldown: float = 0.35
## Where the bolt appears, relative to her feet, when facing right.
@export var hand_offset: Vector2 = Vector2(48, -78)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hand_light: PointLight2D = $HandLight
@onready var shadow: Sprite2D = $Shadow
@onready var floor_ray: RayCast2D = $FloorRay

var facing := 1
var casting := false
var _fired := false
var _cooldown := 0.0
var _coyote := 0.0
var _buffer := 0.0


func _ready() -> void:
	_ensure_input_actions()
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hand_light.energy = 0.0
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	_cooldown = maxf(_cooldown - delta, 0.0)
	_coyote = coyote_time if is_on_floor() else maxf(_coyote - delta, 0.0)
	_buffer = jump_buffer if Input.is_action_just_pressed("jump") else maxf(_buffer - delta, 0.0)

	velocity.y += gravity * (fall_gravity_multiplier if velocity.y > 0.0 else 1.0) * delta
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= short_hop_cut

	if Input.is_action_just_pressed("attack") and not casting and _cooldown <= 0.0:
		_start_cast()

	if casting:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		var control := 1.0 if is_on_floor() else air_control
		if dir != 0.0:
			velocity.x = move_toward(velocity.x, dir * walk_speed, acceleration * control * delta)
			facing = 1 if dir > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
		if _buffer > 0.0 and _coyote > 0.0:
			velocity.y = jump_velocity
			_buffer = 0.0
			_coyote = 0.0

	move_and_slide()
	sprite.flip_h = facing < 0
	_update_animation()
	_update_shadow()
	_update_hand_light(delta)


func _update_animation() -> void:
	if casting:
		return
	var anim := "idle"
	if not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 8.0:
		anim = "walk"
	if sprite.animation != anim:
		sprite.play(anim)
	# a little squash and stretch in the air makes the single jump pose feel alive
	var s := Vector2.ONE
	if not is_on_floor():
		var t := clampf(velocity.y / 400.0, -1.0, 1.0)
		s = Vector2(1.0 - absf(t) * 0.05, 1.0 + absf(t) * 0.06)
	sprite.scale = sprite.scale.lerp(s, 0.3)


func _update_shadow() -> void:
	# soft shadow on the ground: shrinks and fades the higher she is
	var h := 0.0
	if floor_ray.is_colliding():
		h = floor_ray.get_collision_point().y - global_position.y
		shadow.visible = true
		shadow.global_position.y = floor_ray.get_collision_point().y
	else:
		shadow.visible = false
	var k := clampf(1.0 - h / 160.0, 0.25, 1.0)
	shadow.scale = Vector2(0.55, 0.12) * k
	shadow.modulate.a = 0.75 * k


func _update_hand_light(delta: float) -> void:
	var target := 0.0
	if casting and sprite.animation == "cast":
		target = [0.0, 0.5, 0.9, 1.4, 0.8][clampi(sprite.frame, 0, 4)]
	hand_light.energy = move_toward(hand_light.energy, target, delta * 8.0)
	hand_light.position = Vector2(hand_offset.x * 0.55 * facing, hand_offset.y + 12)


func _start_cast() -> void:
	casting = true
	_fired = false
	sprite.play("cast")
	sprite.frame = 0


func _on_frame_changed() -> void:
	if casting and sprite.animation == "cast" and sprite.frame == fire_frame and not _fired:
		_fired = true
		var bolt := bolt_scene.instantiate()
		bolt.direction = facing
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(hand_offset.x * facing, hand_offset.y)


func _on_animation_finished() -> void:
	if sprite.animation == "cast":
		casting = false
		_cooldown = cast_cooldown
		sprite.play("idle")


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
