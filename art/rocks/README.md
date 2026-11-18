# Rock artwork

Editable SVG face maps for all eight large rocks and seven small rocks. Large rocks have side-view faces, shallow top facets and flat ground edges; small rocks retain more visible top surface. Canvas sizes match the original PNGs so existing scene anchors, shadows, collisions and level placement can stay unchanged.

The SVG fills are categorical face directions, not lighting colors. See [the rock face-map skill](../../.agents/skills/rock-face-map/SKILL.md) for the palette and camera-space normal mapping. Green albedos remain solid `#508563`; Godot supplies lighting.

Regenerate all three PNGs per rock with the existing Godot executable:

```sh
godot --headless --path . --script res://tools/generate_rock_textures.gd
```

The generator rasterizes at twice the final size, classifies face labels before downsampling, then writes matching albedo, `_faces` and `_normal` textures under `sprites/`. No external image libraries are required. These source SVGs are excluded from Godot's asset importer.
