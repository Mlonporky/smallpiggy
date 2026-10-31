shader_type canvas_item;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float edge = smoothstep(0.38,1.38,length(p*vec2(0.80,1.0)));
 COLOR = vec4(0.18,0.115,0.085,edge*0.28);
}
