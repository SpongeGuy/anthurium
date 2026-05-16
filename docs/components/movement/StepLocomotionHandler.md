---
title: StepLocomotionHandler
class_name: StepLocomotionHandler
extends: "[[LocomotionHandler]]"
tags:
  - component/movement
---

# StepLocomotionHandler

**Extends:** [[LocomotionHandler]]

A [[LocomotionHandler]] subclass that produces rhythmic, impulse-based movement. Instead of setting velocity continuously, the entity pauses briefly after each step, then lurches forward. This creates a stilted, creature-like gait suited to enemies that should feel weighty or deliberate.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `float` | `step_delay` | `0.75` |
| `float` | `step_power` | `25.0` |
| `float` | `step_factor` | `20.0` |
| `float` | `acceleration` | `450.0` |
| `float` | `friction` | `750.0` |

Inherits `input`, `speed`, `velocity`, `disabled` from [[LocomotionHandler]].

---

## Signals

| Signal | Description |
|---|---|
| `stepping` | Emitted at the moment an impulse is applied — the entity "lifts its foot." |
| `stepped` | Emitted when `step_timer` returns to zero after an impulse — the entity "lands." |

Use these to trigger footstep sounds or animations in sync with actual movement.

---

## Property Descriptions

### `step_delay: float`
Time in seconds the entity must hold an input direction before a step impulse fires. Lower values make movement more responsive; higher values make it feel more lumbering.

---

### `step_power: float`
Multiplier on the impulse velocity target. Combined with `speed`, this determines how far each step launches the entity.

---

### `step_factor: float`
Scales the `acceleration` during the `move_toward` call that applies the impulse. A higher value snaps to target velocity more sharply.

---

### `acceleration: float`
Rate of velocity change when applying a step impulse. Used alongside `step_factor` to control impulse sharpness.

---

### `friction: float`
Local friction applied to `velocity` within the locomotion handler itself, independent of [[PhysicsComponent]]'s friction. Decays locomotion velocity toward zero between steps, creating the pause-lurch rhythm.

> **Note:** This `friction` applies only to `velocity` (the locomotion vector). Knockback and other forces decelerating through `physics_velocity` are still governed by PhysicsComponent's own `friction` property.

---

## See Also
- [[LocomotionHandler]] — base class and authoring guide
- [[NormalLocomotionHandler]] — smooth continuous movement alternative
- [[PhysicsComponent]] — consumes `velocity`
