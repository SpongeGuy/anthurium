---
title: Brain
class_name: Brain
extends: "[[Component]]"
tags:
  - class/ai
---

# Brain

**Extends:** [[Component]]

A [[Component]] that implements a priority-based utility AI. Brain collects all [[Lobe]] children in its subtree, evaluates them each frame (or on a timer), and switches its [[StateMachine]] to whichever state the highest-priority Lobe recommends.

Brain does not define *what* decisions are available — that is the responsibility of individual [[Lobe]] subclasses. Brain only arbitrates between them.

---

## The Evaluation Loop

Each evaluation cycle, Brain calls `evaluate()` on every registered Lobe. Each Lobe returns `[priority: float, state: BehaviorState]`. Brain selects the Lobe with the highest priority value, writes that Lobe's data to [[Memory]] via `commit()`, and switches the [[StateMachine]] to the recommended state — but only if the state has actually changed.

A Lobe can also force an immediate evaluation at any time by emitting its `changed` signal.

> **Note:** avoid setting the `Brain` to evaluate automatically over time, as this will increase overhead for that particular entity. Instead, try to build Lobes around emitting its `changed` signal, as this is more efficient.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `StateMachine` | `state_machine` | `null` |
| `Memory` | `memory` | `null` |
| `bool` | `periodically_evaluate` | `false` |
| `float` | `time_between_evaluations` | `1.0` |
| `Array[float]` | `personality` | `[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]` |
| `Dictionary[String, Array]` | `last_state` | `{}` |

---

## Methods

| Return Type | Signature |
|---|---|
| `Variant` | `get_lobe(type: Script) → Lobe \| null` |
| `bool` | `has_lobe(type: Script)` |

---

## Property Descriptions

### `state_machine: StateMachine`
**@export** — The [[StateMachine]] Brain will call `switch()` on. Must be assigned in the editor. Typically this is a sibling component on the same entity.

---

### `memory: Memory`
**@export** — The [[Memory]] blackboard that winning Lobes write to via `commit()`. Optional — if unset, the `commit()` step is skipped but evaluation still proceeds.

---

### `periodically_evaluate: bool`
**@export** — When `true`, Brain runs `_evaluate()` on a fixed interval defined by `time_between_evaluations`, in addition to any Lobe-triggered evaluations. Useful for creatures where constant re-evaluation would be expensive.

---

### `time_between_evaluations: float`
**@export** — Interval in seconds between periodic evaluations. Only relevant when `periodically_evaluate` is `true`.

---

### `personality: Array[float]`
A six-element array of floats in the range `[0.0, 1.0]`, randomized on `_ready`. Each index corresponds to a personality trait:

| Index | Trait |
|---|---|
| `[0]` | `aggression` |
| `[1]` | `bravery` |
| `[2]` | `dominance` |
| `[3]` | `energy` |
| `[4]` | `nervous` |
| `[5]` | `sympathy` |

Personality values are available to Lobes via `brain.personality`. Lobes may use these to scale or gate their priority output, creating behavioral variety between instances of the same creature without changing any scene structure.

---

### `last_state: Dictionary[String, Array]`
A read-only snapshot of the most recent evaluation cycle. Maps each Lobe's `name` to the `[priority, state]` array it returned. Populated after every call to `_evaluate()`. Useful for debugging — inspect this at runtime to see what each Lobe is recommending.

---

## Method Descriptions

### `get_lobe(type: Script) → Variant`
Returns the registered [[Lobe]] of the given script type, or `null` if none is registered.

```gdscript
var lobe: HungerLobe = brain.get_lobe(HungerLobe)
```

---

### `has_lobe(type: Script) → bool`
Returns `true` if a Lobe of the given script type is registered with this Brain.

---

## Usage

### Scene structure
Lobes must be placed somewhere in Brain's subtree — they do not need to be direct children, only descendants. Brain recurses through all children on `_ready` to collect them.

```
Entity
├── Brain                  ← assign state_machine and memory here
│   ├── HungerLobe
│   ├── ThreatLobe
│   └── WanderLobe
├── StateMachine
│   ├── IdleState
│   ├── FleeState
│   └── EatState
└── Memory
```

### Writing a Lobe
See [[Lobe]] for the full authoring guide. In short: subclass Lobe, override `evaluate()` to return `[priority, state]`, and emit `changed` whenever relevant data changes.

### Using personality in a Lobe
```gdscript
func evaluate() -> Array:
    var aggression: float = brain.personality[0]
    var priority: float = threat_level * aggression
    return [priority, attack_state]
```

---

## See Also
- [[Lobe]] — the decision units Brain evaluates
- [[StateMachine]] — the FSM Brain drives
- [[Memory]] — the blackboard Lobes write to via `commit()`
- [[BehaviorState]] — the states Brain switches between
