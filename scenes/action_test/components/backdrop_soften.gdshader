shader_type canvas_item;
// Distant painting colour grade: lower contrast and a cool haze, so the far layer reads as depth
// instead of competing with platforms while scrolling. The blur is baked into the texture on load
// (see backdrop.gd), so this stays a single texture sample per pixel.
uniform float haze = 0.34;
uniform vec4 haze_color : source_color = vec4(0.10, 0.17, 0.15, 1.0);
uniform float saturation = 0.70;
uniform float brightness = 0.78;

void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(grey), color, saturation) * brightness;
	// Haze thickens toward the lower part of the painting (deeper cave air).
	float depth = haze * (0.65 + 0.35 * UV.y);
	color = mix(color, haze_color.rgb, depth);
	COLOR = vec4(color, 1.0) * COLOR;
}
