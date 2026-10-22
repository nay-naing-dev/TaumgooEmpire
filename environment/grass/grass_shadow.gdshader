shader_type canvas_item;
render_mode unshaded;
// Shadows of the grass tufts on the ground. They sway and bend with the grass.
#include "res://environment/fx/wind.gdshaderinc"

global uniform vec2 shadow_dir;

uniform vec4 shadow_color : source_color = vec4(0.02, 0.06, 0.04, 0.32);
uniform float tuft_height = 38.0;
uniform float sway = 1.4;
uniform float gust_lean = 3.0;
uniform float bend = 11.0;
uniform vec3 bend_a = vec3(0.0);
uniform vec3 bend_b = vec3(0.0);

float push(vec3 b, vec2 r) {
	if (b.z <= 0.0) return 0.0;
	vec2 d = r - b.xy;
	d.y *= 2.0;
	return (1.0 - smoothstep(b.z * 0.3, b.z, length(d))) * (d.x >= 0.0 ? 1.0 : -1.0);
}

void vertex() {
	float top = 1.0 - UV.y;
	vec2 wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	vec2 root = wp - shadow_dir * top * tuft_height;
	float g = wind_gust(root);
	float ph = fract(sin(dot(floor(root), vec2(12.9898, 78.233))) * 43758.5453) * 6.2831853;
	float s = sin(TIME * 1.9 + ph) * sway * (0.6 + g) + g * gust_lean;
	float p = push(bend_a, root) + push(bend_b, root);
	VERTEX.x += (s + p * bend) * top * top * 0.8;
}

void fragment() {
	COLOR = vec4(shadow_color.rgb, texture(TEXTURE, UV).a * shadow_color.a);
}
