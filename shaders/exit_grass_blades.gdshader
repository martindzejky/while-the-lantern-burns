shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 blade_color : source_color = vec4(0.36, 0.48, 0.17, 1.0);

void vertex() {
  vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
  float wind = sin(TIME * 1.8 + world_position.x * 0.45 + world_position.z * 0.3);
  VERTEX.x += wind * VERTEX.y * VERTEX.y * 0.14;
}

void fragment() {
  ALBEDO = blade_color.rgb;
  EMISSION = blade_color.rgb * 0.12;
}

void light() {
  DIFFUSE_LIGHT += max(ATTENUATION, 0.0) * LIGHT_COLOR / PI;
}
