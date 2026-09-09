shader_type canvas_item;
uniform sampler2D after_image : source_color, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 focus = vec2(0.31, 0.46);
uniform vec2 radius = vec2(0.14, 0.16);
uniform vec2 focus2 = vec2(-10.0);
uniform vec2 radius2 = vec2(0.01);
void fragment() {
	// Localize the change so generated furniture does not swim.
	float mask = 1.0 - smoothstep(0.85, 1.0, length((UV - focus) / radius));
	float second_mask = 1.0 - smoothstep(0.85, 1.0, length((UV - focus2) / radius2));
	mask = max(mask, second_mask);
	COLOR = mix(texture(TEXTURE, UV), texture(after_image, UV), mask * progress);
}
