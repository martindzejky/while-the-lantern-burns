// profile: inner radius, brightness before step, after step, at outer edge.
const vec4 MINIMUM_LIGHT_PROFILE = vec4(0.3, 0.94, 0.8, 0.3);
const vec4 FULL_LIGHT_PROFILE = vec4(0.4, 0.94, 0.8, 0.3);
// total width of the inner transition, as a fraction of the light radius.
const float INNER_TRANSITION_WIDTH = 0.03;

float ground_light_profile(float attenuation, vec3 light_color, bool directional) {
  if (directional) {
    return step(0.001, attenuation);
  }
  // invert Godot's (1 - distance^4)^2 range falloff with omni_attenuation = 0.
  // zero attenuation includes real cast shadows, so they remain completely dark.
  float radius = pow(max(1.0 - sqrt(clamp(attenuation, 0.0, 1.0)), 0.0), 0.25);
  float energy = max(light_color.r, max(light_color.g, light_color.b)) / PI;
  float charge = clamp((energy - 0.15) / (1.1 - 0.15), 0.0, 1.0);
  vec4 profile = mix(MINIMUM_LIGHT_PROFILE, FULL_LIGHT_PROFILE, charge);
  float inner = mix(1.0, profile.y, clamp(radius / profile.x, 0.0, 1.0));
  float outer = mix(profile.z, profile.w, clamp((radius - profile.x) / (1.0 - profile.x), 0.0, 1.0));
  float half_width = max(INNER_TRANSITION_WIDTH * 0.5, 0.0001);
  float transition = smoothstep(profile.x - half_width, profile.x + half_width, radius);
  return mix(inner, outer, transition) * step(0.001, attenuation);
}
