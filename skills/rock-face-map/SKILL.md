---
name: rock-face-map
description: Slice Martin's color-labeled rock sheets and generate flat green albedos and normal maps for the game's Sprite3D rocks.
---

# Rock face maps

Martin supplies only the color-labeled face sheet. He may call this the normal-map image, but these colors are categorical direction labels, NOT encoded normals or lighting colors. Generate both the green base sprites and encoded normal maps from it. Preserve this palette across agents.

## Approved base color

Fill each complete rock silhouette with solid **`#508563`** (sRGB RGB **80, 133, 99**), retaining the source alpha exactly, including antialiased edges and holes. This is the approved lit-face green; dynamic lighting supplies the face shading. Do not bake the colored face labels or additional highlights into the albedo. Earlier darker bases `#123a28` and `#2b6245` were rejected as too dark.

## Authoring palette

| Face direction | Label color | Exact hex |
| --- | --- | --- |
| Top face, tilted forward for lantern lighting | Yellow | `#FFFF00` |
| Left-facing side | Red | `#FF0000` |
| Diagonally left/front | Purple | `#8000FF` |
| Front, toward the camera | Blue | `#0000FF` |
| Diagonally right/front | Cyan | `#00FFFF` |
| Right-facing side | Green | `#00FF00` |

Left/right refer to the pictured rock as seen on screen, not the lantern's position. Each flat face receives one label color. Actual face slopes can be tuned during a one-rock lighting test; the palette does not prescribe exact angles.

## Procreate exports

- Draw the silhouette and fill it blue, then paint the other face labels over it. Every interior pixel should have a direction label.
- Use opaque, solid fills without texture, gradients, shading, or soft transitions between faces. Preserve separate face layers or masks for easy edits.
- Export only the direction-map PNG or sheet with a transparent exterior. Keep the layered source file. A separate green albedo export is not required.
- Slice each rock once; use identical crop dimensions, placement and alpha for its generated albedo, preserved `_faces.png`, and `_normal.png`. Preserve relative sizes across the sheet.

## Processing and verification

1. Check transparency and label colors, then generate the approved flat albedo from the full alpha silhouette. Do not treat the supplied faces image as a ready-to-use normal map.
2. Translate labels into chosen surface directions and encode a normal-map texture. Keep each face flat; do not automatically round or bevel it. Keep palette interpretation separate from tunable face slopes.
3. Classify labels before filtering/resizing, since interpolating label RGB values invents false directions. Resolve antialiased edge colors against adjacent known labels while preserving the artwork's alpha silhouette. Inspect unexplained interior colors instead of assigning arbitrary faces.
4. Inspect the current rock shader/material and billboard orientation before wiring normals. Use Godot's OpenGL-style tangent-space convention, not the label colors; import normal data without sRGB color conversion. Verify direction signs against the actual camera/billboard basis, especially the upward-facing top.
5. Test ONE rock with light moved left, right, and above before processing a collection. Check appropriate faces brighten and the green palette remains useful. Normals affect lighting, not silhouette geometry or volumetric cast-shadow shape.

## Existing project setup

The first seven examples are `sprites/small_rock_01` through `small_rock_07`, each with albedo, `_faces` and `_normal` PNGs. Scriptless scenes in `objects/` use native `StandardMaterial3D` normal mapping, alpha scissor, no specular, billboard mode with scale preserved, and bottom-centered Sprite3D artwork. Normal imports use `compress/normal_map=1` without green-channel inversion or sRGB conversion. New sheets should follow these examples. Larger blocking variants are `big_rock_01` through `big_rock_08`, with native material sprites under StaticBody3D roots. All small and big rock scenes have their own CylinderShape3D: radius is half the visible alpha silhouette width multiplied by pixel_size, excluding transparent padding. Height is 1 and the shape is centered at Y .5; no jumping is supported. Keep visual sprites bottom-centered and scale the whole root when resizing a placed rock so collisions scale with it. The old placeholder rock scene and SVG have been removed. Small rocks use pixel_size .0025; the larger 2048-pixel sheet uses .004. Keep new size choices consistent with the artwork and verify them in the level.

The mapping uses the current 40-degree camera pitch: yellow top faces are artistically tilted toward the front, only **15 degrees above the horizontal ground plane**, so low lanterns can light them. Their tangent normal is `(0, sin(-25°), cos(-25°))`, encoded RGB **(128, 74, 243)**. This replaces the original vertical-up mapping, which left the tops too dark. The remaining directions are front `(0, -sin(40°), cos(40°))`, left/right `(±1, 0, 0)`, and diagonal front faces with X `±sqrt(0.5)` and the front vector multiplied by `sqrt(0.5)`. Left uses negative X. Encode each component as `(component * 0.5 + 0.5) * 255`. Recheck the camera basis if its pitch changes.

Exports can shift the exact label RGB values. Identify the dominant exported colors corresponding to the palette, then resolve blended seam/edge pixels from adjacent known labels. Do not invent a face category absent from the artwork because an antialiased seam happens to resemble it.

Native left/right/overhead lighting was verified for the first collection. Repeat a one-rock check when the converter, camera basis or material changes. Processing artwork does not authorize unrelated gameplay edits.
