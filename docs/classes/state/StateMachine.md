---
title: StateMachine
class_name: StateMachine
extends: "[[Component]]"
tags:
  - class/state
---

# StateMachine

**Extends:** [[Component]]

A [[Component]] that drives an entity's active behavior by delegating each frame to exactly one [[BehaviorState]] child. States are children of the StateMachine node in the scene tree. Only one state is active at any given time.

StateMachine does not decide *which* state to enter — that responsibility belongs to [[Brain]], which calls `switch()` after evaluating its [[Lobe|Lobes]]. StateMachine is purely an executor and lifecycle manager.

> **Note:** A StateMachine must have at least one [[BehaviorState]] child assigned to `initial_state`. Forgetting this will raise a runtime error.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `BehaviorState` | `current_state` | `null` |
| `BehaviorState` | `initial_state` | `null` |
| `BehaviorState` | `death_state` | `null` |
| `bool` | `enabled` | `true` |

---

## Methods

| Return Type | Signature                          |
| ----------- | ---------------------------------- |
| `void`      | `switch(new_state: BehaviorState)` |
| `void`      | `switch_to_death_state()`          |
| `void`      | `enable()`                         |
| `void`      | `disable()`                        |

---

## Signals

| Signal | Description |
|---|---|
| `state_switched(old_state: BehaviorState, new_state: BehaviorState)` | Emitted immediately before the new state's `enter()` is called. `old_state` may be `null` on the first transition. |
| `just_enabled` | Emitted when `enable()` is called. |
| `just_disabled` | Emitted when `disable()` is called. |

---

## Property Descriptions

### `current_state: BehaviorState`
The state currently being executed. Updated by `switch()`. Do not assign this directly — always use `switch()` to ensure proper lifecycle calls (`exit()` / `enter()`).

---

### `initial_state: BehaviorState`
**@export** — The state entered automatically when the entity is ready. Must be assigned in the editor. Raises a runtime error if not set.

---

### `death_state: BehaviorState`
**@export** — The state entered when `switch_to_death_state()` is called, typically triggered by [[HealthComponent]] reaching zero. Optional; leave unset if the entity does not have a death behavior.

---

### `enabled: bool`
When `false`, `_process` and `_physics_process` are skipped, effectively freezing the state machine without exiting the current state. Use `enable()` and `disable()` rather than setting this directly to ensure signals are emitted.

---

## Method Descriptions

### `switch(new_state: BehaviorState) → void`
Transitions from `current_state` to `new_state`. Calls `current_state.exit()`, emits `state_switched`, sets `current_state`, then calls `new_state.enter()`.

If `new_state` has a `cooldown_timer > 0`, the switch is silently rejected. This prevents a state from being re-entered before it has cooled down.

```gdscript
# Example: manually triggering a transition from another component
var sm: StateMachine = entity.get_component(StateMachine)
sm.switch(sm.death_state)
```

> **Warning:** Switching to the state that is already active will call `exit()` then `enter()` again. Guard against this in [[Brain]] if needed — Brain already does this by comparing `current_state` before calling `switch()`.

---

### `switch_to_death_state() → void`
Convenience wrapper for `switch(death_state)`. Intended to be called by [[HealthComponent]] or similar on entity death.

---

### `enable() → void`
Sets `enabled` to `true` and emits `just_enabled`. Does not re-enter the current state.

---

### `disable() → void`
Sets `enabled` to `false` and emits `just_disabled`. Does not exit the current state — it is merely paused.

---

## Usage

### Setting up a StateMachine
1. Add `StateMachine` as a child of your entity.
2. Add [[BehaviorState]] subclasses as children of StateMachine.
3. Assign `initial_state` (and optionally `death_state`) in the editor.
4. If the entity has a [[Brain]], assign it the same StateMachine via the `state_machine` export.

```
Entity
└── StateMachine         ← assign initial_state and death_state here
    ├── IdleState
    ├── ChaseState
    └── DeathState
```

### Without a Brain
StateMachine can be used standalone without a Brain — states can call `state_machine.switch()` on themselves directly inside `update()` or `exit()`, acting as a classic hand-coded FSM.

---

## See Also
- [[BehaviorState]] — base class for all states; defines the `enter` / `update` / `exit` lifecycle
- [[Brain]] — the AI evaluator that decides which state to switch to
- [[Lobe]] — Brain's subordinate decision units
- [[Component]] — base class

---

## Script Template
A script template for BehaviorState subclasses is available at:
`script_templates/BehaviorState/BehaviorState.gd`
