shader_type canvas_item;
render_mode unshaded;
// Both forms keep their painted proportions and feet. A soft wave of recovered
// warmth replaces their silhouettes; no head/body or limb is warped.
uniform vec2 heart_origin = vec2(0.0);
uniform float visible_height = 165.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool appearing = true;
varying vec2 world_vertex;
void vertex() {
 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
 vec2 at = (world_vertex - heart_origin) / visible_height;
 float grain = sin(at.x * 39.0 + sin(at.y * 23.0)) * sin(at.y * 31.0) * 0.014;
 float distance_from_heart = length(at * vec2(1.12, 1.0)) + grain;
 float wave = progress * 0.86;
 float reveal = 1.0 - smoothstep(wave - 0.045, wave + 0.045, distance_from_heart);
 if (progress <= 0.0) { reveal = 0.0; }
 if (progress >= 1.0) { reveal = 1.0; }
 float rim = (1.0 - smoothstep(0.0, 0.075, abs(distance_from_heart - wave))) * sin(progress * 3.14159265);
 COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.91, 0.62), rim * 0.58);
 COLOR.a *= appearing ? reveal : 1.0 - reveal;
}
