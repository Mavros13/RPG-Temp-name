# Player adventurer

Low-poly humanoid for APEX DREAMFORGE. Godot 4 imports the glTF as a scene. There is no skeleton and no animation.

## Files

- `player_adventurer.glb` — the character (glTF 2.0 binary, about 1.83 m tall)
- `.gitattributes` — Git LFS rules for `*.glb` and `*.bin` in this folder

Opening the project makes Godot write `player_adventurer.glb.import` and a cache under `.godot/`. `.godot/` is gitignored. Do not commit that cache.

## Instance it

The repository root is the Godot project. Drag `res://assets/characters/player/player_adventurer.glb` into a 3D scene, or instance it from a script:

```gdscript
const PLAYER_MODEL := preload("res://assets/characters/player/player_adventurer.glb")

func _ready() -> void:
    var player := PLAYER_MODEL.instantiate()
    add_child(player)
```

Checked with Godot 4.7.2. `instantiate()` returns a `Node3D` named `Player`. The figure is its child, `PlayerAdventurer`.

## Layout

The origin is on the ground between the feet. One unit is one meter. The figure faces +Z, and Godot 4.7 keeps that axis (the imported root transform is identity). A Godot camera looks down -Z, so set `rotation_degrees.y = 180` when the character should face the camera.

Materials are glTF metallic-roughness colors. Add a light, such as a `DirectionalLight3D`, or the mesh stays dark.

`Left` and `Right` are the character's own left and right. `+X` is the character's left. These nodes are the joints, and rotating one moves its children:

- `Pelvis` at the hips
- `Chest` for the upper body
- `Neck` and `Head` (the head turns from the base of the skull)
- `UpperArmLeft` / `UpperArmRight` at the shoulders
- `ForearmLeft` / `ForearmRight` at the elbows
- `HandLeft` / `HandRight` at the wrists
- `ThighLeft` / `ThighRight` at the hips
- `ShinLeft` / `ShinRight` at the knees

The hood, cape, belt, pouch, and sheathed sword are parented under the body, so they follow those joints. The arms hang in a slight A-pose.
