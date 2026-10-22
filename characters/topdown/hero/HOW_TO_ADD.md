# Hero (suit) - main character, 8 directions

## 1. Copy
Put this `hero` folder in `characters/topdown/` of your project.

## 2. One line in `scripts/game.gd`
Inside `const TOPDOWN := { ... }` add:
```gdscript
	"hero": "res://characters/topdown/hero/hero.tscn",
```
To make him the default main character, also change
`var topdown_character := "swordsman"` to `var topdown_character := "hero"`.

## 3. Play
F5 -> pick **Hero** next to "Explore Taungoo".

| Key | |
|---|---|
| WASD / arrows | walk (8 directions) |
| hold **Shift** | run |
| **E** | wave hello |

## Animations (in `hero_frames.tres`)
- `idle_<dir>`  6 frames, breathing          (dir = s, se, e, ne, n, nw, w, sw)
- `walk_<dir>`  29-33 frames each, from your 8-direction walking video, converted to the pixel-art style of your sheet (same colours, 1-px outline) - smooth, 26 fps
- `run_<dir>`   8 frames for e / se / w / sw (from the sheet); the other directions
                play the walk faster when running (Run Walk Rate on the Hero node)
- `wave`        6 frames
Each frame has a lighting map (`frames/*_n.png`), so torches, sun, moon, lightning and
tree shadows light his body, and he reflects in water / wades like the others.

Walk/run speed and animation speed match, so feet don't slide. Change speeds in the
Inspector on the **Hero** root: Walk Speed, Run Speed, Max Health.
Size: **AnimatedSprite2D** -> Scale (0.46 now).

## Replacing frames later
Frames are plain PNGs in `frames/` (128 x 176, feet at y = 168, body centred at x = 64).
Overwrite any `walk_s_3.png` etc. with a new picture of the same size and Godot uses it.
If you replace a picture, also delete its `_n.png` or make a new one with
`python3 tools/normals.py frames/walk_s_3.png` from the project folder.
