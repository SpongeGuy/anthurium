---
title: PhysicsComponent
class_name: PhysicsComponent
extends: "[[Component]]"
tags:
  - component/movement
---

# PhysicsComponent

**Extends:** [[Component]]

A [[Component]] that owns and drives all physics simulation for an entity. It combines intentional movement from a [[LocomotionHandler]] with external forces — friction, knockback, and collision responses — then applies the final velocity to the entity via `move_and_slide()`.

PhysicsComponent is the single place where `entity.velocity` is written and `move_and_slide()` is called. No other component should call `move_and_slide()` directly.

---

## Architecture

PhysicsComponent distinguishes between two velocity sources:

| Source | Owner | Description |
|---|---|---|
| `physics_velocity` | PhysicsComponent | External forces: knockback, collision bounce, terrain effects. Subject to friction. |
| `locomotion.velocity` | [[LocomotionHandler]] | Intentional movement from AI or player input. Not subject to friction. |

Each physics frame, the two are summed, applied via `move_and_slide()`, and then `physics_velocity` is extracted back from the result to correctly account for wall deflections.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `bool` | `disabled` | `false` |
| `float` | `friction` | `800.0` |
| `KnockbackComponent` | `knockback` | `null` |
| `WorldInterface` | `world_interface` | `null` |
| `LocomotionHandler` | `locomotion` | `null` |
| `MassComponent` | `mass` | `null` |
| `Vector2` | `physics_velocity` | `Vector2.ZERO` |

---

## Property Descriptions

### `disabled: bool`
**@export** — When `true`, `_physics_process` returns immediately and no movement is applied. The entity freezes in place. Use this rather than removing the component when you need to temporarily halt physics (e.g., a stunned or rooted state).

---

### `friction: float`
**@export** — Deceleration rate applied to `physics_velocity` per second. A higher value makes the entity stop more sharply after being launched. Does **not** affect `locomotion.velocity`, which is managed entirely by the [[LocomotionHandler]].

---

### `knockback: KnockbackComponent`
**@export** — Optional. If assigned, `knockback.knockback_velocity` is added to `physics_velocity` each frame and the component handles bounce deflection on collision.

---

### `world_interface: WorldInterface`
**@export** — Optional. Reserved for terrain-based physics effects (e.g., tile slow, damage-on-contact). Currently a placeholder for future cell terrain handling.

---

### `locomotion: LocomotionHandler`
**@export** — Required for intentional movement. Provides `velocity` each frame. If unset, the entity can still receive knockback but cannot move under its own power.

---

### `mass: MassComponent`
**@export** — Optional. Reserved for mass-dependent calculations such as resistance to knockback. Currently referenced but not yet consumed.

---

### `physics_velocity: Vector2`
The current externally-applied velocity vector. Written to by knockback and collision responses. Decays toward `Vector2.ZERO` each frame due to friction. Do not write to this directly unless you are applying a custom impulse.

To apply an impulse from outside PhysicsComponent:
```gdscript
var phys: PhysicsComponent = entity.get_component(PhysicsComponent)
phys.physics_velocity += impulse_direction * impulse_strength
```

---

## Internal Methods

These are not intended to be called externally but are documented here for clarity when reading or extending the component.

### `physics_update(delta: float) → void`
The main update method, called from `_physics_process`. Runs in order:
1. `_apply_friction` — decays `physics_velocity`
2. `_handle_cell_terrain` — applies tile-based effects (future)
3. `_apply_knockback` — adds knockback velocity
4. Sums `physics_velocity + locomotion.velocity`, calls `move_and_slide()`
5. Extracts the post-slide `physics_velocity` back from `entity.velocity`
6. `_handle_passive_collisions` — applies push responses from other bodies
7. `_handle_bounce_collisions` — bounces knockback velocity off walls

---

## Usage

### Required setup
PhysicsComponent requires the entity to be a `CharacterBody2D` (which `Entity` already extends). Assign at minimum a [[LocomotionHandler]] if the entity should move under its own power.

```
Entity
├── PhysicsComponent    ← assign locomotion, knockback, etc. here
├── NormalLocomotionHandler
└── KnockbackComponent
```

### Applying a one-shot impulse
Any system can push the entity by writing to `physics_velocity`:

```gdscript
func on_explosion_nearby(direction: Vector2, force: float) -> void:
    var phys: PhysicsComponent = entity.get_component(PhysicsComponent)
    if phys:
        phys.physics_velocity += direction * force
```

Friction will naturally decay the impulse over subsequent frames.

---

## See Also
- [[LocomotionHandler]] — provides the intentional movement velocity this component consumes
- [[KnockbackComponent]] — the external force source most commonly paired with PhysicsComponent
- [[MassComponent]] — future integration for mass-based knockback resistance
- [[Component]] — base class
