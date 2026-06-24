# Anthurium — Game Loop Implementation Checklist

Cross-referenced against `Game loop.md` and the current codebase.
Items marked ✅ are substantively implemented. Everything else is a gap.

---

## Tutorial

- [ ] Locked starting room containing: Anthurium Flower, Pick Up/Drop Ability Shard, a digger creature
- [ ] Room escape requires picking up digger creature and using its ability to break out
- [ ] Player spawn placed inside tutorial room rather than hardcoded `Vector2(300, 300)`

---

## Ichor

- ✅ Drains over time (`IchorComponent._process`)
- [ ] Damage over time applied to entity when ichor reaches `0`
- [ ] Consumer type replenishment behaviors actually implemented:
  - [ ] `AMBIENT` — replenish passively given a condition
  - [ ] `PROXIMITY` — replenish when near a specific entity type
  - [ ] `CONSUMER` — replenish by eating entities (`EdibleComponent` exists but not wired to ichor)
  - [ ] `ESOTERIC` — unconventional replenishment (creature-specific)

---

## Player / Abilities

- ✅ 4-slot AbilityManager
- ✅ Pick up and throw creatures (`HandComponent`, `AbilityHand`)
- ✅ Squeeze held creature to use its ability (modifier + ability press in `hand.gd`)
- ✅ Ability Shard drop on death (`CreateAbilityShardComponent`)
- ✅ Ability Shard pick-up transfers ability to player
- [ ] Pip's innate push ability
- [ ] Ability discarding from pause menu (UI interaction to drop shard and free slot)
- [ ] Ability slot rearrangement in pause menu

---

## Aura

- ✅ Aura score tracked on `PointsInterface` and `GameState`
- ✅ Score events emitted on `EventBus`
- [ ] Aura multiplier built up by acting in quick succession or causing chain events
- [ ] Diminishing returns on repeated state changes to the same entity

---

## Anthurium

- ✅ All parts exist as scenes: Core, Flower, Grass, Growth Node, Leaf, Pitcher, Spine, Thorn
- ✅ `AnthuriumBrain` tracks active parts, ichor, emotional state variables
- ✅ `AnthuriumGrowthLobe` and `AnthuriumDefaultLobe` drive growth behavior
- ✅ Part registration/deregistration on spawn/death
- [ ] **Aggression property** — drives which parts are prioritized (high aggression → Spines/Roots; low → Leaves/Shields)
  - Aggression increases when creatures are nearby, more so when attacked
  - Aggression inversely proportional to nutrition ratio
- [ ] **Shield part** — protects nearby parts
- [ ] **Root part** — traps incapacitated creatures, slowly kills and eats them
- [ ] **Nutrition system** — Anthurium must have enough nutrition to produce fruit from Flower
- [ ] **Fruit production** — Flower produces random fruit carrying seeds
- [ ] **Seed mechanic** — seeds left alone spawn a new Core
- [ ] **Eating creatures** — when Anthurium consumes a creature, max nutrition grows
- [ ] **Phase 1 → Phase 2 transition** — triggered when max nutrition crosses a threshold
- [ ] **Phase 2** — ceases fruit production; parts begin converting tiles to Anthurium Tiles
- [ ] **Anthurium Tiles** — dangerous tiles that consume creatures on contact; corrupt adjacent tiles over time
- [ ] **Phase 2 rapid spread** — Anthurium forced into Phase 2 (and spreads rapidly) when boss spawns

---

## Creatures

- ✅ `BehaviorClass` enum defined (`PASSIVE`, `REACTIVE`, `PREDATORY`, `FERAL`, `ALOOF`)
- ✅ `ConsumerType` enum defined
- ✅ `CreatureTag` system
- ✅ AI via `Brain`/`Lobe`/`StateMachine` architecture
- [ ] Consumer type behaviors actually drive AI (currently only enum + data, no behavior logic)
- [ ] Creature offspring system — some creatures reproduce given a condition

---

## Boss & Level Progression

- [ ] Aura threshold check — when player reaches threshold, boss spawns at random map position
- [ ] **Mega Cow** boss entity (`PREDATORY`, `CONSUMER`, charge-through-walls ability)
- [ ] Boss death spawns a level exit gate
- [ ] Player escapes through gate → loads next level
- [ ] Run-to-run dynamic elements randomized per level:
  - [ ] Dynamic Anthurium starting position
  - [ ] Creature population varied per run
  - [ ] Resources and nutrition sources varied per run

---

## World & Map

- ✅ Dungeon generator with seeded room placement and corridors
- ✅ `CellData` with terrain types
- ✅ Visibility system (flood-fill room reveal)
- [ ] **Prefab structures** — special rooms containing unique creatures, items, or interactables
- [ ] **Wall tile properties**:
  - [ ] Hardness (damage modifier)
  - [ ] Health (wall destruction when reaches 0)
  - [ ] Inventory (walls can contain hidden items, dropped on destruction)
  - [ ] Interacted (tracks last entity that interacted)
- [ ] **Wall destruction mechanic** — walls take damage and break
- [ ] Resource/nutrition source spawning on map
- [ ] `SpawnManager` enabled — currently returns early in `_dawn_arrived`

---

## Controls

- ✅ Keyboard + controller input mapped
- ✅ `InputComponent` with action system
- [ ] Verify all keybinds from game loop doc are mapped (Ability 1–4, Action, Back, Accept, Modifier)
- [ ] Controller-only play through confirmed (no mouse dependency anywhere)
