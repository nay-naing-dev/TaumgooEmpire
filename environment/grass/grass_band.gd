extends Node2D
## One strip of grass tufts (strips are Y-sorted with the characters, so you walk
## in front of / behind the grass), or - with `shadow` on - all the grass shadows.
## GrassField creates these; you don't need to touch them.

const CELLS := 8
const CELL := Vector2(44, 40)
const BASE := Vector2(22, 38)

## Each tuft: [position, variant, scale, flipped, tint]
var tufts: Array = []
var atlas: Texture2D
var shadow := false


func _draw() -> void:
	var cu := 1.0 / CELLS
	for t in tufts:
		var p: Vector2 = t[0]
		var v: int = t[1]
		var sc: float = t[2]
		var flip: bool = t[3]
		if not shadow:
			var w := CELL.x * sc
			var dst := Rect2(p.x - BASE.x * sc, p.y - BASE.y * sc, w, CELL.y * sc)
			if flip:
				dst = Rect2(p.x + BASE.x * sc, p.y - BASE.y * sc, -w, CELL.y * sc)
			draw_texture_rect_region(atlas, dst, Rect2(v * CELL.x, 0, CELL.x, CELL.y), t[4])
		else:
			var xf := Transform2D(0.0, Vector2(sc * (-1.0 if flip else 1.0), sc * 0.5), -0.95, p)
			var pts := PackedVector2Array([xf * Vector2(-BASE.x, -BASE.y), xf * Vector2(CELL.x - BASE.x, -BASE.y),
					xf * Vector2(CELL.x - BASE.x, CELL.y - BASE.y), xf * Vector2(-BASE.x, CELL.y - BASE.y)])
			var uvs := PackedVector2Array([Vector2(v * cu, 0), Vector2((v + 1) * cu, 0), Vector2((v + 1) * cu, 1), Vector2(v * cu, 1)])
			draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, atlas)
