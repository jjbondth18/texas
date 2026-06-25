shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.32, 0.86, 1.0, 1.0);
uniform float glow_strength = 0.5;
uniform float pulse_speed = 0.7;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	vec3 glow = tint.rgb * (glow_strength + pulse * 0.25);
	COLOR = vec4(max(tex.rgb, glow * tex.a), tex.a * tint.a);
}
