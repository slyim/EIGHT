shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/canvas_color.gdshaderinc"
// PLACEHOLDER-tunable light palette. Pixels painted in `key` glow as `glow` x `energy`; the
// key is matched on the original texture, so hit flashes and tints cannot switch a glow off.
// `whole` is for things made of light (spear, bow, arrows, shots): every pixel glows.
uniform vec4 key : source_color = vec4(0.902, 0.886, 0.62, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.03, 0.05, 1.0);
// Optional second palette entry (the angel's cream halo); alpha 0 switches it off.
uniform vec4 key2 : source_color = vec4(0.0);
uniform vec4 glow2 : source_color = vec4(1.0);
uniform float energy : hint_range(0.0, 12.0) = 2.5;
uniform float tolerance : hint_range(0.0, 0.2) = 0.025;
uniform bool whole = false;
uniform float reflected_light : hint_range(0.0, 0.1) = 0.0;
// Glow pulse: the keyed glow swells by up to `pulse` and back, stepped every `pulse_step`
// seconds so it changes in visible beats rather than smoothly. 0 is a steady glow.
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed = 3.0;
uniform float pulse_step = 0.1;
varying vec4 item_color;
void vertex() { item_color = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 ink = canvas_to_linear(tex.rgb);
	vec3 base = ink * canvas_to_linear(item_color.rgb);
	vec3 tint = canvas_to_linear(glow.rgb);
	float beat = pulse > 0.0 ? 1.0 + pulse * sin(floor(TIME / pulse_step) * pulse_step * pulse_speed) : 1.0;
	if (whole) {
		base *= tint * energy;
	} else if (tex.a > 0.5 && distance(ink, canvas_to_linear(key.rgb)) < tolerance) {
		base = tint * energy * beat;
	} else if (tex.a > 0.5 && key2.a > 0.5 && distance(ink, canvas_to_linear(key2.rgb)) < tolerance) {
		base = canvas_to_linear(glow2.rgb) * energy;
	} else {
		base += tint * reflected_light * (1.0 - smoothstep(0.03, 0.22, max(ink.r, max(ink.g, ink.b))));
	}
	// Keep saturated eyes and ammunition distinct when the canvas clips its highlights.
	base /= max(1.0, max(base.r, max(base.g, base.b)) / 1.45);
	COLOR = vec4(linear_to_canvas(base), tex.a * item_color.a);
}
