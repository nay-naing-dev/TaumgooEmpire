shader_type canvas_item;
// Rice paddies: the flooded plots shimmer with sky reflection and small ripples,
// and the young rice sways a little in the wind.
#include "res://environment/fx/wind.gdshaderinc"

uniform sampler2D water_mask : filter_nearest;   // R/A = flooded water
uniform vec4 sky : source_color = vec4(1.0, 0.93, 0.82, 1.0);
uniform float shimmer = 0.22;
uniform float sparkle = 0.6;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 p = floor(UV / TEXTURE_PIXEL_SIZE);
	float w = texture(water_mask, UV).a;
	vec2 uv = UV;
	vec4 c = texture(TEXTURE, uv);
	if (w > 0.5) {
		// rice sprouts (green pixels) lean with the wind; water ripples under them
		float g = wind_gust(p * 2.0);
		float n = noise(p * vec2(0.12, 0.25) + vec2(TIME * 0.4, TIME * 0.15));
		vec4 c2 = texture(TEXTURE, UV + vec2(round(sin(TIME * 2.0 + p.y * 0.3) * (0.4 + g)) , 0.0) * TEXTURE_PIXEL_SIZE);
		if (c2.g > c2.b + 0.04) c = c2;
		float band = smoothstep(0.55, 0.9, n);
		c.rgb = mix(c.rgb, sky.rgb, shimmer * (0.4 + band));
		float s = step(0.985, hash(p + floor(TIME * 1.5))) * step(0.6, n);
		c.rgb += vec3(1.0, 0.95, 0.85) * s * sparkle;
	}
	COLOR = c * COLOR;
}
