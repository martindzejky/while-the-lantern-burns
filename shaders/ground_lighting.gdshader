shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/ground_light_profile.gdshaderinc"

uniform sampler2D ground_texture : source_color;

void fragment() {
  ALBEDO = texture(ground_texture, UV).rgb * COLOR.rgb;
}

void light() {
  float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
  DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
