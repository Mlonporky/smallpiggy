shader_type canvas_item;
// Chapter 1 uses blur=0.025. This glimpse preserves a hazy pink identity
// while revealing the pickup gesture and pendant.
uniform float blur = 0.0033;
uniform float clarity_alpha = 0.82;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
 vec4 sample_color = vec4(0.0);
 for (int y=-1; y<=1; y++) {
  for (int x=-1; x<=1; x++) {
   sample_color += texture(TEXTURE,UV+vec2(float(x),float(y))*blur);
  }
 }
 sample_color /= 9.0;
 sample_color.rgb = mix(sample_color.rgb,vec3(1.0,0.76,0.80),0.24);
 COLOR = sample_color*tint;
 COLOR.a *= clarity_alpha;
}
