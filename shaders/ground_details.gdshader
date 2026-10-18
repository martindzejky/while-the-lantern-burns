shader_type spatial;
render_mode cull_disabled, specular_disabled, depth_draw_never;

#include "res://shaders/ground_light_profile.gdshaderinc"

uniform sampler2D detail_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_disable;
uniform bool use_normal_map = false;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
  vec4 detail = texture(detail_texture, UV);
  ALBEDO = detail.rgb;
  ALPHA = detail.a * opacity;
  if (use_normal_map) {
    // normal imports can store only RG; match Godot's positive-green decode.
    vec2 xy = texture(detail_normal, UV).rg * 2.0 - 1.0;
    vec3 authored = vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
    // the source normals were authored on sprites facing a 40-degree camera.
    // rotate that frame 50 degrees into the floor, keeping artwork X/Y axes.
    vec3 floor_normal = vec3(authored.x,
      authored.y * 0.6427876 - authored.z * 0.7660444,
      authored.y * 0.7660444 + authored.z * 0.6427876);
    NORMAL = normalize(TANGENT * floor_normal.x + BINORMAL * floor_normal.y + NORMAL * floor_normal.z);
  }
}

void light() {
  if (use_normal_map) {
    DIFFUSE_LIGHT += max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION * LIGHT_COLOR / PI;
  } else {
    float lit = ground_light_profile(ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL, SPECULAR_AMOUNT);
    DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
  }
}
