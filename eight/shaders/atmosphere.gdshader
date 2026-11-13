shader_type canvas_item;
render_mode unshaded, blend_disabled;
// PLACEHOLDER-tunable: one screen sample, a grade, a vignette, and world-anchored haze.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.16;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.06;
// Haze: drifting fog patches pinned to the world (they do not slide with the camera), read
// once per art pixel, stepped in time and dithered into a few levels like the lighting, so
// it never shimmers below the pixel grid. 0 switches it off.
uniform float haze_strength : hint_range(0.0, 0.3) = 0.18;
// World units per fog cell, noise cells drifted per second, and seconds per time step.
uniform float haze_scale = 180.0;
uniform float drift_speed : hint_range(0.0, 1.0) = 0.06;
uniform float haze_step = 0.125;
uniform float haze_levels = 4.0;
uniform float art_pixel = 2.0;
// Set every frame by Run: the world point at the buffer's top-left and the world size it spans.
uniform vec2 world_origin = vec2(0.0);
uniform vec2 world_size = vec2(1280.0, 720.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float bayer(vec2 cell) {
	const float M[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	ivec2 p = ivec2(mod(cell, 4.0));
	return (M[p.y * 4 + p.x] + 0.5) / 16.0;
}

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	float edge = smoothstep(0.18, 0.72, length(SCREEN_UV - 0.5));
	// Multiplicative grade preserves realm tints; bright gameplay signals keep their hue.
	float shadow = 1.0 - smoothstep(0.12, 0.7, max(max(scene.r, scene.g), scene.b));
	vec3 graded = scene * mix(vec3(1.0), vec3(0.94, 0.87, 1.0), grade_strength * strength * shadow);
	graded *= 1.0 - edge * vignette_strength * strength;
	// Lower quality settings switch the haze off; skip its noise entirely then.
	if (haze_strength * strength > 0.0) {
		vec2 cell = floor((world_origin + SCREEN_UV * world_size) / art_pixel);
		float t = floor(TIME / haze_step) * haze_step * drift_speed;
		vec2 at = (cell + 0.5) * art_pixel / haze_scale;
		float haze = value_noise(at + vec2(t, t * 0.6)) * 0.65 + value_noise(at * 2.3 - vec2(t * 1.4, 0.0)) * 0.35;
		haze = clamp(floor(haze * haze_levels + bayer(cell)) / haze_levels, 0.0, 1.0);
		graded += vec3(0.30, 0.20, 0.42) * haze * haze_strength * strength * shadow;
	}
	COLOR = vec4(graded, 1.0);
}
