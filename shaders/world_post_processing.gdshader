shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vignette_strength = 0.22;
uniform float vignette_start = 0.45;
uniform float vignette_end = 1.25;

void fragment() {
  vec3 color = texture(screen_texture, SCREEN_UV).rgb;
  float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
  color = mix(vec3(luminance), color, saturation);
  color = (color - 0.5) * contrast + 0.5;
  color *= brightness * tint.rgb;
  float radius = length((SCREEN_UV - 0.5) * 2.0);
  float vignette = smoothstep(vignette_start, max(vignette_end, vignette_start + 0.01), radius);
  COLOR = vec4(max(color, vec3(0.0)) * (1.0 - vignette * vignette_strength), 1.0);
}
