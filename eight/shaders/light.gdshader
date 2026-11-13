shader_type canvas_item;
render_mode blend_add, unshaded;
// PLACEHOLDER-tunable falloff for one light quad drawn by lights.gd. The quad's colour is
// the light colour; its alpha is energy / ENERGY_MAX (alpha is not gamma converted).
const float ENERGY_MAX = 4.0;
void fragment() {
	// A bright core with a wide skirt that reaches zero smoothly at the quad's edge.
	vec2 offset = UV * 2.0 - 1.0;
	float reach = max(0.0, 1.0 - dot(offset, offset));
	COLOR = vec4(COLOR.rgb * COLOR.a * ENERGY_MAX * reach * reach * reach, 1.0);
}
