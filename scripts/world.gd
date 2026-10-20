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
var _shade_vp: SubViewport
var _shade_t := 0.0
var _t := 0.0


func _ready() -> void:
	apply_night(Game.night_mode, false)
	_setup_light_and_water()
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
	# refresh the shadow map ~15 times a second so swaying leaf shadows move on bodies too
	_shade_t -= delta
	if _shade_vp and _shade_t <= 0.0:
		_shade_t = 1.0 / 15.0
		_shade_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	if _pan_cam == null:
		return
	_t += delta
	# drift along a loop: palace -> market -> fortress gate -> monastery
	var k := _t * 0.035
	_pan_cam.position = Vector2(1000, 620) + Vector2(cos(k) * 520.0, sin(k * 2.0) * 220.0)


func _exit_tree() -> void:
	Game.reset_world_globals()


## Water map + shadow map for living light, reflections, wading and ripples.
func _setup_light_and_water() -> void:
	if has_node("Water"):
		var w: Sprite2D = $Water
		Game.set_world_water(w.texture, Rect2(w.global_position, w.texture.get_size()))
	# --- shadow map: every tree/building/palm cast shadow, drawn once more into a
	# half-size picture of the world (white = sun, dark = shadow). Characters read it,
	# so canopy shadows slide over their bodies as they walk.
	var vp := SubViewport.new()
	vp.name = "ShadeMap"
	vp.size = Vector2i(map_size / 2.0)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(0.5, 0.5))
	_shade_vp = vp
	var bg := ColorRect.new()
	bg.color = Color.WHITE
	bg.size = map_size
	vp.add_child(bg)
	var dir := Vector2(-0.4, -0.3)
	var found := false
	for cs in find_children("CastShadow", "Sprite2D", true, false):
		if cs.owner and cs.owner.scene_file_path.begins_with("res://characters/"):
			continue
		var d := Sprite2D.new()
		d.texture = cs.texture
		d.centered = cs.centered
		d.offset = cs.offset
		d.flip_h = cs.flip_h
		d.flip_v = cs.flip_v
		d.region_enabled = cs.region_enabled
		d.region_rect = cs.region_rect
		d.material = cs.material
		d.transform = cs.global_transform
		d.modulate = Color(0, 0, 0, clampf(cs.modulate.a * 1.8, 0.0, 0.9))
		vp.add_child(d)
		if not found and cs.owner and "forest" in cs.owner.scene_file_path:
			var ps: float = cs.get_parent().global_scale.y
			dir = cs.global_transform.basis_xform(Vector2(0, -1)) / maxf(ps, 0.01)
			found = true
	Game.set_world_shade(vp.get_texture(), Rect2(Vector2.ZERO, map_size), dir)
	# --- ripples, boat and palm reflections
	var rip := preload("res://scripts/ripples.gd").new()
	rip.name = "Ripples"
	add_child(rip)
	if has_node("Objects"):
		for o in $Objects.get_children():
			if str(o.name).begins_with("Sampan"):
				o.add_to_group("boat")
				Game.add_reflection(o, 14.0)
			elif str(o.name).begins_with("Palm") and o.has_node("Sprite2D"):
				if Game.water_near(o.global_position, 70.0):
					Game.add_reflection(o.get_node("Sprite2D"))


## Night: moonlit blue, sun off, torches and fireflies stand out.
func apply_night(on: bool, animate: bool) -> void:
	var tint := Color(0.32, 0.38, 0.62) if on else Color(0.88, 0.87, 0.84)
	var sun_energy := 0.0 if on else 0.5
	var shaft_alpha := 0.0 if on else 1.0
	var t := 1.5 if animate else 0.0
	var tw := create_tween().set_parallel()
	if has_node("Atmosphere"):
		tw.tween_property($Atmosphere, "color", tint, t)
	if has_node("Sun"):
		tw.tween_property($Sun, "energy", sun_energy, t)
	if has_node("SunShafts"):
		tw.tween_property($SunShafts, "modulate:a", shaft_alpha, t)
	if has_node("Moon"):
		tw.tween_property($Moon, "energy", 0.45 if on else 0.0, t)
	if has_node("Fireflies"):
		$Fireflies.modulate.a = 1.0 if on else 0.35
