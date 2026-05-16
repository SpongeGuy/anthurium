---
title: Entity
class_name: Entity
extends: CharacterBody2D
tags:
  - class/core
---

# Entity

**Extends:** `CharacterBody2D`

The root class for every actor in the game world. Entity owns a Component registry that allows any Component to retrieve any other Component on the same entity by script type. It also acts as the physics body — all movement ultimately goes through Entity via `move_and_slide()`, called by [[PhysicsComponent]].

All creatures, the player, interactive objects, and Anthurium parts are Entities.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `StringName` | `basename` | (set in `_ready`) |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `add_component(component: Component)` |
| `Variant` | `get_component(type: Script)` |
| `Variant` | `get_components(type: Script)` |
| `bool` | `has_component(type: Script)` |
| `StringName` | `get_basename()` |

---

## Signals

| Signal | Description |
|---|---|
| `entity_initialized` | Emitted after all Components have been registered. Use this to safely defer Component setup that depends on other Components being ready. |

---

## Property Descriptions

### `basename: StringName`
The filename of the entity's scene, without the extension. For example, an entity loaded from `dcube_alpha.tscn` will have `basename = &"dcube_alpha"`. Useful for identification, logging, or data lookups that key on entity type.

---

## Method Descriptions

### `add_component(component: Component) → void`
Registers a [[Component]] to this Entity's internal dictionary, injects `component.entity = self`, and calls `component._on_registered()`. Called automatically for all Component descendants during `_ready()`. Can also be called at runtime to add a Component after initialization — see the Usage section for caveats.

```gdscript
# Runtime addition example
var new_comp: PoisonComponent = PoisonComponent.new()
entity.add_node(new_comp) # add to scene tree first
entity.add_component(new_comp)
```

---

### `get_component(type: Script) → Variant`
Returns the first registered [[Component]] of the given script type, or `null` if none exists. This is the standard way for Components and states to find their siblings.

```gdscript
var health: HealthComponent = entity.get_component(HealthComponent)
if health:
    health.take_damage(10)
```

> **Note:** The argument is the Script resource, not a string. Pass the class name directly as shown above.

---

### `get_components(type: Script) → Variant`
Returns the full `Array` of registered Components of the given type, or `null` if none exist. Use this when an entity may have multiple Components of the same type — for example, multiple [[Hitbox]] instances.

```gdscript
var hitboxes: Array = entity.get_components(Hitbox)
for box in hitboxes:
    box.set_active(false)
```

---

### `has_component(type: Script) → bool`
Returns `true` if at least one [[Component]] of the given type is registered. Use this to safely branch without null-checking the result of `get_component()`.

```gdscript
if entity.has_component(IchorComponent):
    # this entity has ichor
```

---

### `get_basename() → StringName`
Returns the scene filename without extension as a `StringName`. Called once in `_ready()` and cached to `basename`.

---

## Usage

### Scene structure
Place all [[Component|Components]] as children (or deeper descendants) of the Entity root. Entity recurses the entire subtree on `_ready`, so Components can be nested for organizational clarity without losing registration.

```
Entity (Entity.gd)
├── CollisionShape2D
├── Sprite2D
├── CreatureData            ← Component
├── StateMachine            ← Component
│   ├── IdleState           ← BehaviorState (not a Component)
│   └── ChaseState          ← BehaviorState (not a Component)
├── Brain                   ← Component
│   └── HungerLobe          ← Lobe (not a Component)
├── Memory                  ← Component
├── InputComponent          ← Component
├── AbilityManager          ← Component
│   └── ChargeAbility       ← Ability (not a Component)
└── Movement
    ├── PhysicsComponent    ← Component
    └── NormalLocomotionHandler ← Component
```

### Registration order
Components are registered in scene tree order, top to bottom. If Component A's `_on_registered()` calls `entity.get_component(B)`, B must appear above A in the tree. When order cannot be guaranteed, defer setup to `entity.entity_initialized`:

```gdscript
func _on_registered() -> void:
    entity.entity_initialized.connect(_on_entity_ready)

func _on_entity_ready() -> void:
    # all components guaranteed registered here
    var other: OtherComponent = entity.get_component(OtherComponent)
```

### Adding Components at runtime
`add_component()` can register a Component after `_ready()`. The Component must be added to the scene tree first. Be aware that any Component already registered which checked `has_component()` in its own `_on_registered()` will not see the late-added Component unless it re-checks.

### Creating a new entity
1. Create a scene with Entity.gd as the root script.
2. Add a `CollisionShape2D`.
3. Add Components as children — at minimum [[PhysicsComponent]], [[LocomotionHandler]], and [[InputComponent]].
4. For AI-driven entities, add [[StateMachine]] with [[BehaviorState]] children, and optionally [[Brain]] with [[Lobe]] children.
5. Consult [[Possession-Ready Design]] for how to structure states so the entity can be player-controlled.

---

## See Also
- [[Component]] — base class for all Entity children that participate in the registry
- [[Possession-Ready Design]] — philosophy for building entities that can be player-controlled
- [[StateMachine]] — the behavior driver for AI entities
- [[InputComponent]] — the universal intent interface shared by AI and player control
- [[PhysicsComponent]] — handles all movement and `move_and_slide()` calls
