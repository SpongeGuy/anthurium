---
title: AbilityManager
class_name: AbilityManager
extends: "[[Component]]"
tags:
  - component/control
---

# AbilityManager

**Extends:** [[Component]]

A [[Component]] that routes [[InputComponent]] signals to the correct [[Ability]] node. AbilityManager owns the four ability slots, listens to `input_just_pressed` and `input_just_released` from [[InputComponent]], and calls the corresponding Ability hooks (`on_pressed`, `on_held`, `on_released`).

AbilityManager does not contain any ability logic itself. It is a dispatcher. All logic lives in [[Ability]] subclasses.

---

## Properties

| Type | Name | Default |
|---|---|---|
| `Array[Ability]` | `abilities` | `[]` |
| `InputComponent` | `input` | `null` |
| `IchorComponent` | `ichor_component` | `null` |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `enable(id: int)` |
| `void` | `disable(id: int)` |
| `Ability` | `get_ability_from_id(id: int)` |
| `Ability` | `get_ability_from_string(action: String)` |

---

## Property Descriptions

### `abilities: Array[Ability]`
**@export** — The four ability slots, indexed 0–3. Each element is an [[Ability]] node, or `null` if that slot is empty. The index corresponds directly to [[InputComponent]]'s action indices — slot 0 fires when action 0 is pressed.

[[Ability]] nodes should be children of AbilityManager in the scene tree, though they may also live elsewhere and be assigned manually.

---

### `input: InputComponent`
**@export** — The [[InputComponent]] to listen to. Connected in `_ready()` — signals from this component drive all ability dispatch. Must be assigned.

---

### `ichor_component: IchorComponent`
**@export** — Optional. Reserved for ichor cost checking before ability execution. Currently referenced but not yet consumed — future abilities will query this to gate on ichor availability.

---

## Method Descriptions

### `enable(id: int) → void`
Re-enables ability slot `id`. Enabled slots dispatch to their [[Ability]] when input arrives. All slots start enabled.

---

### `disable(id: int) → void`
Disables ability slot `id`. While disabled, input events for that slot are silently dropped — `on_pressed`, `on_held`, and `on_released` will not be called.

Used by [[BehaviorState|BehaviorStates]] to restrict which abilities are available during a given state, regardless of player or AI control.

```gdscript
# In a state's enter() — only slot 0 is usable
func enter() -> void:
    ability_manager.disable(1)
    ability_manager.disable(2)
    ability_manager.disable(3)

func exit() -> void:
    ability_manager.enable(1)
    ability_manager.enable(2)
    ability_manager.enable(3)
```

---

### `get_ability_from_id(id: int) → Ability`
Returns the [[Ability]] in slot `id`, or `null` if the slot is empty.

---

### `get_ability_from_string(action: String) → Ability`
Returns the [[Ability]] mapped to the given action name string (e.g. `"primary_action"`). Performs a binary search against `InputComponent.actions` to resolve the index.

---

## Scene Structure

[[Ability]] nodes are typically placed as children of AbilityManager and assigned to slots via the `abilities` export array in the editor:

```
Entity
└── AbilityManager         ← assign input, abilities array here
    ├── ChargeAbility       ← Ability (slot 0)
    ├── ShieldAbility       ← Ability (slot 1)
    └── TeleportAbility     ← Ability (slot 2)
```

Slot 3 left `null` means that ability button does nothing for this entity.

---

## Usage

### Ability lifecycle per input event
For each frame, AbilityManager checks `InputComponent.is_held` for every slot and calls `on_held()` on any ability whose slot is held and enabled. On `input_just_pressed`, it calls `on_pressed()`. On `input_just_released`, it calls `on_released()` with the total hold duration.

This means a single ability can respond differently to a tap versus a hold — see [[Ability]] for details.

### State-driven slot control
A common pattern is for a [[BehaviorState]] to `disable()` all slots except the one it wants to expose, and `enable()` them again on `exit()`. This ensures the entity cannot accidentally fire an inappropriate ability during a restricted state, whether player-controlled or not.

Disabling a slot is a mechanical constraint that applies to the player too — by design, since it reflects the creature's identity in that state.

---

## See Also
- [[Ability]] — the base class for all ability logic; subordinate to AbilityManager
- [[InputComponent]] — the source of all input events AbilityManager listens to
- [[Possession-Ready Design]] — how ability availability interacts with player control
- [[Component]] — base class
