shader_type canvas_item;
// Gentle wind sway for trees, palms and their shadows: the top moves, the base stays.
uniform float strength = 2.5;     // pixels at the very top
uniform float speed = 1.3;
uniform float phase = 0.0;

void vertex() {
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * speed + phase) * strength * top * top
		+ sin(TIME * speed * 2.3 + phase * 1.7) * strength * 0.3 * top;
}
