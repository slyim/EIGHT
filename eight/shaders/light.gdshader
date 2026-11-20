shader_type canvas_item;
render_mode blend_add, unshaded;
#include "res://shaders/canvas_color.gdshaderinc"
// PLACEHOLDER-tunable falloff for one light quad drawn by lights.gd. The quad's colour is
// the light colour; its alpha is energy / ENERGY_MAX (alpha is not gamma converted).
const float ENERGY_MAX = 4.0;
// Two-tone light: the inner core leans toward white while the skirt keeps the pure colour,
// so a pool reads hot at the centre. 0 (the default) is single-tone; the ULTRA setting uses 0.55.
uniform float core_whiten : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	// The light buffer stores linear intensity in both renderers.
	vec2 offset = UV * 2.0 - 1.0;
	float reach = max(0.0, 1.0 - dot(offset, offset));
	float core = smoothstep(0.58, 0.95, reach);
	vec3 tint = mix(canvas_to_linear(COLOR.rgb), vec3(1.0), core * core_whiten);
	float falloff = reach * reach * reach * (0.55 + 0.45 * reach);
	COLOR = vec4(tint * COLOR.a * ENERGY_MAX * falloff, 1.0);
}
