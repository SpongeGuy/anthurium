# Anthurium — Working Beta Checklist

> **Scope:** Everything needed for a single complete, playable run — from the tutorial room through at least one boss fight and level exit. Systems are grouped by dependency so you can work top-down.

---

## 1. Pip (Player Character)

The current player stand-in is `ecube_beta`. Pip needs his own scene before anything else can be accurately tested from the player's perspective.

- [x] Create `pip.tscn` with all required components (health, ichor, hand, ability manager, facing, movement, camera target, HUD hooks)
- [x] Wire the four ability slots; slots 1 and 2 should be empty by default except for the innate **push** ability
- [ ] Implement the **innate push ability** — a short-range force that doesn't require a shard and is always available
- [ ] Swap `GameMaster` to spawn `pip` as the player instead of `ecube_beta`

---

## 2. Ability Shard System

Shards are the currency of the entire progression loop. Nothing else in the GDD flows properly without them.

- [ ] Create `ability_shard.tscn` — a lightweight `PickupableComponent` entity that carries a reference to an `Ability` script/resource
- [ ] Add a **drop-on-death** hook to `HealthComponent` (or a separate `DeathDropComponent`) so that any creature with a configured shard type spawns one at its position when it dies
- [ ] Implement **picking up a shard** via the hand ability: when the player squeezes (`Action` key) a shard rather than a creature, it installs into the first empty ability slot
- [ ] Implement **discarding an ability** from the pause menu: removing an ability from its slot drops the corresponding shard on the floor
- [ ] Extend the pause-menu HUD (the slide-up panel already exists) with per-slot discard buttons and drag-to-rearrange

---

## 3. Squeeze Mechanic

The hand ability can pick up and throw, but pressing `Action` while holding a creature should fire that creature's signature ability. This is Pip's core combat tool.

