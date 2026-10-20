# Taungoo 1550 — Godot 4 project

Set in the Taungoo era (1486–1752). Every building comes from your Taungoo art sheet.

- **Title screen** — the living Taungoo world drifts by behind the menu.
- **Taungoo World (top-down)**
  - Golden **palace** on a stone courtyard — King Tabinshwehti (boss) meditates in front of it
  - **City wall** with gate and tower, **moat** with lotus pads, stone bridge
  - **Market square** with stalls, banners and vendors
  - **Monastery terrace** — bronze bell, golden stupa, white stupa, shrine, monks — on the river bank
  - **Stilt houses** (3) with flooded **rice paddies**
  - **River** with muddy/sandy banks, reeds, foam and sampans
  - Dense tropical forest (190 rain trees, young trees and bushes) with swaying
    canopies, dappled leaf shadows, dark mossy forest floor, sun shafts,
    falling leaves, fireflies and a warm colour grade
  - Court and army NPCs: royal ministers before the palace, spear guards,
    gate guards, a groom with a war horse, a spear squad marching from the
    gate to the market, cavalry patrolling the roads
  - Palms that sway, torches, townspeople, dirt paths
- **Sunset Stage (side-view)** for the sky mage, swordswoman and night thief.
- Characters: top-down swordsman, gunslinger, Burmese man, sky mage; side-view sky mage, swordswoman, night thief.

## Setup
1. Unzip → folder `yangon_game/` with `project.godot` inside.
2. Godot 4.3+ → **Import** → `project.godot` → **Import & Edit**.
3. **F5**. Pick a character next to a button and click it. **Esc** = back to title.

| Top-down | Side-view |
|---|---|
| WASD move, J attack / cast | A/D run, Space jump, J attack |

## Folder structure
```
yangon_game/
├── project.godot
├── scripts/            game.gd, world.gd, hud.gd, player_topdown.gd, npc_wander.gd, ...
├── scenes/
│   ├── title/          title_screen.tscn
│   ├── world/          taungoo_world.tscn  (+ art/ground.png, ground_n.png, water_map.png)
│   └── stages/         sunset_stage.tscn
├── characters/
│   ├── npcs/taungoo/   ministers, guards, horse, squad, cavalry (npc_idle.gd, marcher.gd)
│   ├── topdown/        swordsman/, gunslinger/, burmese_man/, sky_mage/
│   ├── sideview/       sky_mage/, heroine/, night_thief/
│   └── enemies/        tabinshwehti/
└── environment/
    ├── taungoo/
    │   ├── forest/     rain_tree_a/b/c, young_tree, bush (+ normal maps, dappled shadows)
    │   ├── buildings/  palace, fortress, bridge, stilt_house(_double/_small), monastery, market_*
    │   ├── nature/     palm.tscn, torch.tscn
    │   └── building.gd (front/behind sorting + see-through fade)
    ├── trees/red_tree/
    ├── fx/             water, reflection, sway, atmosphere (colour grade) shaders, flicker.gd
    ├── props/          boat.gd, boat_rowing.png, dummy.gd
    └── backgrounds/sunset_hills/
```

## Add things to the world
Open `scenes/world/taungoo_world.tscn`. Everything standing up goes inside **Objects**
(Y-sorted). Drag any scene from `environment/taungoo/buildings/`, `nature/palm.tscn`,
`nature/torch.tscn`, `trees/red_tree/red_tree.tscn` or
`characters/topdown/burmese_man/burmese_man_npc.tscn` onto **Objects**.

Note: the ground (paths, courtyards, paddies, river, moat) is painted into
`scenes/world/art/ground.png` and `water_map.png`. Moving a building does not move its
courtyard. Water you can't walk on is in **WaterEdges** (collision polygons).

## Add your own character
Duplicate a folder in `characters/topdown/`, swap the SpriteFrames, keep the root in
the **player** group, and add one line to `TOPDOWN` in `scripts/game.gd`.

## Boss
King Tabinshwehti waits in front of the palace. Come close and he rises. Tune him by
selecting `Objects/Tabinshwehti` (Max Health, Damage, Speed, Aggro Radius).

## NPCs and forest

- Standing NPCs (`characters/npcs/taungoo/*.tscn`) breathe and turn to face you when
  you come close. Drag any of them onto **Objects** to add more.
- `spear_squad.tscn`, `cavalry_patrol.tscn`, `lone_rider.tscn` march/ride along their
  **Points** (select the node → Inspector → Points) back and forth.
- Trees: drag `environment/taungoo/forest/*.tscn` onto **Objects**. They sway, cast
  dappled shadows and go see-through when you walk behind them.
- Colour grade: `Grade/Screen` in the world. Tune Bloom, Warmth, Vignette in its
  material, or hide it on slow PCs (it costs some performance).

## ASCII mode and night (F2 / F3)

| Key | What it does |
|---|---|
| **F2** | ASCII graphics on/off: the whole world is redrawn as coloured text characters (`/ \ | - ; r ? T @ ...`) |
| **F3** | Day / night (moonlight, no sun shafts, more fireflies). Fades over 1.5 s |

Both work anywhere, also on the title screen. ASCII + night gives the dark terminal look.

- Your character and the boss stay as normal sprites on top, so you can always see them.
  To turn them into text too, set `ascii_keep_characters_clear = false` in `scripts/game.gd`.
- Start the game in ASCII or night mode: set `ascii_mode = true` / `night_mode = true` at the top of `scripts/game.gd`.
- Tune the look in `environment/fx/ascii/ascii.gdshader`:
  - `cell` — character size in pixels (bigger = chunkier letters, `vec2(8, 13)` default)
  - `edge_threshold` — lower = more `/ \ | -` outline strokes
  - `contrast` — higher = darker, emptier background
  - `vivid` / `saturation` — how colourful the letters are
  - `brightness`, `background`, `glow`
- Letters come from `environment/fx/ascii/glyphs.png` (16 dark→bright letters + 4 line strokes, 12×20 each).

## Living light, reflections, wading

**Light on the body.** Every character (you, the NPCs and the boss) has a rounded normal
map for every animation frame (`*_n.png` next to each picture or sheet). As you run,
attack or turn, light and shade roll over arms, legs, clothes and face. Walk past a
torch and watch the lit side follow it. Walk through the forest and the leaf and
building shadows slide over your body.
- Shader: `environment/fx/lit_character.gdshader`. Material settings: `shade_strength`
  (how dark the tree shadows on you are), `rim_strength` (bright edge on the lit side),
  `contrast` (how strong the light/dark split is).
- It is added automatically to any sprite in a scene saved under `res://characters/`,
  as long as there is a normal map. For your own character:
  `python3 normals.py my_sheet.png` makes `my_sheet_n.png` (script in `tools/normals.py`).
- Turn it off: `living_light = false` in `scripts/game.gd`.

**Water reflections.** Characters, boats and riverside palms get an upside-down,
rippling reflection, shown only on water. Turn off with `water_reflections = false`
in `scripts/game.gd`. Tune `strength`, `tint`, `fade_px` and `wobble` in
`environment/fx/water_reflection.gdshader`.

**Wading and ripples.** You can walk about 30 px into the river shallows (slower,
feet under the water line). Rings spread out around you while you wade (faster while
moving), around the boats, and now and then from fish. Settings: the **Ripples** node
script `scripts/ripples.gd` (ring_color, max_radius, life, fish_rings).
In ASCII mode (F2) the rings turn into `( ) / \` text rings.
