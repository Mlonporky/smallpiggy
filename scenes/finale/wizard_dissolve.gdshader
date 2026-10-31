shader_type canvas_item;
uniform vec2 actor_origin = vec2(0.0);
uniform vec2 actor_extent = vec2(260.0,220.0);
uniform float appear : hint_range(0.0,1.0) = 1.0;
uniform float dissolve : hint_range(0.0,1.0) = 0.0;
uniform float joy_light : hint_range(0.0,1.0) = 0.0;
varying vec2 local_uv;
float grain(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float soft_grain(vec2 p) {
 vec2 cell=floor(p), f=fract(p);
 f=f*f*(3.0-2.0*f);
 return mix(mix(grain(cell),grain(cell+vec2(1,0)),f.x),mix(grain(cell+vec2(0,1)),grain(cell+vec2(1,1)),f.x),f.y);
}
void vertex() {
 local_uv=((MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy-actor_origin)/actor_extent;
}
void fragment() {
 vec4 tex=texture(TEXTURE,UV);
 float noise=soft_grain(local_uv*vec2(70.0,60.0));
 float threshold=clamp(0.62*(1.0-local_uv.y)+0.38*noise,0.02,0.98);
 float remain=1.0-smoothstep(threshold-0.028,threshold+0.028,dissolve);
 if(dissolve<=0.0) remain=1.0;
 if(dissolve>=1.0) remain=0.0;
 float edge=(1.0-smoothstep(0.0,0.045,abs(threshold-dissolve)))*step(0.001,dissolve);
 float arrival=smoothstep(1.0-appear-0.08,1.0-appear+0.06,local_uv.y);
 if(appear>=1.0) arrival=1.0;
 if(appear<=0.0) arrival=0.0;
 vec3 lit=mix(tex.rgb,vec3(1.0,0.88,0.63),joy_light*0.25+edge*0.55);
 COLOR=vec4(lit,tex.a*remain*arrival);
}
