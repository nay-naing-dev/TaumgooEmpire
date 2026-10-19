shader_type canvas_item;
render_mode unshaded;
// Upside-down copy of an object, wobbling on the water.

uniform float wobble_pixels = 1.5;
uniform vec4 tint : source_color = vec4(0.45, 0.55, 0.65, 1.0);
uniform float tint_amount = 0.45;
uniform float opacity = 0.5;

varying vec2 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }

void fragment() {
	vec2 px = floor(wpos);
	float w = sin(px.y * 0.65 + TIME * 2.4) * 0.6 + sin(px.y * 0.21 - TIME * 1.6) * 0.6;
	vec2 uv = UV + vec2(floor(w * wobble_pixels + 0.5) * TEXTURE_PIXEL_SIZE.x, 0.0);
	vec4 c = texture(TEXTURE, uv);
	// little horizontal gaps, like light broken by ripples
	float gap = step(0.8, fract(sin(px.y * 12.9898 + floor(px.x / 5.0 + TIME * 2.0) * 4.1) * 43758.5));
	c.rgb = mix(c.rgb, tint.rgb, tint_amount);
	c.a *= opacity * (1.0 - gap * 0.7);
	COLOR = c;
}
