shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/ground_light_profile.gdshaderinc"

uniform sampler2D ground_texture : source_color;
uniform float ground_grain_strength : hint_range(0.0, 0.15, 0.005) = 0.045;
uniform float ground_grain_scale : hint_range(0.1, 5.0, 0.1) = 0.65;

void fragment() {
  float broad = floor(ground_noise(ground_world_position * ground_grain_scale) * 5.0) / 4.0;
  float fine = ground_noise(ground_world_position * 28.0);
  float grain = ((broad - 0.5) * 1.6 + (fine - 0.5) * 0.4) * ground_grain_strength;
  ALBEDO = texture(ground_texture, UV).rgb * COLOR.rgb * (1.0 + grain);
}

void light() {
  float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
  DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
