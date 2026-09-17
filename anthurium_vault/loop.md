---
kanban_order: W0I
---
# Game Loop
### Micro-loop
The player must constantly monitor their **Ichor**, which is a resource much like saturation/hunger that slowly drains over time. If an entity has 0 ichor, they will slowly starve until death.

The player must constantly search for new food sources which replenish Ichor; either smaller animals to hunt, fruit, or edible plants.

The player must be cautious and avoid potential threats, as there are stronger animals that hunt the player. Chances are, the player will need to use abilities to escape or defeat more powerful creatures, which depletes ichor.

The player can find items (consumable entities that cast abilities) or ability shards (more permanent and portable than items) which make surviving easier, but most of these cost ichor to use. Using some items or shards will deplete the player's ichor, encouraging them to find a more stable source of ichor.

### Meso-loop
The player will experience three "phases", which are arbitrary states of the game board. This is a sandbox game, so the player has multiple ways of playing and surviving.
##### Phase 1 (minute 1-2)
- the player will explore and forage for food
- take note of all the creatures on the map
- learn where the anthurium has been positioned
- gather their first ability shard
##### Phase 2 (minute 3-5)
- the player will most likely get familiar with and utilize the creatures' mechanics. 
- this is probably the most interesting phase, where the player can abuse certain mechanics to maximize their aura.
- bloom events are common, so the player will have to find a stable source of ichor to survive.
- the player is probably directly interacting with the anthurium to gain resources, influence the environment, and guide the anthurium to bloom in the way they want it to.
##### Phase 3 (minute 6+)
- the game board is being bombarded
- the player has all of their ability slots full.
- the player has their last chance to manipulate the anthurium to perform their preferred final bloom.

After a final bloom, the results screen will be shown to the player. This screen appraises the game board at the time of completion, tallying up Aura. The player is then given the option to continue or quit. If the player continues, a new round will begin and Phase 1 will start once more.

### Macro-loop
The player begins a game by selecting the PLAY option on the main menu. When this occurs, a game board will be populated by randomly selected entities, procedurally generated terrain, the anthurium, and prefabricated structures. Then the player will spawn in the biggest cave on the map.

A round is typically seven minutes long, where a game (multiple rounds) can theoretically go on infinitely as long as the player is infinitely skilled. The game is most likely soft-capped at around an hour because then it gets too hard.

When a final bloom is complete, a new round will begin if the player chooses to continue.

Subsequent rounds are different and harder due to some factors:
- The Anthurium's heartbeat grows faster
- The Anthurium's *Esoterica* values are initialized at higher base values
- Rarer and more dangerous creatures are more likely to appear

The game is over when the player dies; the player is shown the final results screen. This is where the player is shown the things they may have unlocked by achieving certain feats while playing. The player is then prompted to go back to the main menu where they can choose to play again if they wish.

The player's aim is to gain as much Aura as possible. If the player dies, all the Aura that was gained throughout every round the player completed is tallied up to a final score.

The player can view a scoreboard showing their highest scores.

The player can view a bestiary (filled up as the player encounters creatures) which can be viewed in the main menu.