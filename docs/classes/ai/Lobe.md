---
title: Lobe
class_name: Lobe
extends: Node
tags:
  - class/ai
---

# Lobe

**Extends:** `Node`

The base class for all decision units evaluated by [[Brain]]. A Lobe monitors some slice of the entity's world — a nearby threat, a hunger level, a destination — and recommends a [[BehaviorState]] with an associated priority when conditions warrant it.

Lobe is **not** a [[Component]]. It is a subordinate of [[Brain]] and is never registered to `Entity._components`. It cannot be retrieved via `entity.get_component()`.

> **Note:** Never instantiate Lobe directly. Always subclass it and override `evaluate()` at minimum.

---

## The Contract

A Lobe's sole responsibility is to answer the question: *"Given what I know, what should this entity do, and how badly?"*

- It expresses that answer as a `[priority: float, state: BehaviorState]` pair.
- It notifies [[Brain]] of changes by emitting `changed`.
- It may write structured data to [[Memory]] via `commit()`.

Everything else — connecting to signals, caching component references, polling — is implementation detail and up to the Lobe subclass.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `Brain` | `brain` | (set by Brain on registration) |

---

## Signals

| Signal | Description |
|---|---|
| `changed` | Emit this to trigger an immediate evaluation cycle in [[Brain]]. Emit whenever data this Lobe depends on has changed in a way that might change its `evaluate()` output. |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `_on_registered()` |
| `Array` | `evaluate()` |
| `void` | `commit(memory: Memory)` |

---

## Property Descriptions

### `brain: Brain`
Injected by [[Brain]] during registration in its `_ready()`. Use this to access other Lobes or Brain's `personality` array.

```gdscript
var aggression: float = brain.personality[0]
var other_lobe: HungerLobe = brain.get_lobe(HungerLobe)
```

Do not set this manually.

---

## Method Descriptions

### `_on_registered() → void`
Called by [[Brain]] immediately after this Lobe is registered. Override this to perform one-time setup — acquiring component references, connecting signals from other components. This is the correct place for setup logic because `brain` is guaranteed to be set when this is called.

```gdscript
func _on_registered() -> void:
    var health: HealthComponent = brain.entity.get_component(HealthComponent)
    health.health_changed.connect(_on_health_changed)
```

> **Note:** `brain.entity` is available here because Brain is a Component and therefore has an `entity` reference. Access sibling components through `brain.entity.get_component()`.

---

### `evaluate() → Array`
The core method. Called by Brain during each evaluation cycle. Must return an array of exactly two elements:

```
[priority: float, state: BehaviorState]
```

- **`priority`** — A float from `0.0` to `1.0` expressing how strongly this Lobe recommends its state. The Lobe with the highest priority wins the cycle and its state is entered.
- **`state`** — A reference to a [[BehaviorState]] node. Typically stored as an `@export` variable pointing to a node on the [[StateMachine]].

Return `[0.0, null]` (or `[]`) to abstain — this Lobe has nothing to recommend this cycle.

```gdscript
@export var flee_state: BehaviorState

func evaluate() -> Array:
    if threat_nearby:
        return [0.9, flee_state]
    return [0.0, null]
```

---

### `commit(memory: Memory) → void`
Called by Brain on the *winning* Lobe only, after `evaluate()` selects it. Override this to write relevant data to the [[Memory]] blackboard so that [[BehaviorState|BehaviorStates]] can read it.

```gdscript
func commit(memory: Memory) -> void:
    memory.set_value(Memory.Key.TARGET, current_target)
```

Only the winning Lobe's `commit()` is called per cycle. Do not rely on `commit()` being called every frame.

---

## Usage

### Creating a new Lobe
A script template is available at:
`script_templates/Lobe/Lobe.gd`

The typical workflow:
1. Subclass Lobe.
2. Export a reference to the [[BehaviorState]] this Lobe recommends.
3. In `_on_registered()`, acquire component references and connect to their signals.
4. In those signal handlers, update cached data and emit `changed`.
5. In `evaluate()`, return a priority and state based on that cached data.

```gdscript
extends Lobe

@export var flee_state: BehaviorState

var _nearby: NearbyObjectDetector
var threat_nearby: bool = false

func _on_registered() -> void:
    _nearby = brain.entity.get_component(NearbyObjectDetector)
    _nearby.entered.connect(_on_entity_entered)
    _nearby.exited.connect(_on_entity_exited)

func _on_entity_entered(other: Entity) -> void:
    if other.has_component(DamageComponent):
        threat_nearby = true
        changed.emit()

func _on_entity_exited(other: Entity) -> void:
    threat_nearby = false
    changed.emit()

func evaluate() -> Array:
    if not threat_nearby:
        return [0.0, null]
    return [brain.personality[1], flee_state] # scaled by bravery

func commit(memory: Memory) -> void:
    memory.set_value(Memory.Key.TARGET, _nearby.get_closest())
```

### Signal-driven vs. polled evaluation
Prefer **signal-driven** evaluation: connect to component signals in `_on_registered()`, update cached state, emit `changed`. This triggers Brain immediately without waiting for a periodic tick.

Use **polled** evaluation (via Brain's `periodically_evaluate`) only when the relevant data has no signal — for example, reading a raw distance every second rather than tracking enter/exit events.

---

## See Also
- [[Brain]] — registers, evaluates, and arbitrates between Lobes
- [[BehaviorState]] — the states Lobes recommend
- [[Memory]] — the blackboard Lobes write to via `commit()`
- [[StateMachine]] — ultimately driven by Brain's lobe evaluation

---

## Script Template
`script_templates/Lobe/Lobe.gd`
