shader_type canvas_item;
// Living Yangon harbour. The mask texture says where each effect goes:
//   red   = river water   -> moving waves, highlights, sunset glints
//   green = pagoda gold   -> a slow shine sweeping across the gold + sparkles
//   blue  = sunset sky    -> soft warm pulse and drifting light

uniform sampler2D fx_mask : filter_nearest;
uniform vec2 image_size = vec2(1408.0, 768.0);

uniform float wave_speed = 1.0;
uniform float wave_highlight = 0.22;
uniform float ripple_pixels = 1.0;
uniform float glint_amount = 0.75;
uniform float gold_shine = 0.55;
uniform float sky_glow = 0.08;
uniform vec2 sun_pos = vec2(1330.0, 215.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = floor(UV * image_size);
	vec3 m = texture(fx_mask, UV).rgb;
	float t = TIME * wave_speed;

	// ---------- WATER: sideways ripple of the painted water (pixel-snapped)
	vec2 uv = UV;
	float wob = sin(px.y * 0.55 + t * 2.4) * 0.6 + sin(px.y * 0.19 - t * 1.4 + px.x * 0.01) * 0.6;
	uv.x += floor(wob * ripple_pixels + 0.5) / image_size.x * step(0.5, m.r);
	vec4 col = texture(TEXTURE, uv);

	// long horizontal wave bands drifting towards the shore (pixel-art "realistic" water)
	vec2 wp = vec2(px.x / 26.0 + t * 0.35, px.y / 4.0 - t * 0.25);
	float w1 = noise(wp);
	float w2 = noise(wp * vec2(0.5, 1.3) + vec2(-t * 0.2, 7.3));
	float crest = smoothstep(0.68, 0.9, w1 * 0.65 + w2 * 0.45);
	float trough = smoothstep(0.35, 0.1, w1);
	// waves closer to the camera (lower on screen) are brighter, like real perspective
	float depth = smoothstep(470.0, 768.0, px.y);
	vec3 sky_tint = mix(vec3(1.0, 0.72, 0.55), vec3(0.75, 0.9, 1.0), depth);   // sunset near, sky blue far
	col.rgb += m.r * crest * wave_highlight * (0.6 + 0.6 * depth) * sky_tint;
	col.rgb -= m.r * trough * 0.05;

	// sunset glints twinkling on the water
	vec2 cell = floor(px / vec2(4.0, 2.0));
	float gt = t * 1.3 + hash(cell) * 6.28;
	float glint = step(0.988, hash(cell + floor(gt))) * (0.5 + 0.5 * sin(gt * 6.28));
	col.rgb += m.r * glint * glint_amount * vec3(1.0, 0.8, 0.55);

	// ---------- PAGODA GOLD: a slow shine sweeping across
	float s = fract((px.x * 0.8 + px.y - TIME * 70.0) / 520.0);
	float band = smoothstep(0.0, 0.025, s) * (1.0 - smoothstep(0.025, 0.07, s));
	col.rgb += m.g * band * gold_shine * vec3(1.0, 0.92, 0.65);
	vec2 gc = floor(px / 3.0);
	float gt2 = TIME * 1.1 + hash(gc + 3.1) * 6.28;
	col.rgb += m.g * step(0.992, hash(gc + floor(gt2))) * (0.5 + 0.5 * sin(gt2 * 6.28)) * 0.6;

	// ---------- SKY: warm pulse + slow drifting light
	float drift = noise(vec2((px.x + TIME * 8.0) / 60.0, px.y / 16.0));
	col.rgb += m.b * (sky_glow * (0.5 + 0.5 * sin(TIME * 0.5)) + drift * 0.05) * vec3(1.0, 0.65, 0.45);

	// ---------- SUN glow behind the city
	float d = length((px - sun_pos) * vec2(0.6, 1.0));
	col.rgb += vec3(1.0, 0.6, 0.3) * 0.22 * exp(-d / 110.0) * (0.85 + 0.15 * sin(TIME * 0.8));

	COLOR = col;
}
