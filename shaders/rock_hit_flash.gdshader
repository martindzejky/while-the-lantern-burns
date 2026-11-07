shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_disable;

void vertex() {
  // match the rock's full camera-facing billboard while retaining its scale.
  vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
  MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
  MODELVIEW_MATRIX[0] *= scale.x;
  MODELVIEW_MATRIX[1] *= scale.y;
  MODELVIEW_MATRIX[2] *= scale.z;
}

void fragment() {
  ALBEDO = vec3(1.0);
  ALPHA = texture(rock_texture, UV).a;
  ALPHA_SCISSOR_THRESHOLD = 0.5;
}
