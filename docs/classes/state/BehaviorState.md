---
title: BehaviorState
class_name: BehaviorState
extends: Node
tags:
  - class/state
---

# BehaviorState

**Extends:** `Node`

The base class for all states managed by [[StateMachine]]. A BehaviorState represents a single, discrete mode of behavior for an entity — such as idling, chasing, or dying. It defines four lifecycle hooks that StateMachine calls at the appropriate moments.

BehaviorState is **not** a [[Component]]. It lives as a direct child of a [[StateMachine]] node and is never registered to `Entity._components`. It cannot be retrieved via `entity.get_component()`.

> **Note:** Never instantiate BehaviorState directly. Always subclass it and override the lifecycle methods you need.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `StateMachine` | `state_machine` | (set in `_ready`) |
| `float` | `cooldown` | `0.0` |
| `float` | `cooldown_timer` | `0.0` |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `enter()` |
| `void` | `update(delta: float)` |
| `void` | `physics_update(delta: float)` |
| `void` | `exit()` |
| `void` | `apply_cooldown()` |

---

## Property Descriptions

### `state_machine: StateMachine`
A reference to the parent [[StateMachine]], resolved automatically in `_ready()`. Use this to call `state_machine.switch()` from within a state.

> **Warning:** If this node's parent is not a StateMachine, a runtime error is raised. Always place BehaviorState nodes as direct children of a StateMachine.

---

### `cooldown: float`
**@export** — The duration in seconds added to `cooldown_timer` when `apply_cooldown()` is called. Set this in the editor to prevent a state from being immediately re-entered after it exits.

---

### `cooldown_timer: float`
**@export** — The remaining cooldown time. Counts down automatically in `_process`. [[StateMachine]] will refuse to switch to this state while `cooldown_timer > 0`. 

Exposed as an export so it can be pre-seeded with a nonzero value in the editor, effectively delaying a state from being entered at all when the entity first spawns.

---

## Method Descriptions

### `enter() → void`
Called by [[StateMachine]] immediately after this state becomes `current_state`. Use this to initialize any state-local variables, play an animation, or register signal connections that should only be active in this state.

Disconnect those same signals in `exit()` to avoid memory leaks or unintended behavior.

```gdscript
func enter() -> void:
    var anim: SpriteAnimator = entity.get_component(SpriteAnimator)
    if anim:
        anim.play("run")
```

---

### `update(delta: float) → void`
Called every `_process` frame by [[StateMachine]] while this state is active. Use for logic that does not require physics — animation decisions, timer countdowns, signal polling.

---

### `physics_update(delta: float) → void`
Called every `_physics_process` frame while this state is active. Use for logic that must be synchronized with physics, such as directing movement via [[LocomotionHandler]] or reading collision results.

```gdscript
func physics_update(delta: float) -> void:
    var locomotion: LocomotionHandler = entity.get_component(LocomotionHandler)
    if locomotion:
        locomotion.velocity = direction * locomotion.speed
```

---

### `exit() → void`
Called by [[StateMachine]] just before switching away from this state. Use this to clean up — stop animations, disconnect signals, reset any values this state set on shared components.

---

### `apply_cooldown() → void`
Adds `cooldown` to `cooldown_timer`. Call this inside `exit()` if you want to prevent the state from being immediately re-entered.

```gdscript
func exit() -> void:
    apply_cooldown()
```

---

## Usage

### Creating a new state
The recommended workflow is to use the script template:
`script_templates/BehaviorState/BehaviorState.gd`

This gives you all four lifecycle stubs pre-generated.

To access entity components from within a state, use `state_machine.entity`:

```gdscript
extends BehaviorState

func enter() -> void:
    var health: HealthComponent = state_machine.entity.get_component(HealthComponent)
```

### Transitioning between states
Call `state_machine.switch()` from within any lifecycle method to trigger a transition. Typically this lives in `update()` after checking a condition:

```gdscript
func update(delta: float) -> void:
    if target_is_in_range():
        state_machine.switch(state_machine.get_node("AttackState"))
```

> **Tip:** Store references to sibling states in exported variables so you aren't calling `get_node()` every frame.

```gdscript
@export var attack_state: BehaviorState

func update(delta: float) -> void:
    if target_is_in_range():
        state_machine.switch(attack_state)
```

---

## See Also
- [[StateMachine]] — the manager that calls into BehaviorState's lifecycle
- [[Brain]] — the AI evaluator; if present, it drives state transitions instead of the states themselves
- [[Lobe]] — Brain's decision units; analogous to BehaviorState in the AI hierarchy

---

## Script Template
`script_templates/BehaviorState/BehaviorState.gd`
