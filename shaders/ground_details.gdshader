shader_type spatial;
render_mode cull_disabled, specular_disabled, depth_draw_never;

#include "res://shaders/ground_light_profile.gdshaderinc"

uniform sampler2D detail_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
  vec4 detail = texture(detail_texture, UV);
  ALBEDO = detail.rgb;
  ALPHA = detail.a * opacity;
}

void light() {
  float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
  DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
