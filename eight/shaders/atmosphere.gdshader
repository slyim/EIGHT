shader_type canvas_item;
render_mode unshaded, blend_disabled;
// PLACEHOLDER-tunable: one screen sample and two slow waves, no noise texture.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.16;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.06;
uniform float haze_strength : hint_range(0.0, 0.2) = 0.012;
uniform float drift_speed : hint_range(0.0, 1.0) = 0.025;
void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	vec2 p = SCREEN_UV;
	float edge = smoothstep(0.18, 0.72, length(p - 0.5));
	float haze = (sin(p.x * 12.0 + p.y * 7.0 + TIME * drift_speed) * sin(p.y * 17.0 - TIME * drift_speed * 0.7) + 1.0) * 0.5;
	// Multiplicative grade preserves stage tints; bright gameplay signals keep their hue.
	float shadow = 1.0 - smoothstep(0.12, 0.7, max(max(scene.r, scene.g), scene.b));
	vec3 graded = scene * mix(vec3(1.0), vec3(0.94, 0.87, 1.0), grade_strength * strength * shadow);
	graded *= 1.0 - edge * vignette_strength * strength;
	graded += vec3(0.30, 0.20, 0.42) * haze * haze_strength * strength * shadow;
	COLOR = vec4(graded, 1.0);
}
