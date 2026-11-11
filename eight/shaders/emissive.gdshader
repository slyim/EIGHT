shader_type canvas_item;
render_mode unshaded;
// PLACEHOLDER-tunable emission. Eyes sample the original texture, before hit/tint modulation.
uniform int mode = 0; // 0: keyed eyes, 1: cool light, 2: red ammunition
uniform float energy : hint_range(0.0, 12.0) = 4.0;
uniform vec4 light_color : source_color = vec4(0.792, 0.922, 0.878, 1.0);
uniform float tolerance : hint_range(0.0, 0.2) = 0.025;
instance uniform vec4 eye_bounds = vec4(19.0, 15.0, 22.0, 17.0);
instance uniform float frame_size = 32.0;
instance uniform bool dark_eyes = false;
instance uniform bool pale_eyes = true;
instance uniform bool mint_eyes = false;
varying vec4 item_color;
void vertex() { item_color = COLOR; }
bool keyed(vec3 color, vec3 key) { return distance(color, key) < tolerance; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 base = tex * item_color;
	if (mode == 0) {
		// Committed placeholder atlases use untrimmed 32/64 px cells, no padding.
		vec2 pixel = mod(floor(UV / TEXTURE_PIXEL_SIZE), vec2(frame_size));
		bool region = all(greaterThanEqual(pixel, eye_bounds.xy)) && all(lessThan(pixel, eye_bounds.zw));
		// Texture samples are linear under HDR 2D; palette keys below are linear too.
		bool eye = (dark_eyes && keyed(tex.rgb, vec3(0.002125, 0.000304, 0.002732))) || (pale_eyes && keyed(tex.rgb, vec3(0.791298, 0.760525, 0.341914)));
		eye = eye || (mint_eyes && keyed(tex.rgb, vec3(0.590619, 0.83077, 0.745404)));
		if (region && eye && tex.a > 0.5) base.rgb = vec3(energy, 0.015, 0.025);
	} else if (mode == 1) {
		base.rgb *= light_color.rgb * energy;
	} else {
		float value = max(max(tex.r, tex.g), tex.b);
		base.rgb = vec3(energy, 0.025, 0.04) * (0.35 + 0.65 * value);
	}
	COLOR = base;
}
