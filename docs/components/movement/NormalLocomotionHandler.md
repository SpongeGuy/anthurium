---
title: NormalLocomotionHandler
class_name: NormalLocomotionHandler
extends: "[[LocomotionHandler]]"
tags:
  - component/movement
---

# NormalLocomotionHandler

**Extends:** [[LocomotionHandler]]

The simplest [[LocomotionHandler]] subclass. Sets `velocity` directly from `input.move_input_direction` multiplied by `speed` each physics frame. Movement is instant — there is no acceleration or deceleration curve. Stopping is handled by friction in [[PhysicsComponent]].

Use this for creatures or entities that should respond to input immediately with no movement weight.

---

## Properties

Inherits all properties from [[LocomotionHandler]]. No additional properties.

---

## Behavior

Each physics frame, `movement_function()` sets:

```
velocity = speed * input.move_input_direction
```

`move_input_direction` is a normalized `Vector2`. When the input is zero, `velocity` is set to `Vector2.ZERO`.

---

## See Also
- [[LocomotionHandler]] — base class and authoring guide
- [[StepLocomotionHandler]] — rhythmic, impulse-based alternative
- [[PhysicsComponent]] — consumes `velocity`
