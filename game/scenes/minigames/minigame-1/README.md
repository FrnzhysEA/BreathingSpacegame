# Heart Rate Manager — Godot 4 Project

A mini anxiety-management game. Keep your heart rate (the glowing ball) inside
the **safe zone (60–100 bpm)** by clicking/tapping to breathe. Stressor pills
fly in from the right and spike your BPM when they hit.

## Requirements
- **Godot 4.2+** (GL Compatibility renderer)

## How to open
1. **Extract** the zip to a folder (do NOT open from inside the zip)
2. Open Godot 4
3. Click **Import** → navigate into the extracted `HeartRateManager` folder
4. Select `project.godot` → **Import & Edit**
5. Press **F5** to run

## Controls
| Input | Action |
|-------|--------|
| Left-click / Tap | Breathe — lowers BPM by ~7-10 |
| Passive | BPM drifts back toward 75 on its own |

## Gameplay
- Safe zone: 60-100 bpm (green band)
- Stressor pills collide with the heart ball and raise BPM
- Staying outside the safe zone fills a red danger bar — when full you lose a life
- You have 3 lives; lose all 3 and the game ends
- Difficulty increases every 18 seconds (up to level 8)

## Project structure

    HeartRateManager/
    ├── project.godot              Godot project config
    ├── icon.svg                   App icon (EKG style)
    ├── Main.gd                    All game logic + _draw() rendering
    ├── Main.tscn                  Main scene: Node2D + CanvasLayer HUD
    └── assets/
        ├── theme.tres             UI theme (buttons, panels, labels)
        ├── default_env.tres       Default environment (silences warnings)
        ├── heart.svg              Heart/ball icon 32x32
        ├── icon_safe.svg          Safe zone checkmark 16x16
        ├── icon_danger.svg        Danger warning icon 16x16
        ├── icon_breath.svg        Breath/calm ripple icon 16x16
        └── stressor_deadline.svg  Example stressor pill graphic

## Key functions in Main.gd

- bpm_to_y(b)         — Maps BPM value to screen Y coordinate
- _do_breathe(pos)    — Click/tap: lowers BPM, spawns breath particles
- _spawn_stressor()   — Picks a random stressor, fires from right edge
- _process(delta)     — Physics: BPM drift, ball spring, collision, danger timer
- _draw()             — Renders background, EKG, safe zone, stressors, ball
- _draw_dashes(...)   — Custom dashed line (avoids Godot built-in name clash)
