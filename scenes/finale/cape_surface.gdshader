shader_type canvas_item;
render_mode unshaded;
uniform vec2 sheet_size;
uniform float seconds = 0.0;
uniform float strength = 0.0;
void vertex() {
 vec2 source = UV * sheet_size;
 // Only the free outer cloth. Face, collar, torso, tail and attachment stay fixed.
 float weight = (1.0-smoothstep(225.0,380.0,source.x)) * smoothstep(485.0,560.0,source.y) * (1.0-smoothstep(680.0,710.0,source.y));
 float wave = sin(seconds*2.6 + source.y*.013);
 VERTEX += vec2(-7.0, -12.0) * weight * strength * (.55+.45*wave);
}
