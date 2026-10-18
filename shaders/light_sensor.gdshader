shader_type spatial;
render_mode cull_disabled, specular_disabled, ambient_light_disabled, fog_disabled, depth_test_disabled, depth_draw_never;

#include "res://shaders/ground_light_profile.gdshaderinc"

void fragment() {
  ALBEDO = vec3(1.0);
  // Transparent pass + high render priority draws over scenery, retaining shadows.
  ALPHA = 1.0;
}

void light() {
  float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL, SPECULAR_AMOUNT);
  DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
