shader_type canvas_item;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	float circle = 1.0 - smoothstep(0.40, 0.49, length(UV - vec2(0.5)));
	vec4 pig = texture(TEXTURE, vec2(0.375, 0.29) + UV * vec2(0.18, 0.34));
	COLOR = vec4(mix(pig.rgb, vec3(0.72, 0.54, 1.0), 0.18), circle * 0.84) * tint;
}
