# Black Cat v2 - 8 directions, walk / run / sit / pounce

## Install
- If you already have the old cat: delete `characters/topdown/black_cat/` and put this
  `black_cat` folder there instead. `scripts/game.gd` stays the same.
- New: put this folder in `characters/topdown/` and add inside `const TOPDOWN := { ... }`:
  ```gdscript
  "black_cat": "res://characters/topdown/black_cat/black_cat.tscn",
  ```

## Keys
| Key | |
|---|---|
| WASD / arrows | walk (8 directions) |
| hold **Shift** | run |
| **C** | sit down / stand up (also sits by itself after 4 s standing still) |
| **J** | pounce - leaps and swipes (hurts the boss) |

## Animations (`black_cat_frames.tres`, frames in `frames/`)
- `walk_<dir>`, `run_<dir>` (4 frames each, all 8 directions from your new walk/run sheet), `idle_<dir>`
  dir = e, se, s, sw, w, nw, n, ne
- `sit_down_r/l`, `sit` (tail sways, blinks), `stand_up_r/l`, `pounce_r/l`
Every frame has a lighting map (`_n.png`) and a glowing-eye layer (`_eyes.png`).

Inspector on **BlackCat**: Walk Speed, Run Speed, Auto Sit After (0 = never), Max Health,
Pounce Damage/Distance. Size: set the same Scale on **AnimatedSprite2D** and **Eyes**.
