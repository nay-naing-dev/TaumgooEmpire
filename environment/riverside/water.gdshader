shader_type canvas_item;
render_mode unshaded;
// Realistic pixel-art river. Waves, depth, sunset sky reflection, sun glints,
// shadow of the quay wall and foam where the water hits the stone.

uniform float edge_c = 113.0;      // water line: y = 0.5 * x + edge_c (world pixels)
uniform vec4 shallow : source_color = vec4(0.22, 0.36, 0.42, 1.0);
uniform vec4 deep : source_color = vec4(0.07, 0.15, 0.24, 1.0);
uniform vec4 sky : source_color = vec4(0.98, 0.62, 0.45, 1.0);
uniform vec4 foam_color : source_color = vec4(0.86, 0.93, 0.95, 1.0);
uniform vec3 sun_dir = vec3(0.55, -0.6, 0.55);
uniform float flow_speed = 1.0;
uniform float color_levels = 16.0;  // fewer = more "pixel art"

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float waves(vec2 p, float t) {
	vec2 flow = vec2(0.894, 0.447);                       // the river runs along the quay
	vec2 q = vec2(dot(p, flow), dot(p, vec2(-flow.y, flow.x)));   // rotate into river space
	float h = noise(q * vec2(0.045, 0.16) - vec2(t * 0.9, 0.0)) * 0.55;
	h += noise(q * vec2(0.11, 0.33) - vec2(t * 1.6, t * 0.2) + 7.0) * 0.3;
	h += noise(q * vec2(0.35, 0.7) + vec2(t * 0.8, -t * 0.5) + 3.0) * 0.15;
	return h;
}
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0., 8., 2., 10., 12., 4., 14., 6., 3., 11., 1., 9., 15., 7., 13., 5.);
	return m[i] / 16.0 - 0.5;
}

void fragment() {
	vec2 p = floor(wpos);
	float t = TIME * flow_speed;
	float dist = (p.y - (0.5 * p.x + edge_c)) * 0.894;    // distance from the quay wall

	float h = waves(p, t);
	float hx = waves(p + vec2(1.0, 0.0), t) - h;
	float hy = waves(p + vec2(0.0, 1.0), t) - h;
	vec3 n = normalize(vec3(-hx * 9.0, -hy * 9.0, 1.0));

	float depth = smoothstep(0.0, 160.0, dist);
	vec3 c = mix(shallow.rgb, deep.rgb, depth);

	// sky reflection: stronger where waves tilt toward us and further from the wall
	float fres = clamp(0.2 + 0.45 * depth + n.y * 1.8, 0.0, 1.0);
	c = mix(c, sky.rgb * 0.7 + deep.rgb * 0.3, fres * 0.5);

	// wave light and shade
	vec3 L = normalize(sun_dir);
	c *= 0.82 + 0.3 * clamp(dot(n, L), 0.0, 1.0);

	// sun glints
	vec3 V = normalize(vec3(0.0, 0.55, 0.85));
	vec3 Hh = normalize(L + V);
	float spec = pow(max(dot(n, Hh), 0.0), 70.0);
	c += vec3(1.0, 0.85, 0.65) * step(0.82, spec) * step(30.0, dist) * 0.45;

	// the quay wall shades the water right next to it
	c *= mix(0.6, 1.0, smoothstep(0.0, 14.0, dist));

	// foam: lapping strip along the wall + small whitecaps on wave crests
	float fn = noise(vec2(p.x * 0.18 - t * 1.4, p.y * 0.35 + t * 0.6));
	float foam = step(dist, 1.5 + fn * 5.0) * step(0.32, fn);
	foam = max(foam, step(0.93, h) * step(0.7, noise(p * 0.3 + t)) * step(24.0, dist) * 0.6);
	c = mix(c, foam_color.rgb, foam * 0.85);

	// pixel-art finish: ordered dithering + limited colour steps
	c = floor(c * color_levels + 0.5 + bayer4(p) * 0.6) / color_levels;
	COLOR = vec4(c, 1.0);
}
