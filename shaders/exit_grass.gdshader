shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/ground_light_profile.gdshaderinc"

void fragment() {
  vec2 grass_position = ground_world_position - MODEL_MATRIX[3].xz;
  float noise = ground_noise(grass_position * 1.2);
  float fade = smoothstep(-6.0, 1.0, -grass_position.y + (noise - 0.5) * 2.0);
  float grain = floor(noise * 5.0) / 4.0;
  ALBEDO = mix(vec3(0.27, 0.40, 0.13), vec3(0.48, 0.57, 0.25), grain);
  EMISSION = ALBEDO * 0.10;
  ALPHA = fade;
}

void light() {
  float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL, SPECULAR_AMOUNT);
  DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
