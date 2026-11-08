# Rock crumble sound effects

Replacement assets for [issue #31](https://github.com/martindzejky/while-the-lantern-burns/issues/31), generated with ElevenLabs Sound Effects v2 (`eleven_text_to_sound_v2`) on 2026-11-08.

- Settings: `duration_seconds: 2`, `prompt_influence: 0.6`, `loop: false`; one generation per prompt.
- ElevenLabs flow: `CJZffdlme4Bu1nMCiFma`.
- Downloaded MP3s decoded to 44.1 kHz mono float PCM before gain adjustment, then saved as 16-bit WAV. Exactly 88,200 frames (2 seconds) each.
- Constant gain targets −23 dBFS RMS, close to the previous assets' average level, with a −1 dBFS peak ceiling. Linear 2 ms start / 40 ms end fades prevent edge clicks. No extra reverb: the existing scene routes to `World SFX Heavy Reverb`.
- Existing paths, import UIDs, three-way randomizer and 2.5-second effect lifetime are preserved.

## Generation prompts

### `rock_crumble_01.wav`

Generation: `KkGPcfKedmwSXlCne1NS`.

A heavy boulder shatters on impact: instant powerful low stone thud and sharp brittle crack, then coarse crunching rock chunks falling, followed by smaller stones bouncing and ticking on stone in diminishing irregular taps until fully settled. One punchy destruction event over exactly two seconds, no lead-in, quiet ending. Dry close-up isolated foley, no reverb, gunshot, explosion, voice, music or ambience.

### `rock_crumble_02.wav`

Generation: `NEcKitbCVfLuBWFXeFZV`.

A dense limestone rock struck hard, bursting apart instantly with a punchy deep impact and layered sharp fractures. Large fragments crash down briefly, then loose gravel and small pebbles clatter and bounce more softly until fully settled to silence. Exactly two seconds, single event, fast attack, gritty rocky texture. Dry close microphone, no echo, explosion, gunfire, voices, music or ambience.

### `rock_crumble_03.wav`

Generation: `AWeWbrUrUnDKVEdYr8Ri`.

Granite boulder destruction: immediate forceful heavy impact with jagged snapping and shattering, then rough stone chunks knocking together as they fall. A scattered cascade of small stones patters and rolls to a final few quiet pebble ticks, decaying to silence by two seconds. Single event, no lead-in, punchy physical rocky crunch. Dry isolated foley, no reverb, blast, gunshot, voices, music or ambience.

## Audition

Listen to the three WAVs directly for the dry source. In game, shoot a large rock with the musket to hear random selection through cave reverb. Final sound character and mix approval require human listening.
