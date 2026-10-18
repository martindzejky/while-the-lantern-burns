uniform sampler2D ground_light_curve : filter_linear, repeat_disable;
uniform sampler2D world_light_curve : filter_linear, repeat_disable;
uniform float light_edge_noise_strength : hint_range(0.0, 0.1, 0.001) = 0.025;
uniform float light_edge_noise_scale : hint_range(0.1, 10.0, 0.1) = 1.8;

varying vec2 ground_world_position;

void vertex() {
  ground_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float ground_hash(vec2 position) {
  return fract(sin(dot(position, vec2(127.1, 311.7))) * 43758.5453);
}

float ground_noise(vec2 position) {
  vec2 cell = floor(position);
  vec2 fraction = fract(position);
  vec2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
  return mix(
    mix(ground_hash(cell), ground_hash(cell + vec2(1.0, 0.0)), blend.x),
    mix(ground_hash(cell + vec2(0.0, 1.0)), ground_hash(cell + vec2(1.0)), blend.x),
    blend.y
  );
}

float ground_light_profile(float attenuation, vec3 light_color, bool directional, float specular_amount) {
  if (directional) {
    return step(0.001, attenuation);
  }
  // invert Godot's range falloff with omni_attenuation = 0; shadows stay dark.
  float radius = pow(max(1.0 - sqrt(clamp(attenuation, 0.0, 1.0)), 0.0), 0.25);
  float edge_noise = ground_noise(ground_world_position * light_edge_noise_scale);
  // only shrink the boundary, keeping light within its actual range and shadows.
  radius += edge_noise * light_edge_noise_strength * radius * radius * radius;
  vec2 curve_uv = vec2(clamp(1.0 - radius, 0.0, 1.0), 0.5);
  // world_light.tscn tags external lights; lantern and musket lights use specular zero.
  float profile = specular_amount > 0.5
    ? texture(world_light_curve, curve_uv).r
    : texture(ground_light_curve, curve_uv).r;
  return profile * step(radius, 1.0) * step(0.001, attenuation);
}
