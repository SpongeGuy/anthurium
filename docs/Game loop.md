# final design of game loop

Play as Pip, a little animal with many tricks up his sleeve. Befriend, defeat, and interact with the many beasts found in Dreamland to survive. Traverse as far as you can throughout Dreamland and discover the mystery of the Anthurium, a ravenous, godlike plant entity which transmutes matter into more of itself.

---

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

### Controls
*Anthurium* is a game meant for controllers and does not make use of the mouse at all.

| Name            | Keybind     | Button   |
| --------------- | ----------- | -------- |
| Movement/Select | WASD        | LS/D-Pad |
| Ability 1       | SPACE       | RT       |
| Ability 2       | P           | B        |
| Ability 3       | O           | X        |
| Ability 4       | I           | Y        |
| Action/Interact | ENTER       | A        |
| Back            | BACKSPACE   | B        |
| Accept          | ENTER/SPACE | A/RT     |

### Abilities
Every creature has four **Ability Slots**. The portable form of an ability is an **Ability Shard**. Technically, every creature can discard abilities. The player can discard an ability by pausing the game and accessing the menu. Pressing a button on an ability will discard it and drop that Ability Shard on the floor, freeing up an Ability Slot. The player is allowed to rearrange their abilities into different slots if they wish. Some abilities can only be used a few times before the shard is destroyed.

### Ichor
> might rename this?
> (ichor dew aether flow shimmer syrup mana mercury argent aura mote vitae)

Every creature has a value which acts as a hunger, energy, and mana resource. The resource is called **Ichor**. Ichor drains over time but can be replenished by consuming food or other special items. It is drained by using special abilities. When Ichor is drained completely, the creature will take damage over time.
> Ichor acts as a drive for creatures to seek food and replenish themselves, making creature behavior more interesting and complex
> Ichor also acts as motivation for the player to not only survive, but also to strategically use abilities only when necessary

### Terrain
Terrain is procedurally generated to appear cavelike.
Terrain is interactable and can be destroyed or created. Tiles have special properties.

Wall tiles:
- hardness: a modifier which alters how much damage the tile takes per hit.
- health: when this reaches zero, the wall is destroyed.
- inventory: stores these items. if destroyed, the wall drops these items.
- interacted: keeps track of what entity last interacted with the tile.

> Walls can have treasure or special items in them.


### Map
The map is generated using a combination of room generation and cavelike noisy generation. The caves should be small enough that gameplay feels cohesive and tense but not overwhelmingly tight to be cramped.

### Vision
The player can only see tiles of the room they are currently in. All entities on invisible tiles are also invisible. There may be rooms beyond walls that are hidden and must be broken into to discover.

### The Anthurium
The Anthurium acts as a natural and dynamic time limit that the player has to work around.
The Anthurium has multiple parts that function differently.

| PART   | DESCRIPTION                                                                                                                                       |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Core   | Acts as the brain of the Anthurium. If all the cores are killed, the plant dies.                                                                  |
| Shield | Protects nearby parts.                                                                                                                            |
| Spine  | Actively tries to stab creatures with its poisonous needles. If a creature is sufficiently poisoned, it passes out.                               |
| Flower | Produces fruit. Fruit carry seeds which produce a new core if left alone. There are a vast number of fruits; a random one is produced every time. |
| Leaf   | Produces extra amounts of nutrition for the Anthurium.                                                                                            |
| Root   | Traps incapacitated creatures and slowly kills them and eats them.                                                                                |
The Anthurium has a property *aggression* which determines what kind of parts the plant grows. The more aggression the plant has, the more likely it produces spines and roots. The less aggression the plant has, the more likely it will produce leaves and shields. Aggression is increased when creatures are nearby a plant part, and is increased even more strongly if a part is attacked. Aggression is also inversely proportional to its nutrition ratio.

The Anthurium must have enough nutrition to produce a fruit from a flower.

Every time the Anthurium eats a creature, its max nutrition grows by an amount.

The plant will grow a tree at the beginning of a level and will very slowly spread. The plant has two phases. It begins in phase 1 and once the Anthurium's max nutrition reaches a threshold, it will enter phase 2 permanently.
1. **Gather Nutrition**
The plant will be aggressive towards creatures and attempt to spread trees to other parts of the map. The plant becomes more aggressive as time elapses. The plant will attempt to consume creatures. Once the plant has gathered enough nutrition, it will move onto its next phase.
During this phase, the plant grows fruits which can feed creatures.
2. **Consume matter**
The plant will cease producing fruit and its parts will begin to transform  nearby tiles into **Anthurium Tiles** which are highly dangerous; creatures that step onto these tiles will be consumed within seconds.
Anthurium Tiles corrupt adjacent tiles over time, transforming them.

### Creatures
There exist a wide variety of creatures. There is a helpful chart to identify them.

| Behavior Class | Description                                                           |
| -------------- | --------------------------------------------------------------------- |
| PASSIVE        | Does not attack other creatures OR flees when nearby other creatures. |
| REACTIVE       | Only retaliates if provoked.                                          |
| PREDATORY      | Actively hunts other creatures to satiate itself.                     |
| FERAL          | Violent towards other creatures.                                      |
| ALOOF          | Does not care about other creatures.                                  |

| Consumer Type | Description                                                 |
| ------------- | ----------------------------------------------------------- |
| AMBIENT       | Ichor is replenished passively over time given a condition. |
| PROXIMITY     | Ichor is replenished when nearby a specific entity.         |
| CONSUMER      | Ichor is replenished by consuming entities                  |
| ESOTERIC      | Ichor is replenished through unconventional means.          |
| EXEMPT        | Does not have ichor.                                        |

Creatures can behave in vastly different ways and/or have mechanics around other existing mechanics. In this way, creatures are the actors and the stage for emergent chaos.

Some creatures will create offspring given a condition.

Some creatures are helpful, and some are harmful. It all depends on what their role is in the ecosystem.

### Aura
The main currency of the game controlling how the game progresses and functions. Aura is gained by performing actions that affect other entities. Any action done by an actor that affects (or alters the state of) a victim gives points to the actor.

Aura can be gained by changing an entity's state. Repeated state changes have diminishing returns.

A multiplier is built up by acting in quick succession or causing chain events.

---

# Completing levels

### Defending yourself
When playing as Pip, you are near the bottom of the food chain; there are creatures that are much more powerful than the player and will hunt you if they are hungry!

Pip is unique in that he is near defenseless on his own, only having an innate push ability. However, Pip starts with the unique ability to **pick up and throw** lightweight creatures and objects, which allows Pip to use external resources to solve situations. Pip can pick up a creature and squeeze it (by pressing the **Action** key) to make it cast its signature ability. Use this technique to kill other creatures, which may drop an Ability Shard imbued with its signature ability.

### Encountering prefabs
Prefab structures can be found in levels. They contain special creatures, items, or interactable entities. Most of the time, these structures can only be found or reached by using a special ability or under certain criteria.

### Progressing to the next level
The player can only leave the level when the main boss of that level is defeated.

To summon the main boss, the player must break an Aura threshold.

Once the player reaches a sufficient amount of Aura, a boss will spawn positioned randomly on the map. The boss must be defeated to open a gate the player must escape through to advance to the next level. Once the boss has been spawned, the Anthurium will be forced into its phase 2 and will begin spreading very rapidly. 


### Boss
There is currently one boss; the **Mega Cow**. This boss is a PREDATORY CONSUMER and has the ability to charge through walls, destroying them.