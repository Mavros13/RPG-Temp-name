# Engine

APEX DREAMFORGE uses Godot 4.

The project was opened with Godot 4.7.2 stable, the standard editor (not the .NET build). `project.godot` targets the 4.7 feature set and the Forward Plus renderer. The repository root is the Godot project.

## Why this pass stops at a launching project

This repository had no engine and no project. This change only adds a project that opens and runs one main scene, `res://main.tscn`, in a window titled APEX DREAMFORGE. Gameplay systems, content, export presets, and automation stay out until that launch is real.

## How to open it

1. Install Godot 4.7 stable. This project was checked with 4.7.2. The standard editor is enough.
2. In the Project Manager, choose Import and select the repository root, the folder that contains `project.godot`.
3. Open the project and press F5, or the Play button. Godot runs `res://main.tscn`.

From a terminal, with the Godot 4.7 binary available as `godot`:

```
godot --path .
```

Load check:

```
godot --headless --path . --quit-after 1
```

That command exited 0 with Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`).

An editor debug run would otherwise title the window `APEX DREAMFORGE (DEBUG)`, because Godot appends that suffix to `application/config/name`. `main.gd` sets the window title to `APEX DREAMFORGE` when the main scene starts.
