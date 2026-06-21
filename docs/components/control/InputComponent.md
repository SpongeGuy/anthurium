---
title: InputComponent
class_name: InputComponent
extends: "[[Component]]"
tags:
  - component/control
---

# InputComponent

**Extends:** [[Component]]

The universal intent interface for every entity. InputComponent is the single point through which all movement direction and ability inputs pass — whether they originate from the player's hardware or from an AI [[BehaviorState]].

Neither [[LocomotionHandler]] nor [[AbilityManager]] knows or cares who wrote to InputComponent. The player and AI interact with the entity through identical calls. This is the architectural foundation of [[Possession-Ready Design]].

---

## Properties

| Type | Name | Default |
|---|---|---|
| `Vector2` | `move_input_direction` | `Vector2.ZERO` |
| `Array[String]` | `actions` | `["primary_action", "secondary_action", "ternary_action", "quaternary_action"]` |
| `Array[bool]` | `just_pressed` | `[false, false, false, false]` |
| `Array[float]` | `hold_time` | `[0.0, 0.0, 0.0, 0.0]` |
| `Array[bool]` | `is_held` | `[false, false, false, false]` |
| `Array[bool]` | `just_released` | `[false, false, false, false]` |
| `bool` | `player_controlled` | `false` |

---

## Signals

| Signal | Description |
|---|---|
| `input_just_pressed(id: int)` | Emitted when an action transitions from not-held to held. |
| `input_just_released(id: int, held_time: float)` | Emitted when an action transitions from held to not-held. `held_time` is the total duration held in seconds. |

---

## Methods

| Return Type | Signature |
|---|---|
| `void` | `press_action(id: int)` |
| `void` | `release_action(id: int)` |

---

## Property Descriptions

### `move_input_direction: Vector2`
A `Vector2` representing the current movement intent. Typically a normalized cardinal or diagonal direction, but not required to be. Written to directly each frame by whoever controls the entity — either [[PlayerManager]] (reading hardware input) or a [[BehaviorState]] (computing AI direction).

Consumed by [[LocomotionHandler]] subclasses to compute `velocity`.

---

### `actions: Array[String]`
The four Godot input action names mapped to ability slots 0–3. These are the string keys `PlayerManager` passes to `Input.is_action_just_pressed()`. AI-driven entities do not use these strings — they call `press_action()` by index directly.

| Index | Action | Default Binding |
|---|---|---|
| 0 | `primary_action` | Space / RT |
| 1 | `secondary_action` | P / B |
| 2 | `ternary_action` | O / X |
| 3 | `quaternary_action` | I / Y |

---

### `hold_time: Array[float]`
Per-action duration in seconds since the action was pressed. Incremented each frame while `is_held[id]` is `true`, reset to `0.0` on release. Passed to `Ability.on_held()` and `Ability.on_released()` by [[AbilityManager]].

---

### `player_controlled: bool`
`true` when [[PlayerManager]] has assigned this entity as the active player entity. Used by [[BehaviorState|BehaviorStates]] to implement [[Possession-Ready Design]] — states check this flag to decide whether to write input automatically or defer to the player.

Set by `PlayerManager.set_player()`. Do not set manually.

---

## Method Descriptions

### `press_action(id: int) → void`
Transitions action `id` from not-held to held. Sets `is_held[id] = true`, emits `input_just_pressed`, and resets `just_pressed[id]` to `false` on the next frame via `await`.

Guards against double-pressing: if `is_held[id]` is already `true`, the call is ignored.

**Used by:** AI [[BehaviorState|BehaviorStates]] to trigger abilities programmatically.

```gdscript
# Inside a BehaviorState, triggering ability slot 0:
input.press_action(0)
input.release_action(0)
```

---

### `release_action(id: int) → void`
Transitions action `id` from held to not-held. Sets `is_held[id] = false`, emits `input_just_released` with the accumulated `hold_time`, and resets `just_released[id]` on the next frame via `await`.

Guards against double-releasing: if `is_held[id]` is already `false`, the call is ignored.

---

## Usage

### Who writes to InputComponent

| Source | Method |
|---|---|
| **Player** | `PlayerManager._process()` calls `press_action()` / `release_action()` from `Input` polling, and writes `move_input_direction` from `Input.get_vector()` |
| **AI State** | [[BehaviorState]] subclasses write `move_input_direction` directly and call `press_action()` / `release_action()` |

The entity's systems — [[LocomotionHandler]], [[AbilityManager]] — read from InputComponent without knowing the source. This is the entire point.

### Who reads from InputComponent
- [[AbilityManager]] — listens to `input_just_pressed` and `input_just_released` signals to trigger [[Ability]] hooks
- [[LocomotionHandler]] subclasses — read `move_input_direction` in `movement_function()`
- [[BehaviorState|BehaviorStates]] — read `player_controlled` to decide whether to automate inputs

### Writing AI input from a state
```gdscript
func physics_update(delta: float) -> void:
	# AI sets direction directly
	if not input.player_controlled:
		input.move_input_direction = facing.get_direction()
	# If player_controlled, the player has already written move_input_direction
	locomotion.movement_function(delta)
```

### Triggering an ability from a state
```gdscript
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0 and not input.player_controlled:
		input.press_action(0)
		input.release_action(0)
```

See [[Possession-Ready Design]] for the full philosophy on when to gate behind `player_controlled`.

---

## See Also
- [[AbilityManager]] — listens to InputComponent signals and routes them to [[Ability]] nodes
- [[LocomotionHandler]] — reads `move_input_direction` to compute velocity
- [[PlayerManager]] — writes to InputComponent when the player is in control
- [[Possession-Ready Design]] — the design philosophy built on InputComponent as universal intent interface
- [[Component]] — base class
