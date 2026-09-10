shader_type canvas_item;
render_mode unshaded;
uniform vec4 spots[4]; // Authored room position and ellipse radii.
uniform float strengths[4];
uniform float clock = 0.0;
varying vec2 room_position;
void vertex() { room_position = VERTEX; }
void fragment() {
 float light = 0.0;
 for (int i = 0; i < 4; i++) {
  vec2 radius = max(spots[i].zw, vec2(1.0));
  float distance_to_spot = length((room_position - spots[i].xy) / radius);
  float falloff = 1.0 - smoothstep(0.25, 1.35, distance_to_spot);
  float breath = 0.96 + 0.04 * sin(clock * 1.65 + float(i));
  light = max(light, falloff * strengths[i] * breath);
 }
 // Transparent pools reveal the original painted colours without bleaching them.
 COLOR = vec4(vec3(0.055, 0.065, 0.10), 0.50 * (1.0 - light));
}
