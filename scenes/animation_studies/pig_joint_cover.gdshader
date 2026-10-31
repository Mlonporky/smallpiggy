shader_type canvas_item;
// Use the intact torso's own alpha as an occluder. No overlay can cover the hand
// or repaint a rectangular seam; only this limb loses pixels behind the torso.
uniform sampler2D torso_texture : filter_linear_mipmap, repeat_disable;
uniform vec2 torso_pivot;
uniform float torso_scale = 0.22;
uniform vec2 part_x;
uniform vec2 part_y;
uniform vec2 part_origin;
uniform float part_scale = 1.0;
uniform float cover_amount = 1.0;
// Negative means the whole leg can tuck behind the torso; positive hides only
// the proximal shoulder, keeping the forearm in front throughout its swing.
uniform float joint_radius = -1.0;
uniform vec2 joint_axis = vec2(0.0,1.0);
uniform vec2 tuck_range;
varying vec2 torso_uv;
varying vec2 joint_offset;
varying vec4 tint;
void vertex() {
 tint = COLOR;
 joint_offset = VERTEX * part_scale;
 vec2 on_torso = part_origin + part_x * VERTEX.x + part_y * VERTEX.y;
 torso_uv = (torso_pivot + on_torso / torso_scale) / vec2(textureSize(torso_texture, 0));
}
void fragment() {
 vec4 painted = texture(TEXTURE, UV) * tint;
 float covered = texture(torso_texture, torso_uv).a;
 if (joint_radius > 0.0) {
  // Hide the complete shoulder cap, including its outer corners. The
  // remaining forearm emerges within the opaque torso, not as a ring.
  covered *= 1.0 - smoothstep(joint_radius, joint_radius + 2.0, dot(joint_offset,joint_axis));
  covered *= cover_amount;
 } else {
  // Retract behind a moving opaque edge, rather than fading a ghost leg over
  // the belly. Only a narrow antialiased boundary blends during the transition.
  float edge = mix(tuck_range.x - 1.0, tuck_range.y + 1.0, cover_amount);
  covered *= 1.0 - smoothstep(edge, edge + 1.0, joint_offset.y);
 }
 painted.a *= 1.0 - covered;
 COLOR = painted;
}
