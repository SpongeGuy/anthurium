---
title: Component
class_name: Component
extends: Node
tags:
  - class/core
---

# Component

**Extends:** `Node`

The base class for all modular building blocks of an [[Entity]]. Components are added as children of an Entity in the scene tree. On `_ready`, Entity recursively walks its subtree, finds every Component, registers it to its internal dictionary, injects the `entity` reference, and calls `_on_registered()`.

A Component's primary purpose is to express a single, focused behavior or data concern and to expose it to other Components through the shared `entity` reference.

> **Note:** Do not use Component directly. Subclass it and override `_on_registered()` to acquire references to sibling Components and connect any necessary signals.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `Entity` | `entity` | (injected by Entity on registration) |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `_on_registered()` |

---

## Property Descriptions

### `entity: Entity`
A reference to the [[Entity]] this Component belongs to. Injected automatically by `Entity.add_component()` before `_on_registered()` is called. Use this to access sibling Components:

```gdscript
var health: HealthComponent = entity.get_component(HealthComponent)
```

Do not set this manually.

---

## Method Descriptions

### `_on_registered() → void`
Called by [[Entity]] immediately after this Component is registered and `entity` has been injected. This is the correct place for all setup logic — acquiring sibling Component references, connecting signals, and initializing state that depends on the entity being fully assembled.

```gdscript
func _on_registered() -> void:
    var health: HealthComponent = entity.get_component(HealthComponent)
    if health:
        health.died.connect(_on_entity_died)
```

> **Warning:** `_on_registered()` is called in scene tree order during `Entity._ready()`. If Component A depends on Component B, B must appear earlier in the scene tree than A, or you must defer access to B using `entity.entity_initialized` signal.

---

## Usage

### Authoring a new Component
A script template is available at:
`script_templates/Component/Component.gd`

The typical workflow:
1. Extend Component and give it a `class_name`.
2. Override `_on_registered()` for setup.
3. Add it as a child of an Entity in the scene tree — registration is automatic.

```gdscript
extends Component
class_name ExampleComponent

var _health: HealthComponent

func _on_registered() -> void:
    _health = entity.get_component(HealthComponent)
```

### What belongs in a Component
A Component should own one concern: a single resource (health, ichor), a single behavior (locomotion, facing), or a single interface (input, abilities). If a Component is growing methods that belong to different concerns, split it.

### Component vs. class subordinates
Not every Node child of an Entity is a Component. [[BehaviorState]], [[Lobe]], and [[Ability]] extend `Node` directly — they are subordinates of a specific parent system ([[StateMachine]], [[Brain]], [[AbilityManager]]) and are never registered to `Entity._components`. The distinction: if something should be retrievable via `entity.get_component()`, it is a Component. If it only makes sense in the context of one specific parent, it is not.

---

## See Also
- [[Entity]] — registers Components and provides the `get_component()` API
- [[BehaviorState]] — a Node subordinate, not a Component
- [[Lobe]] — a Node subordinate, not a Component
- [[Ability]] — a Node subordinate, not a Component

---

## Script Template
`script_templates/Component/Component.gd`
