shader_type canvas_item;
// Brings the painted cave to life. The mask texture says where each effect goes:
//   red   = falling water  -> bright streaks rushing down
//   green = still water    -> ripples + sparkles
//   blue  = sunset sky     -> slow warm glow and drifting light

uniform sampler2D fx_mask : filter_nearest;
uniform vec2 image_size = vec2(768.0, 1367.0);

uniform float fall_speed = 140.0;     // pixels per second the streaks fall
uniform float fall_strength = 0.45;
uniform float ripple_strength = 1.0;  // in pixels
uniform float sparkle_amount = 0.6;
uniform float sky_glow = 0.10;
uniform vec2 sun_pos = vec2(495.0, 372.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = floor(UV * image_size);              // snap to the art's pixel grid
	vec3 m = texture(fx_mask, UV).rgb;

	// --- still water: wobble the picture sideways a little
	vec2 uv = UV;
	float wob = sin(px.y * 0.35 + TIME * 2.2) + sin(px.y * 0.13 - TIME * 1.3);
	uv.x += floor(wob * 0.5 * ripple_strength + 0.5) / image_size.x * m.g;
	vec4 col = texture(TEXTURE, uv);

	// --- waterfall: streaks of light rushing downward
	float lane = floor(px.x / 3.0);
	float streak = noise(vec2(lane * 1.7, (px.y - TIME * fall_speed) / 18.0));
	streak = pow(smoothstep(0.55, 1.0, streak), 2.0);
	float foam = noise(vec2(px.x / 4.0, (px.y - TIME * fall_speed * 1.4) / 6.0));
	col.rgb += m.r * (streak * fall_strength + step(0.86, foam) * 0.18) * vec3(0.75, 0.95, 1.0);

	// --- still water: twinkling sparkles
	vec2 cell = floor(px / 3.0);
	float t = TIME * 1.5 + hash(cell) * 6.28;
	float sp = step(0.985, hash(cell + floor(t))) * (0.5 + 0.5 * sin(t * 6.28));
	col.rgb += m.g * sp * sparkle_amount * vec3(0.8, 1.0, 1.0);
	col.rgb += m.g * 0.04 * sin(TIME * 0.8 + px.x * 0.02);   // gentle breathing glow

	// --- sunset sky: soft warm pulse + light drifting across
	float drift = noise(vec2((px.x + TIME * 6.0) / 40.0, px.y / 14.0));
	col.rgb += m.b * (sky_glow * (0.5 + 0.5 * sin(TIME * 0.6)) + drift * 0.06) * vec3(1.0, 0.6, 0.4);

	// --- sun glow (affects everything near the sun, strongest on the sky)
	float d = length(px - sun_pos);
	col.rgb += vec3(1.0, 0.55, 0.3) * 0.18 * exp(-d / 70.0) * (0.85 + 0.15 * sin(TIME * 0.9));

	COLOR = col;
}
