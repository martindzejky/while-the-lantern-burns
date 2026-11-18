extends SceneTree
## Run: godot --headless --script res://tools/generate_rock_textures.gd
## SVG fills are direction labels, never albedo colors or encoded normals.

const LABELS = [Color.YELLOW, Color.RED, Color(0.5, 0, 1), Color.BLUE, Color.CYAN, Color.GREEN]
const BASE = Color8(80, 133, 99)


func _initialize() -> void:
  var front := Vector3(0, -sin(deg_to_rad(40)), cos(deg_to_rad(40)))
  var normals := [
    Vector3(0, sin(deg_to_rad(-25)), cos(deg_to_rad(-25))),
    Vector3.LEFT,
    (Vector3.LEFT + front).normalized(),
    front,
    (Vector3.RIGHT + front).normalized(),
    Vector3.RIGHT,
  ]
  for family in ['big', 'small']:
    for index in range(1, 9 if family == 'big' else 8):
      var stem := '%s_rock_%02d' % [family, index]
      generate(stem, normals)
  quit()


func generate(stem: String, normals: Array) -> void:
  var faces := Image.new()
  var source := FileAccess.get_file_as_string('res://art/rocks/' + stem + '.svg')
  var error := faces.load_svg_from_string(source, 2.0)
  assert(error == OK, 'Cannot rasterize ' + stem)
  var albedo := Image.create(faces.get_width(), faces.get_height(), false, Image.FORMAT_RGBA8)
  var normal := Image.create(faces.get_width(), faces.get_height(), false, Image.FORMAT_RGBA8)
  for y in faces.get_height():
    for x in faces.get_width():
      var pixel := faces.get_pixel(x, y)
      var encoded := Color(0.5, 0.5, 1, pixel.a)
      if pixel.a > 0:
        var label := nearest_label(pixel)
        var direction: Vector3 = normals[label]
        encoded = Color(
          (direction.x + 1) / 2, (direction.y + 1) / 2, (direction.z + 1) / 2, pixel.a
        )
        faces.set_pixel(x, y, Color(LABELS[label], pixel.a))
      albedo.set_pixel(x, y, Color(BASE, pixel.a))
      normal.set_pixel(x, y, encoded)
  # Classify before downsampling so blended label colors cannot invent directions.
  for texture in [faces, albedo, normal]:
    texture.resize(texture.get_width() / 2, texture.get_height() / 2, Image.INTERPOLATE_BILINEAR)
  var destination := 'res://sprites/'
  var arguments := OS.get_cmdline_user_args()
  if not arguments.is_empty():
    destination = arguments[0].trim_suffix('/') + '/'
  assert(faces.save_png(destination + stem + '_faces.png') == OK)
  assert(albedo.save_png(destination + stem + '.png') == OK)
  assert(normal.save_png(destination + stem + '_normal.png') == OK)
  print('Generated ', stem, ' ', faces.get_size())


func nearest_label(pixel: Color) -> int:
  var nearest := 0
  var distance := INF
  for index in LABELS.size():
    var label: Color = LABELS[index]
    var difference := Vector3(pixel.r - label.r, pixel.g - label.g, pixel.b - label.b)
    var candidate := difference.length_squared()
    if candidate < distance:
      distance = candidate
      nearest = index
  return nearest
