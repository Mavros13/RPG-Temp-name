# First room props

Godot 4 glTF 2.0 meshes for the opening room. Units are meters. Godot 4.7 imports each `.glb` as a scene.

| File | Prop |
| --- | --- |
| `brazier.glb` | Iron tripod brazier with coals, embers, flames, and a fire light |
| `stone_floor_tile.glb` | Flagstone floor tile, 2 m × 2 m |
| `wall_segment.glb` | Ashlar wall segment, 2 m wide and 3 m tall |

`*.glb` in this folder is tracked with Git LFS (see `.gitattributes`).

## Pivots

- `stone_floor_tile.glb` — node `StoneFloorTile`. Origin at the center. The walkable top is Y = 0 and the slab extends down to Y = −0.15. Place copies on a 2 m grid at `(2x, 0, 2z)`.
- `wall_segment.glb` — node `WallSegment`. Origin at the bottom center of the decorated face. That face points along +Z. Blocks and the plinth project toward +Z; the plinth reaches Z = 0.065. The wall body goes back to Z = −0.45. Butt segments along X every 2 m. The running bond continues across the joint, and one segment matches one floor tile.
- `brazier.glb` — root node `Brazier`. Origin at the center of the feet, on Y = 0. The bowl rim is at 1.09 m and the flames reach about 1.42 m. The feet span about 0.80 m.

## Brazier nodes

| Node | Contents |
| --- | --- |
| `Iron` | Bowl, tripod, collar, feet, ground ring, and two rim handles |
| `Coals` | Faceted coal lumps with a little emission |
| `Embers` | Hotter lumps with stronger emission |
| `Flames` | Unlit, double-sided tongues (`Flame` and `FlameCore`) |
| `FireLight` | Omni light. Energy 1.5, range 6 m, color `(1, 0.6, 0.22)` |

Godot copies that light's intensity straight into `OmniLight3D` energy. This project does not use physical light units, so 1.5 is a normal room light.

Stone is rough and non-metallic warm gray. Iron is metallic. `stone_floor_tile.glb` and `wall_segment.glb` use `GODOT_single_root`, so Godot 4.7 imports each mesh as the scene root.

These files are not instanced in a scene.
