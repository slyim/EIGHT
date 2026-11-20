shader_type canvas_item;
// Church stained glass for the team's flat vector artworks, shaded with colour only (no cracks):
// every flat colour region of the art is one pane and the art's own dark outlines are its lead.
// Each pane is lit from within (bright, saturated centre falling to a deeper rim beside the lead),
// with soft light from above and a faint mottle in the glass. Plain math only, so Forward+ and
// Compatibility (Web) render it the same.

uniform float rim_px = 9.0; // How far the deeper rim reaches into a pane, in texture pixels.
uniform float rim_depth = 0.34; // How much darker the rim is than the lit centre.
uniform float glow = 0.28; // Extra light in the middle of each pane.
uniform float saturation = 1.25;
uniform float dark_floor = 0.22; // Brightest channel of the darkest glass: backlit glass is never black.
uniform float top_light = 0.16; // Light falling from above the window.
uniform float mottle = 0.05; // Uneven thickness of old glass.
uniform vec4 lead_color : source_color = vec4(0.078, 0.031, 0.102, 1.0); // Abyss #14081a.
uniform float sweep_strength = 0.0; // A slow light band crossing the glass; 0 = still.
uniform float sweep_speed = 0.12;

varying vec4 modulate; // Vertex colour (node modulate), since fragment COLOR already holds the texture.

void vertex() {
	modulate = COLOR;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 15731.743);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// 1 where this sampled colour is opaque and in the same pane as `centre`.
float same(vec4 c, vec3 centre) {
	return step(0.5, c.a) * step(distance(c.rgb, centre), 0.08);
}

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	float luma = dot(art.rgb, vec3(0.299, 0.587, 0.114));
	float is_lead = step(luma, 0.04); // The art's near-black outlines are the lead.
	// How deep inside its pane this pixel is: the share of two rings around it in the same colour
	// (1 deep inside, about 0.5 on a straight edge).
	float inside = 0.0;
	for (int i = 0; i < 12; i++) {
		float a = float(i) * 0.5236;
		vec2 dir = vec2(cos(a), sin(a)) * TEXTURE_PIXEL_SIZE;
		inside += same(texture(TEXTURE, UV + dir * rim_px * 0.45), art.rgb);
		inside += same(texture(TEXTURE, UV + dir * rim_px), art.rgb);
	}
	float depth = smoothstep(0.45, 1.0, inside / 24.0);

	vec3 glass = art.rgb;
	float peak = max(glass.r, max(glass.g, glass.b));
	glass = mix(glass, glass / max(peak, 0.001) * dark_floor, 1.0 - smoothstep(0.0, dark_floor, peak));
	float grey = dot(glass, vec3(0.333));
	glass = mix(vec3(grey), glass, saturation);

	float shade = 1.0 - rim_depth * (1.0 - depth) + glow * depth * depth;
	shade += top_light * (0.5 - UV.y);
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	shade += mottle * (noise(px / 26.0) + 0.5 * noise(px / 9.0) - 0.75);
	if (sweep_strength > 0.0) {
		float band = fract(TIME * sweep_speed) * 2.6 - 0.8;
		float d = (UV.x + UV.y) * 0.5 - band;
		shade += sweep_strength * exp(-d * d * 90.0);
	}
	// The brightest glass warms slightly toward white, like light burning through it.
	vec3 lit = glass * shade + vec3(0.12, 0.1, 0.06) * max(0.0, shade - 1.0);
	lit = mix(lit, mix(lead_color.rgb, art.rgb, 0.35), is_lead);
	COLOR = vec4(lit, art.a) * modulate;
}
