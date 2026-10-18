shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D detail_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_disable;
uniform float minimum_brightness : hint_range(0.0, 0.2) = 0.04;

void vertex() {
  // face the camera independently of the ground's orientation.
  MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
  MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
  vec4 detail = texture(detail_texture, UV);
  if (detail.a < 0.5) {
    discard;
  }
  ALBEDO = detail.rgb;
  EMISSION = detail.rgb * minimum_brightness;
  vec2 xy = texture(detail_normal, UV).rg * 2.0 - 1.0;
  vec3 authored = vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
  // only the yellow top category has centered X and Y near -0.42.
  if (abs(xy.x) < 0.1 && xy.y > -0.55 && xy.y < -0.3) {
    NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
  } else {
    NORMAL = normalize(authored);
  }
}

void light() {
  // a little wrapped light keeps small facets readable beside a light source.
  float lit = max((dot(NORMAL, LIGHT) + 0.2) / 1.2, 0.0);
  DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI;
}
