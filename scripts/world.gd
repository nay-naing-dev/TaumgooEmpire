extends Node2D
## Taungoo world. Spawns the chosen top-down character at PlayerSpawn,
## gives them a camera that stays inside the map, and adds the HUD.
## With spawn_player off (title screen) it slowly pans across the city instead.

@export var map_size: Vector2 = Vector2(2048, 1280)
@export var camera_zoom: float = 2.4
@export var spawn_player: bool = true
## Set this to play a specific character when you run this scene directly (F6).
@export_enum("swordsman", "gunslinger", "burmese_man", "sky_mage") var test_character: String = ""

var _pan_cam: Camera2D
var _t := 0.0


func _ready() -> void:
	if not spawn_player:
		_pan_cam = Camera2D.new()
		_pan_cam.zoom = Vector2(1.25, 1.25)
		add_child(_pan_cam)
		_pan_cam.make_current()
		for b in get_tree().get_nodes_in_group("boss"):
			b.set_physics_process(false)
		return
	var key: String = test_character if test_character != "" else Game.topdown_character
	var player: Node2D = load(Game.TOPDOWN[key]).instantiate()
	player.global_position = $PlayerSpawn.global_position
	$Objects.add_child(player)
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	cam.position = Vector2(0, -30)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(map_size.x)
	cam.limit_bottom = int(map_size.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	cam.make_current()

	var hud := preload("res://scripts/hud.gd").new()
	add_child(hud)
	hud.watch_player(player)
	for boss in get_tree().get_nodes_in_group("boss"):
		hud.watch_boss(boss)


func _process(delta: float) -> void:
	if _pan_cam == null:
		return
	_t += delta
	# drift along a loop: palace -> market -> fortress gate -> monastery
	var k := _t * 0.035
	_pan_cam.position = Vector2(1000, 620) + Vector2(cos(k) * 520.0, sin(k * 2.0) * 220.0)
