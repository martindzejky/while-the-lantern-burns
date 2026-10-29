shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform bool fxaa_enabled = true;
uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float saturation = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vignette_strength = 0.22;
uniform float vignette_start = 0.45;
uniform float vignette_end = 1.25;

vec3 fxaa(vec2 uv, vec2 pixel_size, vec3 center) {
  const vec3 luma = vec3(0.299, 0.587, 0.114);
  float northwest = dot(texture(screen_texture, uv + vec2(-1.0, -1.0) * pixel_size).rgb, luma);
  float northeast = dot(texture(screen_texture, uv + vec2(1.0, -1.0) * pixel_size).rgb, luma);
  float southwest = dot(texture(screen_texture, uv + vec2(-1.0, 1.0) * pixel_size).rgb, luma);
  float southeast = dot(texture(screen_texture, uv + vec2(1.0, 1.0) * pixel_size).rgb, luma);
  float middle = dot(center, luma);
  float darkest = min(middle, min(min(northwest, northeast), min(southwest, southeast)));
  float brightest = max(middle, max(max(northwest, northeast), max(southwest, southeast)));

  // skip flat areas, but keep the absolute threshold low for the dark cave.
  if (brightest - darkest < max(0.015625, brightest * 0.125)) {
    return center;
  }

  vec2 direction = vec2(
    -((northwest + northeast) - (southwest + southeast)),
    (northwest + southwest) - (northeast + southeast)
  );
  float reduction = max((northwest + northeast + southwest + southeast) * 0.03125, 0.0078125);
  direction /= min(abs(direction.x), abs(direction.y)) + reduction;
  direction = clamp(direction, vec2(-8.0), vec2(8.0)) * pixel_size;

  vec3 inner = 0.5 * (
    texture(screen_texture, uv - direction / 6.0).rgb +
    texture(screen_texture, uv + direction / 6.0).rgb
  );
  vec3 outer = inner * 0.5 + 0.25 * (
    texture(screen_texture, uv - direction * 0.5).rgb +
    texture(screen_texture, uv + direction * 0.5).rgb
  );
  float outer_luma = dot(outer, luma);
  // reject a wider sample when it would cross into an unrelated edge.
  return (outer_luma < darkest || outer_luma > brightest) ? inner : outer;
}

void fragment() {
  vec3 color = texture(screen_texture, SCREEN_UV).rgb;
  if (fxaa_enabled) {
    color = fxaa(SCREEN_UV, SCREEN_PIXEL_SIZE, color);
  }
  float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
  color = mix(vec3(luminance), color, saturation);
  color = (color - 0.5) * contrast + 0.5;
  color *= brightness * tint.rgb;
  float radius = length((SCREEN_UV - 0.5) * 2.0);
  float vignette = smoothstep(vignette_start, max(vignette_end, vignette_start + 0.01), radius);
  COLOR = vec4(max(color, vec3(0.0)) * (1.0 - vignette * vignette_strength), 1.0);
}
