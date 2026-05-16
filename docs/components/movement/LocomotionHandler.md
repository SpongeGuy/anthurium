---
title: LocomotionHandler
class_name: LocomotionHandler
extends: "[[Component]]"
tags:
  - component/movement
---

# LocomotionHandler

**Extends:** [[Component]]

The abstract base class for all intentional movement components. A LocomotionHandler computes a desired `velocity` each frame based on input, AI direction, or its own internal logic. That velocity is then consumed by [[PhysicsComponent]] and applied to the entity.

LocomotionHandler does not call `move_and_slide()` itself — it only produces a velocity vector. [[PhysicsComponent]] is always responsible for applying movement to the entity.

> **Note:** Do not use LocomotionHandler directly. Use a subclass such as [[NormalLocomotionHandler]] or [[StepLocomotionHandler]], or author your own.

---

## Subclasses

| Class | Description |
|---|---|
| [[NormalLocomotionHandler]] | Smooth, direct movement. Velocity is set instantly from input direction. |
| [[StepLocomotionHandler]] | Impulse-based stepping movement with configurable rhythm and delay. |

---

## Properties

| Type | Name | Default |
|---|---|---|
| `InputComponent` | `input` | `null` |
| `float` | `speed` | `500.0` |
| `Vector2` | `velocity` | `Vector2.ZERO` |
| `bool` | `disabled` | `false` |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `_on_registered()` |
| `void` | `movement_function(delta: float)` |

---

## Property Descriptions

### `input: InputComponent`
**@export** — The [[InputComponent]] this handler reads from. Provides `move_input_direction`, a normalized `Vector2` reflecting current movement intent, whether from player input or AI direction-setting.

---

### `speed: float`
**@export** — The base speed scalar, in pixels per second. How this is applied depends on the subclass — for NormalLocomotionHandler it is a direct multiplier; for StepLocomotionHandler it scales impulse power.

---

### `velocity: Vector2`
The computed intentional movement velocity for this frame. Written by `movement_function()`, read by [[PhysicsComponent]]. This is **not** subject to friction — it represents a continuous intent, not a decaying force.

Do not write to this from outside the LocomotionHandler unless you are building a custom controller that bypasses the normal input flow.

---

### `disabled: bool`
**@export** — When `true`, `_physics_process` sets `velocity` to `Vector2.ZERO` and returns. The entity stops moving under its own power but is still affected by physics forces through [[PhysicsComponent]].

---

## Method Descriptions

### `_on_registered() → void`
Called by [[Entity]] after this component is registered. Override in subclasses to acquire component references or connect signals. The base implementation is a no-op.

---

### `movement_function(delta: float) → void`
The core override point. Subclasses implement this to compute and assign `velocity` each physics frame. The base implementation is a no-op.

> **Warning:** The base `_physics_process` in LocomotionHandler only sets `velocity = Vector2.ZERO` when disabled. Subclasses must call `movement_function()` themselves in their own `_physics_process`, or call `super()` with care — check the subclass implementation.

---

## Authoring a Custom LocomotionHandler

To create a new movement style, extend LocomotionHandler and override `movement_function()`:

```gdscript
extends LocomotionHandler
class_name OrbitLocomotionHandler

@export var orbit_target: Node2D
@export var orbit_radius: float = 100.0
var orbit_angle: float = 0.0

func movement_function(delta: float) -> void:
    orbit_angle += delta * speed * 0.01
    var target_pos: Vector2 = orbit_target.global_position
    var desired_pos: Vector2 = target_pos + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
    var direction: Vector2 = (desired_pos - entity.global_position).normalized()
    velocity = direction * speed
```

The only contract is: by the end of `movement_function()`, `velocity` should reflect where the entity intends to go this frame.

---

## See Also
- [[NormalLocomotionHandler]] — smooth continuous movement subclass
- [[StepLocomotionHandler]] — rhythmic impulse-based movement subclass
- [[PhysicsComponent]] — the consumer of `velocity`; handles all `move_and_slide()` calls
- [[InputComponent]] — the source of `move_input_direction`
- [[Component]] — base class
