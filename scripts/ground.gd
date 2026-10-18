extends CSGPolygon3D

@export var details: GroundDetails
@export var edge_seed: int = 60
@export_range(0.1, 2.0, 0.05) var edge_spacing: float = 0.4
@export_range(0.0, 0.5, 0.01) var edge_roughness: float = 0.16

var _base_polygon: PackedVector2Array


func _ready() -> void:
  _base_polygon = polygon.duplicate()
  _build_boundary()
  regenerate_edges()
  details.generate(polygon, depth)


func get_base_polygon() -> PackedVector2Array:
  return _base_polygon.duplicate() if not _base_polygon.is_empty() else polygon.duplicate()


func regenerate_edges() -> void:
  if _base_polygon.is_empty():
    _base_polygon = polygon.duplicate()
  polygon = _base_polygon
  if edge_roughness <= 0.0 or not _is_simple_polygon(_base_polygon):
    return
  # retry more gently around narrow passages; gameplay always uses the original outline.
  for attempt: int in range(4):
    var outline := _repair_outline(_rough_outline(edge_roughness * pow(0.5, attempt)))
    if _is_simple_polygon(outline) and _covers_base_polygon(outline):
      polygon = outline
      return


func _repair_outline(outline: PackedVector2Array) -> PackedVector2Array:
  # union keeps the authored floor while resolving chips that cross at sharp corners.
  var pieces: Array[PackedVector2Array] = Geometry2D.merge_polygons(_base_polygon, outline)
  var result: PackedVector2Array = _base_polygon
  var largest_area: float = 0.0
  for piece: PackedVector2Array in pieces:
    var area: float = absf(_signed_area(piece))
    if area > largest_area:
      largest_area = area
      result = piece
  var cleaned := PackedVector2Array()
  var seen: Dictionary[Vector2, int] = {}
  for point: Vector2 in result:
    if seen.has(point):
      var keep: int = seen[point] + 1
      while cleaned.size() > keep:
        seen.erase(cleaned[cleaned.size() - 1])
        cleaned.resize(cleaned.size() - 1)
    elif cleaned.is_empty() or cleaned[cleaned.size() - 1].distance_squared_to(point) > 0.000004:
      seen[point] = cleaned.size()
      cleaned.append(point)
  if cleaned.size() > 2 and cleaned[0].distance_squared_to(cleaned[cleaned.size() - 1]) <= 0.000004:
    cleaned.resize(cleaned.size() - 1)
  return cleaned


func _rough_outline(amplitude: float) -> PackedVector2Array:
  var random := RandomNumberGenerator.new()
  random.seed = edge_seed
  var noise := FastNoiseLite.new()
  noise.seed = edge_seed
  noise.frequency = 0.45
  var outline := PackedVector2Array()
  var winding := 1.0 if _signed_area(_base_polygon) > 0.0 else -1.0
  for index: int in range(_base_polygon.size()):
    var start := _base_polygon[index]
    var end := _base_polygon[(index + 1) % _base_polygon.size()]
    var edge := end - start
    outline.append(start)
    if edge.is_zero_approx():
      continue
    var outward := Vector2(edge.y, -edge.x).normalized() * winding
    var segments := maxi(2, ceili(edge.length() / maxf(edge_spacing, 0.1)))
    for step: int in range(1, segments):
      var fraction := (float(step) + random.randf_range(-0.22, 0.22)) / segments
      var point := start.lerp(end, fraction)
      var broad := noise.get_noise_2dv(point) * 0.5 + 0.5
      var chip := random.randf_range(0.1, 1.0)
      # only add stone outside the safe floor, never remove support beneath the player.
      outline.append(point + outward * amplitude * (0.35 * broad + 0.65 * chip))
  return outline


func _is_simple_polygon(outline: PackedVector2Array) -> bool:
  if outline.size() < 3 or absf(_signed_area(outline)) < 0.0001:
    return false
  for index: int in range(outline.size()):
    var next := (index + 1) % outline.size()
    if outline[index].distance_squared_to(outline[next]) < 0.00000001:
      return false
    for other: int in range(index + 1, outline.size()):
      var other_next := (other + 1) % outline.size()
      if other == next or other_next == index:
        continue
      if Geometry2D.segment_intersects_segment(
        outline[index], outline[next], outline[other], outline[other_next]
      ) != null:
        return false
  return not Geometry2D.triangulate_polygon(outline).is_empty()


func _covers_base_polygon(outline: PackedVector2Array) -> bool:
  var uncovered := Geometry2D.clip_polygons(_base_polygon, outline)
  for piece: PackedVector2Array in uncovered:
    if absf(_signed_area(piece)) > 0.0001:
      return false
  return true


func _signed_area(outline: PackedVector2Array) -> float:
  var area: float = 0.0
  for index: int in range(outline.size()):
    area += outline[index].cross(outline[(index + 1) % outline.size()])
  return area * 0.5


func _build_boundary() -> void:
  var boundary := StaticBody3D.new()
  boundary.name = 'boundary'
  boundary.collision_layer = 4
  boundary.collision_mask = 0
  add_child(boundary)

  for index: int in range(_base_polygon.size()):
    var start := _base_polygon[index]
    var end := _base_polygon[(index + 1) % _base_polygon.size()]
    var edge := end - start
    if edge.is_zero_approx():
      continue
    var midpoint := (start + end) * 0.5
    var shape := BoxShape3D.new()
    # local XY follows the floor; preserve the authored boundary's local depth
    shape.size = Vector3(edge.length() + 0.1, 0.1, 4.0)
    var collider := CollisionShape3D.new()
    collider.shape = shape
    collider.position = Vector3(midpoint.x, midpoint.y, 2.0)
    collider.rotation.z = edge.angle()
    boundary.add_child(collider)
