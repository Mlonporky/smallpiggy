shader_type canvas_item;
uniform float warmth : hint_range(0.0,1.0) = 0.0;
uniform bool manor = false;
uniform float restoration_time = 10.0;
uniform float water_clock = 0.0;
float oval(vec2 uv, vec2 center, vec2 radius) {
 return 1.0-smoothstep(0.80,1.0,length((uv-center)/radius));
}
void fragment(){
 vec4 tex = texture(TEXTURE,UV);
 float gray = dot(tex.rgb,vec3(0.299,0.587,0.114));
 vec3 cursed = mix(vec3(gray)*vec3(0.34,0.33,0.49),tex.rgb*vec3(0.45,0.47,0.62),0.25);
 float reveal = warmth;
 if(manor){
  // Masks follow the unchanged 1672x941 background: restore its painted detail.
  float windows=max(oval(UV,vec2(.579,.393),vec2(.012,.025)),oval(UV,vec2(.822,.391),vec2(.014,.028)));
  windows=max(windows,oval(UV,vec2(.694,.399),vec2(.010,.020)));
  windows=max(windows,oval(UV,vec2(.943,.389),vec2(.007,.018)));
  float lanterns=max(oval(UV,vec2(.645,.381),vec2(.008,.019)),oval(UV,vec2(.729,.381),vec2(.008,.019)));
  lanterns=max(lanterns,oval(UV,vec2(.175,.575),vec2(.015,.041)));
  float lamps=max(windows,lanterns);
  float lamp_stage=smoothstep(1.2,3.0,restoration_time);
  // Broad feathered garden regions preserve the original brushwork. Per-pixel
  // hue selection created harsh yellow outlines around individual leaves.
  float plants=smoothstep(.43,.66,UV.y);
  plants=max(plants,(1.0-smoothstep(.35,1.0,length((UV-vec2(.12,.43))/vec2(.20,.15))))*.85);
  plants=max(plants,(1.0-smoothstep(.35,1.0,length((UV-vec2(.875,.30))/vec2(.12,.14))))*.85);
  float plant_stage=smoothstep(3.0,5.1,restoration_time);
  float water=oval(UV,vec2(.262,.484),vec2(.064,.032));
  plants*=1.0-water;
  float water_stage=smoothstep(5.0,6.5,restoration_time);
  float sky_color=max(smoothstep(.0,.13,tex.b-tex.r*.9),smoothstep(.65,.88,gray));
  float sky=(1.0-smoothstep(.22,.31,UV.y))*sky_color;
  // The roof occupies the right side, so keep its warm plaster out of the sky mask.
  sky*=1.0-smoothstep(.53,.62,UV.x)*smoothstep(.07,.12,UV.y);
  float sky_stage=smoothstep(7.4,9.4,restoration_time);
  float daylight=smoothstep(7.8,10.0,restoration_time);
  reveal=max(daylight,max(lamps*lamp_stage,max(plants*plant_stage,max(water*water_stage,sky*sky_stage))));
  cursed=mix(cursed,vec3(gray)*vec3(.24,.23,.31),lamps*.75);
  vec3 color=mix(cursed,tex.rgb,reveal);
  float glint=pow(max(0.0,sin(UV.y*1100.0+sin(UV.x*180.0+water_clock)*2.0)),12.0);
  color+=vec3(1.0,.87,.62)*water*water_stage*glint*.045;
  COLOR=vec4(color,tex.a);
 } else {
  COLOR = vec4(mix(cursed,tex.rgb,reveal),tex.a);
 }
}
