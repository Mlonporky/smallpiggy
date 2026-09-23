shader_type canvas_item;
render_mode unshaded;
uniform vec2 light_position = vec2(400.0, 700.0);
uniform float radius = 260.0;
uniform float strength = 1.0;
void fragment() {
    vec2 p = UV * vec2(1536.0, 1024.0);
    float d = length((p - light_position) * vec2(1.0, 1.15));
    float light = (1.0 - smoothstep(30.0, radius, d)) * strength;
    COLOR = vec4(vec3(0.003, 0.005, 0.009), 0.992 - light * 0.91);
}
