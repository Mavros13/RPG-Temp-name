# Chamber 2

Enclosed 10 m × 8 m room. It loads on its own as `res://game/world/chamber_2/chamber_2.tscn`. The floor and walls have collision, so the player can walk inside. Four braziers light the hall.

Run it directly:

```
godot --path . res://game/world/chamber_2/chamber_2.tscn
```

The window title is APEX DREAMFORGE.

This chamber is not linked from the first room yet. `res://game/world/room_3d/room_3d.tscn` does not instance it, and the project main scene is still the first room.

Floor, wall, and brazier meshes are the existing files in `res://assets/world/first_room/`. This folder does not copy those binaries. The player mesh is `res://assets/characters/player/player_adventurer.glb`.
