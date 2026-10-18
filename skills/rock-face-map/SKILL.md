---
name: rock-face-map
description: Interpret Martin's color-labeled rock face maps and prepare normal maps for the game's Sprite3D rocks. Use when supplied rock artwork includes a separate faces PNG.
---

# Rock face maps

Martin draws green rock artwork in Procreate and a separate, aligned layer group marking its flat faces. These colors are categorical direction labels, NOT encoded normals or lighting colors. Preserve this palette across agents.

## Authoring palette

| Face direction | Label color | Exact hex |
| --- | --- | --- |
| Upward-facing top | Yellow | `#FFFF00` |
| Left-facing side | Red | `#FF0000` |
| Diagonally left/front | Purple | `#8000FF` |
| Front, toward the camera | Blue | `#0000FF` |
| Diagonally right/front | Cyan | `#00FFFF` |
| Right-facing side | Green | `#00FF00` |

Left/right refer to the pictured rock as seen on screen, not the lantern's position. Each flat face receives one label color. Actual face slopes can be tuned during a one-rock lighting test; the palette does not prescribe exact angles.

## Procreate exports

- Draw the silhouette and green artwork normally. Keep painted directional highlights/shadows restrained if dynamic normals will supply them.
- Create a separate faces group. Duplicate the silhouette into this group and fill it blue, then paint the other face labels over it. Every interior pixel should have a direction label rather than showing the green artwork underneath.
- Use opaque, solid fills without texture, gradients, shading, or soft transitions between faces. Preserve separate face layers or masks for easy edits.
- Export `rock_name_albedo.png` with only the green artwork visible, and `rock_name_faces.png` with only the direction map visible. Both have identical canvas dimensions, placement, orientation, and transparent exterior. Keep the layered source file.
- Never trim or rescale the two exports independently. Apply the same crop to both when preparing sprites.

## Processing and verification

1. Check alignment and label colors. Do not treat the faces image as a ready-to-use normal map or infer normals from the brightness of the green artwork.
2. Translate labels into chosen surface directions and encode a normal-map texture. Keep each face flat; do not automatically round or bevel it. Keep palette interpretation separate from tunable face slopes.
3. Classify labels before filtering/resizing, since interpolating label RGB values invents false directions. Resolve antialiased edge colors against adjacent known labels while preserving the artwork's alpha silhouette. Inspect unexplained interior colors instead of assigning arbitrary faces.
4. Inspect the current rock shader/material and billboard orientation before wiring normals. Use Godot's OpenGL-style tangent-space convention, not the label colors; import normal data without sRGB color conversion. Verify direction signs against the actual camera/billboard basis, especially the upward-facing top.
5. Test ONE rock with light moved left, right, and above before processing a collection. Check appropriate faces brighten and the green palette remains useful. Normals affect lighting, not silhouette geometry or volumetric cast-shadow shape.

This skill records an authoring agreement, not proof of an implemented converter or verified normal-mapped shader. Check current project files before claiming either exists. Processing artwork does not authorize unrelated gameplay edits.
