shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.006, 0.008, 0.018, 1.0);
uniform vec4 haze_color : source_color = vec4(0.18, 0.28, 0.75, 1.0);
uniform vec4 neon_color : source_color = vec4(1.0, 0.18, 0.62, 1.0);
uniform float speed = 0.012;
uniform float intensity = 0.22;
uniform bool motion_enabled = true;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	float t = motion_enabled ? TIME * speed : 0.0;
	float n = noise(uv * 4.0 + vec2(t, -t * 0.7));
	float band = smoothstep(0.35, 0.92, sin((uv.x + uv.y * 0.6 + t) * 8.0) * 0.5 + 0.5);
	vec4 color = mix(deep_color, haze_color, n * intensity);
	color = mix(color, neon_color, band * n * 0.055);
	COLOR = color;
}
