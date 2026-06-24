# in progress design of game loop


# Start
### Tutorial

The game should not need a tutorial to play; the controls should be intuitive and there should be effects that lead the player in the correct direction for progression.

At the beginning of the game, the player is locked in a small room with an Anthurium Flower, the **Pick Up / Drop** Ability Shard and a digger creature.
The player must activate the shard, then pick up the digger creature and use its ability to escape the room.

## Dynamic Elements
From run to run, these things change:
- Map layout
- Prefab structures
- Creatures inhabiting the map
- Resources on the map
- Nutrition sources
- Starting position of the Anthurium


---

# Game Mechanics



### Ichor
> might rename this?
> (ichor dew aether flow shimmer syrup mana mercury argent aura mote vitae)

Every creature has a value which acts as a hunger, energy, and mana resource. The resource is called **Ichor**. Ichor drains over time but can be replenished by consuming food or other special items. It is drained by using special abilities. When Ichor is drained completely, the creature will take damage over time.
> Ichor acts as a drive for creatures to seek food and replenish themselves, making creature behavior more interesting and complex
> Ichor also acts as motivation for the player to not only survive, but also to strategically use abilities only when necessary


Creatures can behave in vastly different ways and/or have mechanics around other existing mechanics. In this way, creatures are the actors and the stage for emergent chaos.

Some creatures will create offspring given a condition.

Some creatures are helpful, and some are harmful. It all depends on what their role is in the ecosystem.

### Aura
The main currency of the game controlling how the game progresses and functions. Aura is gained by performing actions that affect other entities. Any action done by an actor that affects (or alters the state of) a victim gives points to the actor.

Aura can be gained by changing an entity's state. Repeated state changes have diminishing returns.

A multiplier is built up by acting in quick succession or causing chain events.

---

# Completing levels





### Progressing to the next level
There has been a natural event triggered by creature(s), the Anthurium, special terrain, or a timer, triggering a boss event.

The boss event will have a special objective that the player must complete in order to complete the round.

### Minor Event
todo

### Final Event
todo