- [ ] Add `squeeze()` to `HandComponent` — reads the held entity's first `Ability` and calls `execute()` on it, targeting outward from Pip's facing direction
- [ ] Wire the `Action` input in `PlayerManager` to call `HandComponent.squeeze()` when an entity is held
- [ ] Ensure the ability fires in world space (position + direction come from Pip's hand area and `FacingComponent`)

---

## 4. Tutorial Room

The GDD specifies a locked starting room that teaches pick-up-and-squeeze organically.

- [ ] Design `tutorial_room.tscn` — a small, sealed space carved directly into `WorldGrid` on game start (or as a hard-coded pre-generated layout)
- [ ] Place a **Pick Up / Drop Ability Shard** shard entity in the room at a visible spot
- [ ] Place a **digger creature** (see §5) in the room
- [ ] Place an **Anthurium Flower** part that blocks the only exit
- [ ] The room exit should be a destructible wall tile that only the digger's ability can break; once the digger digs it open, normal dungeon generation begins beyond it
- [ ] `GameMaster` should initialise the tutorial room before running the dungeon generator, or generate the dungeon first and then carve/overwrite a tutorial pocket at the player's start position

---

## 5. Digger Creature

- [ ] Create `digger.tscn` — a simple, passive creature whose signature ability destroys a wall tile in front of it
- [ ] Give it a `PickupableComponent` so Pip can pick it up
- [ ] Its signature ability should be exported as a shard drop (the first shard the player ever gets)

---

## 6. Wall Destruction

The tutorial and much of the mid-game rely on walls being breakable. `CellData` has the data fields; none of the logic exists yet.

- [ ] Add `hardness` and `health` properties to `CellData` (they're documented in the GDD but absent from the class)
- [ ] Add an `inventory: Array[StringName]` property to `CellData` for drops
- [ ] Implement a `damage_wall(coords, amount)` method on `WorldGrid` that subtracts from wall health, applies hardness as a damage multiplier, and on reaching zero converts the cell to `GROUND` and spawns any inventory items
- [ ] Connect hurtboxes/projectiles to `damage_wall()` so any ability that can affect terrain actually does so

---

## 7. Ichor → Damage When Empty

`IchorComponent` drains over time but nothing happens when it hits zero. The GDD is explicit: empty ichor → damage over time.

- [ ] In `IchorComponent._process()`, when `ichor <= 0`, call `HealthComponent.take_damage(starvation_damage * delta)` on the same entity
- [ ] Export `starvation_damage` per-second as a tunable value

---

## 8. Anthurium Phase System

The Anthurium is the game's dynamic time pressure. Phase 2 is the endgame trigger.

### Phase 1 (already partially working — needs polish)

- [ ] Implement **aggression** accumulation: increment `AnthuriumBrain.furor` each frame for every creature within a configurable radius of any active part (use `ProximityDetector` already on parts, or a global scan); increment more steeply when a part is attacked (already wired via `anthurium_react_to_damage`)
- [ ] Wire `furor` and nutrition ratio into `resolve_needed_part()` so high aggression biases toward spawning **spines** and **roots**, low aggression biases toward **leaves** and **shields**
- [ ] Implement **fruit production** on the Flower part: at a nutrition threshold, spawn a `fruit.tscn` entity nearby that creatures (and Pip) can eat
- [ ] Implement **Anthurium eating creatures**: when a Root traps an incapacitated creature, kill it and increase `AnthuriumBrain.max_ichor` by a configured amount

### Phase 2 (not started)

- [ ] Add `ANTHURIUM_TILE` to `CellData.TerrainType`
- [ ] Add a threshold check in `AnthuriumBrain` (or `GameMaster`): when `max_ichor` exceeds a configured value, set a `phase: int` flag to `2` and emit a signal
- [ ] On entering Phase 2: stop fruit production; begin a periodic spread tick where each Anthurium part converts adjacent `GROUND` tiles to `ANTHURIUM_TILE`
- [ ] `ANTHURIUM_TILE` contact damage: any non-Anthurium creature that steps on the tile takes lethal-rate damage (wired through `CellData.contact_damage`)
- [ ] `ANTHURIUM_TILE` spread: each tick, each tile has a chance to corrupt adjacent tiles

---

## 9. Poison / Incapacitation System

The Spine part's mechanic (and future creature interactions) requires a status-effect layer.

- [ ] Create a `StatusComponent` (or extend `IchorComponent`) that tracks active status effects including poison stacks, incapacitation duration
- [ ] Implement **poison**: reduces ichor per second at an amplified rate; at a sufficient stack count, the creature enters `incapacitated` (a new BehaviorState that disables movement and abilities)
- [ ] Implement the **incapacitated BehaviorState** — entity lies still, can be picked up by Roots, wakes up after a duration
- [ ] Wire the Spine hurtbox to apply poison on hit

---

## 10. Root Trap

- [ ] Give the `anthurium_root` part a proximity trigger: when an incapacitated creature enters range, transition to a "trapping" state that holds the creature in place and deals lethal damage over time
- [ ] On creature death inside a Root, emit the nutrition-gain signal to `AnthuriumBrain`

---

## 11. Boss — Mega Cow

- [ ] Create `mega_cow.tscn` — a large PREDATORY CONSUMER creature with a charge ability that destroys wall tiles in its path (reuse/extend `dungeoncube_charge.gd` which already exists for dcube)
- [ ] The charge ability should call `WorldGrid.damage_wall()` on every tile it passes through with enough force to instantly break standard walls

---

## 12. Aura Threshold → Boss Spawn → Level Exit

This is the core win-condition loop for each level.

- [ ] In `GameMaster` (or a new `LevelManager`), subscribe to `EventBus.added_aura_score_to` and track total player aura
- [ ] When aura crosses a configured threshold, call `EntityManager.spawn_safely(&"mega_cow", random_valid_position)` and emit an event that locks the level exit
- [ ] On `anthurium_core_died` *and* `entity_killed` for the Mega Cow, open the **gate** (see below) and force Anthurium into Phase 2
- [ ] Create `gate.tscn` — a destructible or animating wall/door entity placed at a pre-determined exit cell in the dungeon. It opens (becomes passable) only after the boss dies
- [ ] When Pip walks through the gate, trigger level transition (reload `GameMaster.initialize_game()` with an incremented run seed, or load a new scene)

---

## 13. Procedural Creature & Resource Placement

The GDD specifies that creature types, counts, and positions vary each run. `GameMaster` currently hardcodes exact spawns.

- [ ] Create a `LevelConfig` resource (or inline data) that specifies spawn tables: a list of creature types with weights and min/max counts per level
- [ ] Replace the hardcoded spawn loop in `GameMaster.initialize_game()` with a procedural placement pass that samples the spawn table, finds random valid `GROUND` cells away from the player start, and calls `EntityManager.spawn_safely()`
- [ ] Randomise the Anthurium's starting position each run (already a GDD requirement — currently hardcoded to `Vector2(512, 512)`)
- [ ] Randomise nutrition source placement (fruit piles, edible plants, etc.) using a similar pass

---

## 14. Controller Support

The GDD states the game is designed for controllers and does not use the mouse.

- [ ] Map all four action inputs (`primary_action`, `secondary_action`, `ternary_action`, `quaternary_action`) to controller buttons (RT, B, X, Y per GDD)
- [ ] Map movement to Left Stick and D-Pad
- [ ] Map `Back`/`Accept` for menu navigation
- [ ] Verify `PlayerManager` correctly reads both keyboard and joypad inputs without conflict

---

## 15. Prefab Structures (stretch — needed before full beta)

- [ ] Define a `Prefab` resource type: a small 2D array of tile overrides plus a list of entity spawns and a set of unlock criteria (e.g. "requires digger ability")
- [ ] Add a prefab placement pass to `DungeonGenerator` that selects 1–3 prefabs per run and stamps them into valid room space after normal generation

---

## Systems Already Working (reference / do not re-implement)

| System | Location | Status |
|---|---|---|
| Entity/Component composition | `Entity.gd`, `Component.gd` | ✅ solid |
| Brain / Lobe / StateMachine AI | `Brain.gd`, `Lobe.gd`, `StateMachine.gd` | ✅ solid |
| WorldGrid (flood-fill visibility, batching) | `WorldGrid.gd` | ✅ solid |
| Dungeon generator (rooms + L-corridors) | `world_generator.gd` | ✅ functional |
| World + visibility renderers | `WorldRenderer.gd`, `VisibilityRenderer.gd` | ✅ solid |
| Hand / pickup / throw | `HandComponent`, `PickupableComponent` | ✅ solid |
| Health / damage / knockback | `HealthComponent`, `HurtboxComponent`, `KnockbackComponent` | ✅ solid |
| IchorComponent (drain only) | `ichor_component.gd` | ⚠️ drains but no starvation damage |
| Aura + opal scoring + HUD | `PointsInterface`, `GameState`, `UIController` | ✅ solid |
| Navigation (agents, wander states) | `NavigationHelper`, navigate states | ✅ solid |
| Anthurium brain + part registration | `AnthuriumBrain.gd`, `AnthuriumComponent.gd` | ✅ framework solid, Phase 2 missing |
| Furor accumulation on damage | `anthurium_react_to_damage.gd` | ✅ solid |
| Multiple creature scenes | arcbimpy, bimpy, dcube variants, ecube variants, focks | ✅ exist |
| Multiple Anthurium part scenes | core, flower, leaf, spine, thorn, pitcher, grass | ✅ exist |
| Pause / menu slide | `UIHUD.toggle_hud_state()` | ✅ animates; discard UI missing |
| Shaders (hit flash, fog, palette swap) | `assets/shaders/` | ✅ solid |
| Time manager / day cycle | `TimeManager.gd` | ✅ solid |

---

## Clarifying Questions

A few ambiguities in the GDD worth resolving before implementation:

1. **Level count for beta** — Is one level (tutorial → boss → exit) sufficient for the beta, or do you want at least 2–3 distinct levels with scaled difficulty?
2. **Shard slot count** — The GDD says four slots. Should all four be locked at start and unlocked one-by-one via shards, or does Pip begin with the hand ability pre-installed in slot 1?
3. **Pip sprite** — Is Pip's sprite ready, or should the beta use a placeholder? Same question for the Digger and the Mega Cow.
4. **Gate mechanic** — Does the gate require both the boss *and* all Anthurium cores to die, or just the boss?
5. **Anthurium Phase 2 forced on boss spawn** — The GDD says Phase 2 is forced when the boss spawns. Should the Anthurium also *independently* reach Phase 2 through normal nutrition growth, or only through the boss trigger?
