# Hostile NPC

A static hostile humanoid for APEX DREAMFORGE. Godot 4.7 imports the glTF as a packed scene. Nothing in this folder is wired into `main.tscn`.

The figure is a raider, not a traveling adventurer. The face is an enclosed helm with a glowing visor slit. The weapon is a chipped cleaver held out across the body, with a spiked buckler on the other arm. Iron plates, horn spikes, and a crimson war rag replace a pack, a bedroll, a sheathed longsword, or an open face.

## Files

| File | Role |
| --- | --- |
| `hostile_npc.gltf` | glTF 2.0 scene. Text. Materials, node tree, and buffer layout. |
| `hostile_npc.bin` | Vertex and index payload for that glTF. Git LFS. |
| `.gitattributes` | Tracks `hostile_npc.bin` with Git LFS. |

There are no textures. Color comes from glTF material factors, so the mesh has no UVs. Godot turns those factors into `StandardMaterial3D` values on import.

Clone with Git LFS installed (`git lfs install` before `git pull`) so `hostile_npc.bin` is the mesh buffer and not an LFS pointer. Godot cannot import the pointer.

## Scale and orientation

Units are meters. The origin is on the ground, between the soles. The soles sit on y = 0.

The figure faces **+Z**, which is the glTF front. Godot 4 uses the same Y-up axis, and its gameplay forward is **-Z**. Yaw the instance 180 degrees around Y before parenting it to a body that moves along -Z.

Approximate bounds of the posed mesh:

- Height 1.84 m (left horn tip)
- Width 1.09 m
- Depth 1.20 m, from the back spikes to the cleaver

The stance is baked. There is no skeleton and no animation. Each mesh node is translated to its joint, so hiding or moving a part moves that part. Rotating a limb node will not bend a skin; it spins the posed piece.

## Scene tree

`HostileNpc` is the scene root. It carries `extras` for `role`, `units`, `origin`, `facing`, and `pose`. The file lists the `GODOT_single_root` extension so Godot 4.7 keeps that node as the imported root instead of adding a parent. Other viewers ignore the extension.

- `Hips` — `Cuirass`, `ChestPlate`, `WarMark`, `Tabard`, `CollarRag`, `Belt`, `Buckle`, `TassetLeft`, `TassetRight`, `BackSpikes`
- `LegLeft` — `ThighLeft`, `ShinLeft`, `KneeLeft`, `BootLeft`
- `LegRight` — `ThighRight`, `ShinRight`, `KneeRight`, `BootRight`
- `Head` — `Neck`, `HelmetDome`, `HelmetBrow`, `HelmetJaw`, `HelmetCheekLeft`, `HelmetCheekRight`, `Visor`, `Crest`, `HornLeft`, `HornRight`
- `ArmLeft` — `ArmUpperLeft`, `ArmLowerLeft`, `ShoulderLeft`, `ElbowLeft`, `PauldronLeft`, `PauldronSpikesLeft`, `HandLeft`, `Buckler`, `BucklerSpike`
- `ArmRight` — `ArmUpperRight`, `ArmLowerRight`, `ShoulderRight`, `ElbowRight`, `PauldronRight`, `PauldronSpikeRight`, `HandRight`, `Cleaver`

`HornRight` is the short horn. `HornLeft` is the long one. `Visor` is the emissive slit (`VisorGlow`) set in a dark recess.

## Materials

| Material | Use |
| --- | --- |
| `IronDark` | Cuirass, helm, greaves, pauldrons, back spikes |
| `Steel` | Breastplate, buckler, cleaver body |
| `ClothCrimson` | Tabard, collar rag, war mark, pauldron rag |
| `ClothDark` | Sleeves, thighs, neck wrap |
| `Leather` | Belt, mitts, boot uppers, cleaver grip |
| `Horn` | Horns, crest, buckle, spikes |
| `VisorGlow` | Visor slit. `emissiveFactor` is set. |
| `CleaverEdge` | Stained cutting edge |

No skin is exposed.

## Use in Godot 4.7

Open the project. Godot imports `res://assets/characters/hostile_npc/hostile_npc.gltf` on its own. This file was imported with Godot 4.7.2 and checked with the Khronos glTF validator (no errors). The editor writes `hostile_npc.gltf.import` beside the asset and a cache under `.godot/`. The cache is gitignored. This folder does not add a collision body or a `CharacterBody3D`.

Instance it from a script you own:

```gdscript
var packed := load("res://assets/characters/hostile_npc/hostile_npc.gltf") as PackedScene
var npc := packed.instantiate()
npc.rotation.y = PI
add_child(npc)
```

A moving body wants its own collision. A capsule about 1.7 m tall and 0.35 m in radius, centered near y = 0.9, matches the torso and legs. The cleaver and horns stick out of that capsule on purpose.

## What this is not

No player mesh, no animation, no import settings committed, and no edits to `project.godot`, scenes, or scripts.
