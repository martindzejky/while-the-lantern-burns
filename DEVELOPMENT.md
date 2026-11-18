# Development

Use Godot **4.7.2**, matching the Web export workflow. Open `project.godot` and run the main scene with F5. The game uses the Compatibility renderer.

## Validation

Import resources before running the checks in a fresh checkout:

```sh
godot --headless --import
godot --headless --script res://tests/checkpoints.gd
godot --headless --script res://tests/levels.gd
godot --headless --script res://tests/camera_facing.gd
godot --headless --script res://tests/monster_threat.gd
godot --headless --script res://tests/crumbling_rocks.gd
godot --headless --script res://tests/ending.gd
```

These cover checkpoint storage, level geometry, camera facing, monster threats, crumbling rocks and the ending. No separate formatter or linter is configured.

Also play the game to check movement, item interactions, the menu, pause, retry, Continue and the ending. Automated checks do not replace a playthrough.

## Web export

Install the Godot 4.7.2 export templates, then run:

```sh
mkdir -p dist/web
godot --headless --export-release Web dist/web/index.html
```

Serve the output through a local HTTP server to test it in a browser; opening `index.html` directly from disk does not work.

## Releases

[The Web export workflow](.github/workflows/web-export.yml) exports and checks the game on every push, and uploads the Web build as an artifact. Tag pushes also deploy it to the itch.io `web` channel using the repository's `BUTLER_API_KEY` secret.

Before creating a release tag, set `application/config/version` in `project.godot` to exactly match the tag name and include the version change in the tagged commit. Run the validation and Web export above before tagging, then check that the tag workflow and itch.io deployment succeed.

## Source assets and local files

- [Rock artwork](art/rocks/README.md) includes editable SVGs and regeneration instructions.
- `music/` contains the Ableton source project and recorded sample; keep these source assets.
- `resources/menu/SOURCE.md` and `resources/how_to_play/SOURCE.md` record font and guide-image sources.
- `.godot/`, `.mcp/`, `dist/`, `builds/` and export credentials are ignored local files. Do not commit generated builds, playtest captures or credentials.
