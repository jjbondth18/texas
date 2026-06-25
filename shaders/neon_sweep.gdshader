shader_type canvas_item;

uniform vec4 sweep_color : source_color = vec4(1.0, 0.28, 0.78, 0.45); // high-glow magenta sweep
uniform float sweep_width = 0.16;
uniform float sweep_angle = 20.0; // degrees
uniform float sweep_speed = 0.8; // speed of transition
uniform float sweep_interval = 4.0; // wait interval in seconds

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a > 0.0) {
		float cycle_time = mod(TIME, sweep_interval);
		float sweep_duration = 1.0; // sweeps finishes in 1 second
		float progress = cycle_time / sweep_duration;
		
		if (progress <= 1.0) {
			// Sweep from left (-0.4) to right (1.4) to cover slanting
			float x_offset = mix(-0.4, 1.4, progress);
			
			// Slant logic using vertical UV
			float slant = (UV.y - 0.5) * tan(radians(sweep_angle));
			float dist = abs(UV.x - x_offset + slant);
			
			if (dist < sweep_width) {
				float intensity = (1.0 - (dist / sweep_width)) * sweep_color.a;
				color.rgb = mix(color.rgb, sweep_color.rgb, intensity);
			}
		}
	}
	COLOR = color;
}
