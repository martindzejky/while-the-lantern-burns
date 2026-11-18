# Rock artwork

Editable SVG face maps for all eight large rocks and seven small rocks. Large rocks have side-view faces and shallow top facets; small rocks retain more visible top surface.

Each large rock also has an `_extended.svg` with six times its original canvas height. Individually drawn shoulders widen into broad lower masses, with angular fracture planes and occasional exposed shelves. The body starts behind the original lower flank so the join does not pinch into a narrow column. The original crown keeps its size and position; `data-top-preserve` records the number of upper rows copied exactly during generation. The extension has no baked darkness or gradient; lighting supplies the falloff.

Large rock scenes use the extended textures for their visible sprite and keep the original textures for their separate shadow sprite. Extra horizontal canvas space is symmetric, and the generator centers the original crown within it, preserving its horizontal position. The visible sprite offset is reduced by half the added pixel height, preserving the top's vertical position without moving any scene instance or collider. Original textures also remain available for menu dioramas. Small ground rocks are unchanged.

The SVG fills are categorical face directions, not lighting colors. See [the rock face-map skill](../../.agents/skills/rock-face-map/SKILL.md) for the palette and camera-space normal mapping. Green albedos remain solid `#508563`; Godot supplies lighting.

Regenerate all three PNGs per rock with the existing Godot executable:

```sh
godot --headless --path . --script res://tools/generate_rock_textures.gd
```

The generator rasterizes at twice the final size, classifies face labels before downsampling, then writes matching albedo, `_faces` and `_normal` textures under `sprites/`. No external image libraries are required. These source SVGs are excluded from Godot's asset importer.
