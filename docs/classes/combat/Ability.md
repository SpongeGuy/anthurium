---
title: Ability
class_name: Ability
extends: Node
tags:
  - class/combat
---

# Ability

**Extends:** `Node`

The base class for all special abilities. An Ability defines what happens when a creature uses one of its four ability slots. It exposes three input hooks — `on_pressed`, `on_held`, `on_released` — and a separate `execute()` / `_execute()` pair for direct programmatic triggering.

Ability is **not** a [[Component]]. It is a subordinate of [[AbilityManager]] and is never registered to `Entity._components`. It cannot be retrieved via `entity.get_component()`.

> **Note:** Never instantiate Ability directly. Always subclass it and override the hooks you need.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `Entity` | `entity` | (resolved from parent in `_ready`) |
| `AbilityManager` | `manager` | (resolved from parent in `_ready`) |
| `float` | `cooldown` | `0.0` |
| `float` | `cast_time` | `0.0` |
| `bool` | `disabled` | `false` |
| `Texture2D` | `icon` | `null` |

---

## Signals

| Signal | Description |
|---|---|
| `finished` | Emit this when the ability's effect is complete. Used by [[BehaviorState|BehaviorStates]] and UI to know when the ability has resolved. Not emitted automatically — the subclass is responsible for emitting it. |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `on_pressed()` |
| `void` | `on_held(hold_duration: float, delta: float)` |
| `void` | `on_released(hold_duration: float)` |
| `void` | `execute()` |

---

## Internal Methods

| Return Type | Signature |
|---|---|
| `void` | `_execute()` |

---

## Property Descriptions

### `entity: Entity`
The [[Entity]] this Ability belongs to, resolved by walking up from AbilityManager's parent. Available as a shortcut to avoid calling `manager.entity` repeatedly.

---

### `manager: AbilityManager`
The [[AbilityManager]] that owns this Ability. Use this to access sibling abilities or to check slot state.

---

### `cooldown: float`
**@export** — Duration in seconds before this ability can fire again after `execute()` is called. Counted down in `_process`. `execute()` will silently return if the cooldown has not expired.

---

### `cast_time: float`
**@export** — An exported hint value indicating how long the player must hold the input before the ability fires. AbilityManager does not enforce this automatically — the Ability subclass uses `hold_duration` in `on_held()` or `on_released()` to implement cast time behavior.

---

### `disabled: bool`
**@export** — When `true`, `execute()` returns immediately without calling `_execute()`. This is a per-ability override, independent of [[AbilityManager]]'s per-slot `disable()`. Use it to permanently gate an ability without touching the manager.

---

### `icon: Texture2D`
**@export** — The visual representation of this ability in the UI. Used by the HUD and the pause menu ability rearrangement screen.

---

## Method Descriptions

### `on_pressed() → void`
Called by [[AbilityManager]] the moment the corresponding input transitions from not-held to held. Use for abilities that activate immediately on press, or to begin a charge-up effect.

```gdscript
func on_pressed() -> void:
    # begin charging animation
    entity.get_component(SpriteAnimator).play("charge")
```

---

### `on_held(hold_duration: float, delta: float) → void`
Called by [[AbilityManager]] every frame while the input is held. `hold_duration` is the total time in seconds the input has been held. Use this to implement hold-to-charge abilities.

```gdscript
func on_held(hold_duration: float, delta: float) -> void:
    if hold_duration >= cast_time:
        execute()
```

---

### `on_released(hold_duration: float) → void`
Called by [[AbilityManager]] when the input is released. `hold_duration` is the total time held. Use for abilities that fire on release, or that scale their effect based on charge time.

```gdscript
func on_released(hold_duration: float) -> void:
    var power: float = clamp(hold_duration / cast_time, 0.0, 1.0)
    _launch_projectile(power)
```

---

### `execute() → void`
A direct trigger that bypasses the input hooks. Checks `disabled` and cooldown before calling `_execute()` and setting the cooldown timer. Use this when a [[BehaviorState]] needs to fire the ability programmatically outside the normal input flow — for example, an AI-controlled entity triggering an ability at the end of a charge-up state.

```gdscript
# In a BehaviorState, after AI decides to fire:
ability_manager.get_ability_from_id(0).execute()
```

---

### `_execute() → void`
The actual implementation hook. Override this with the ability's effect. Only called by `execute()` after passing cooldown and disabled checks. Do not call this directly — always go through `execute()`.

```gdscript
func _execute() -> void:
    var projectile: Entity = preload("res://scenes/entities/pellet.tscn").instantiate()
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = entity.global_position
    finished.emit()
```

---

## Usage

### Choosing the right hook
| Scenario | Hook to use |
|---|---|
| Instant-on-press ability | `on_pressed()` |
| Hold-to-charge, fire on release | `on_held()` + `on_released()` |
| AI or state directly triggers it | `execute()` + `_execute()` |
| Charge-based with cast time | `on_held()` checking `hold_duration >= cast_time`, call `execute()` |

### Emitting `finished`
Always emit `finished` when the ability's effect resolves. [[BehaviorState|BehaviorStates]] that automate ability usage connect to this signal to know when to proceed:

```gdscript
func enter() -> void:
    var ability: Ability = ability_manager.get_ability_from_id(0)
    ability.finished.connect(_on_ability_finished, CONNECT_ONE_SHOT)
    ability.execute()

func _on_ability_finished() -> void:
    state_machine.switch(next_state)
```

### Scene placement
Ability nodes should be children of [[AbilityManager]] and assigned to its `abilities` export array:

```
AbilityManager
├── ChargeAbility    ← abilities[0]
└── ShieldAbility    ← abilities[1]
```

---

## See Also
- [[AbilityManager]] — the Component that owns and dispatches to Ability nodes
- [[InputComponent]] — the source of input events that trigger ability hooks
- [[Possession-Ready Design]] — how abilities interact with player vs. AI control
- [[Component]] — not a base class of Ability, but the contrast is important; see [[Component#Component vs. class subordinates]]

---

## Script Template
`script_templates/Ability/Ability.gd`
