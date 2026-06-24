g# Creature ideas

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


---

| Name   | Mass | Class/Type         | Description                                                                                                 |
| ------ | ---- | ------------------ | ----------------------------------------------------------------------------------------------------------- |
| Tick   | 0.2  | PASSIVE PROXIMITY  | Breeds quickly. Very skittish.                                                                              |
| Eater  | 1    | PREDATORY CONSUMER | Ticks are his favorite food. Uses a long tongue to grapple things.                                          |
| Spike  | 1    | PASSIVE CONSUMER   | When touched, extends its spikes to stick onto entities, dealing damage.                                    |
| Vacuum | 3    | REACTIVE PROXIMITY | Gains Ichor by being very close to entities. When nearby entities, attempts to pull them in until satiated. |

| Name  | Mass | Class/Type         | Description                                                                                                                     |
| ----- | ---- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| Cow   | 2    | REACTIVE CONSUMER  | Fruit is its favorite food. Headbutts entities that get too close.                                                              |
| Robot | 1    | REACTIVE AMBIENT   | Gains Ichor over time always. Fires lasers when an entity is in line of sight.                                                  |
| Cube  | 10   | ALOOF EXEMPT       | Charges through the dungeon killing anything in its path, only stopping when it hits a wall. Only moves in cardinal directions. |
| Clone | 1    | REACTIVE CONSUMER  | Attacks entities that get too close. When it's hit by something, it clones itself, dividing its current Ichor in half.          |
| Claw  | 0.5  | PREDATORY CONSUMER | Uses its Ichor to move very fast and slice up entities to eat.                                                                  |
