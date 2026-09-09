shader_type canvas_item;
uniform float blur = 0.025;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	vec4 result = vec4(0.0);
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			result += texture(TEXTURE, UV + vec2(float(x), float(y)) * blur);
		}
	}
	COLOR = tint * result / 25.0;
}
