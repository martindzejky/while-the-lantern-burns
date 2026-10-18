shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float darkness_progress : hint_range(0.0, 1.0) = 0.0;
uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warning_color : source_color = vec4(0.6, 0.015, 0.025, 1.0);
uniform vec4 death_tint : source_color = vec4(0.55, 0.04, 0.055, 1.0);

void fragment() {
  vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
  vec2 edge_distance = abs(UV * 2.0 - 1.0);
  float border = smoothstep(0.35, 1.0, max(edge_distance.x, edge_distance.y));
  vec3 warning = mix(scene, warning_color.rgb, border * darkness_progress * 0.75);
  float gray = dot(scene, vec3(0.299, 0.587, 0.114));
  vec3 dead_scene = (gray + 0.16) * death_tint.rgb;
  COLOR = vec4(mix(warning, dead_scene, death_progress), 1.0);
}
