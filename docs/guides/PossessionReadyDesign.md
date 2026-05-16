---
title: Possession-Ready Design
tags:
  - guide
---

# Possession-Ready Design

A design philosophy for building entities in Anthurium. Every entity — whether the player will ever control it or not — should be built as if the player *could*.

This is not merely a convenience. It reflects the game's core mechanic: Pip picks up creatures and uses them. Any creature the player can pick up is a creature the player can possess. Designing every entity to be possession-ready means the system works for free, without retrofitting.

---

## The Core Architecture

[[InputComponent]] is the universal intent interface. It is the single point through which all movement direction and ability inputs pass.

```
┌──────────────┐         ┌─────────────────┐         ┌───────────────────┐
│ PlayerManager│ ──────► │  InputComponent │ ──────► │ LocomotionHandler │
└──────────────┘         │                 │         └───────────────────┘
                        │  move_direction │         ┌───────────────────┐
┌──────────────┐         │  press_action() │ ──────► │   AbilityManager  │
│ BehaviorState│ ──────► │ release_action()│         └───────────────────┘
└──────────────┘         └─────────────────┘
```

When a player possesses an entity, [[PlayerManager]] begins writing to that entity's InputComponent. When no player is present, [[BehaviorState|BehaviorStates]] write to it instead. The entity's systems — [[LocomotionHandler]], [[AbilityManager]] — consume from InputComponent without knowing or caring who wrote to it.

**The entity does not change. Only who writes to its InputComponent changes.**

---

## The Two Categories of Constraint

When authoring a [[BehaviorState]], every constraint you impose on input falls into one of two categories:

### Mechanical Constraints
These reflect the creature's *identity*. They apply equally to AI and player.

The Dungeoncube charges in a straight line. When it is charging, `move_input_direction` is set to the charge direction regardless of who controls it — the player cannot steer mid-charge. This is not a limitation of the implementation; it is *what the Dungeoncube is*. A player possessing it discovers this as a meaningful property of the creature.

Mechanical constraints are never gated behind `player_controlled`.

### Coherence Constraints
These exist only because the AI's own states would conflict with each other without them. Setting `move_input_direction = Vector2.ZERO` during a shoot state is not because the creature *cannot* move — it is because the wander logic and the shoot logic would fight each other if both ran simultaneously. A player does not have that problem.

**Coherence constraints should always be gated behind `not input.player_controlled`.**

When in doubt, ask: *does this constraint make the creature more interesting to control, or does it only exist to prevent the AI from contradicting itself?* If the latter, gate it.

---

## The Minimum Constraint Principle

> Never restrict a player-controlled entity beyond what the creature's mechanical identity requires.

Give the player more freedom than the AI would have. Players are more capable and more creative than any scripted behavior. An AI that locks its movement to zero during a shoot state does so for coherence. A player-controlled creature that can move while shooting is discovering new gameplay space.

---

## State Machine Sovereignty

When the player possesses an entity, **the entity's state machine continues to run**. The player does not take over the state machine — they take over the *inputs* that the state machine consumes and responds to.

This means:

- Automated state transitions still fire. If a creature enters a shoot state on a timer, a possessing player will be pulled into that state too.
- States that lock certain abilities still lock them — via [[AbilityManager]]'s `disable()` calls, which apply regardless of who controls the entity.
- Death states, cooldown states, alignment states — all of these are part of the creature's identity and apply to the player equally.

This is a feature, not a limitation. It defines the creature's "feel" when possessed. A player possessing the Dungeoncube must learn to work with its charge rhythm. That rhythm *is* the Dungeoncube.

The developer decides how rigid or flexible that rhythm feels. The framework does not impose a default.

---

## Authoring Guide

When writing a new [[BehaviorState]], follow this checklist for every constraint you introduce:

| Question | Constraint type | What to do |
|---|---|---|
| Does this constrain something that is mechanically part of the creature's identity? | Mechanical | Apply unconditionally |
| Does this constrain input only to prevent AI self-contradiction? | Coherence | Gate behind `not input.player_controlled` |
| Does this automatically set `move_input_direction`? | Input (AI-written) | Gate behind `not input.player_controlled` |
| Does this automatically call `press_action()` / `release_action()`? | Input (AI-written) | Gate behind `not input.player_controlled` |
| Does this disable an ability slot via `ability_manager.disable()`? | Mechanical | Apply unconditionally |
| Does this force a state transition on a timer or signal? | Mechanical | Apply unconditionally |

---

## Worked Example: The Pellet Creature

A creature wanders, then periodically stops and shoots a pellet in a direction before returning to wandering.

### States involved
- `WanderState` — sets `move_input_direction` toward a target; transitions to `ShootState` on a timer
- `ShootState` — faces a direction, uses the shoot ability, transitions back to `WanderState` on `ability.finished`

### In `ShootState`:

```gdscript
@export var input: InputComponent
@export var facing: FacingComponent
@export var ability_manager: AbilityManager
@export var next_state: BehaviorState

func enter() -> void:
    # Mechanical: only the shoot ability is available in this state
    ability_manager.disable(1)
    ability_manager.disable(2)
    ability_manager.disable(3)

    # Coherence: AI picks a direction to face; player aims themselves
    if not input.player_controlled:
        facing.change_direction(pick_target_direction())

    # Coherence: AI fires immediately; player fires when they choose
    if not input.player_controlled:
        input.press_action(0)
        input.release_action(0)

func exit() -> void:
    ability_manager.enable(1)
    ability_manager.enable(2)
    ability_manager.enable(3)
```

**AI path:** enters state → picks direction → fires immediately → `ability.finished` → back to wander.

**Player path:** enters state → player can still move freely → player aims with movement input → player presses the shoot button → `ability.finished` → back to wander. The player knows they need to press the button because only slot 0 is available.

The state transition back to `WanderState` is triggered by `ability.finished` in both cases. The AI fires immediately, so `finished` emits quickly. The player fires when they choose, so `finished` emits on their timing. The state machine structure is identical.

---

## Summary

1. **InputComponent is the only interface.** Everything goes through it.
2. **AI writes to InputComponent. So does the player. The entity doesn't know the difference.**
3. **Gate coherence constraints behind `not input.player_controlled`. Never gate mechanical ones.**
4. **The state machine always runs. Possession is not a takeover — it is a rewrite of the input source.**
5. **Give players more freedom than the AI. They can handle it.**

---

## See Also
- [[Entity]] — the root of all possessable actors
- [[InputComponent]] — the universal intent interface; the architectural basis of this system
- [[AbilityManager]] — manages ability slot availability per state
- [[BehaviorState]] — where possession-awareness is implemented in practice
- [[StateMachine]] — the structure that continues to run during possession
- [[Ability]] — the `finished` signal is key to state transitions in both AI and player paths
