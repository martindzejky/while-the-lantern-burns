shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec4 light_color : source_color = vec4(0.75, 0.88, 1.0, 0.15);

void fragment() {
  float sides = smoothstep(0.0, 0.25, UV.x) * smoothstep(0.0, 0.25, 1.0 - UV.x);
  float length_fade = smoothstep(0.0, 0.35, UV.y) * smoothstep(0.0, 0.5, 1.0 - UV.y);
  ALBEDO = light_color.rgb;
  ALPHA = light_color.a * sides * length_fade;
}
