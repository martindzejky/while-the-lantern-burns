shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_test_disabled, depth_draw_never;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float far_blur_start = 18.0;
uniform float far_blur_end = 26.0;
uniform float blur_radius_pixels = 1.5;

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
  float depth = texture(depth_texture, SCREEN_UV).r;
  #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
  vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
  #else
  vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
  #endif
  vec4 view_position = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  float distance_from_camera = -view_position.z / view_position.w;
  float blur = smoothstep(far_blur_start, max(far_blur_end, far_blur_start + 0.01), distance_from_camera);
  vec2 offset = blur_radius_pixels * blur / VIEWPORT_SIZE;
  vec3 color = texture(screen_texture, SCREEN_UV).rgb * 0.2;
  color += texture(screen_texture, SCREEN_UV + vec2(offset.x, 0.0)).rgb * 0.12;
  color += texture(screen_texture, SCREEN_UV - vec2(offset.x, 0.0)).rgb * 0.12;
  color += texture(screen_texture, SCREEN_UV + vec2(0.0, offset.y)).rgb * 0.12;
  color += texture(screen_texture, SCREEN_UV - vec2(0.0, offset.y)).rgb * 0.12;
  color += texture(screen_texture, SCREEN_UV + offset * 0.7071).rgb * 0.08;
  color += texture(screen_texture, SCREEN_UV - offset * 0.7071).rgb * 0.08;
  color += texture(screen_texture, SCREEN_UV + vec2(offset.x, -offset.y) * 0.7071).rgb * 0.08;
  color += texture(screen_texture, SCREEN_UV + vec2(-offset.x, offset.y) * 0.7071).rgb * 0.08;
  ALBEDO = color;
  ALPHA = 1.0;
}
