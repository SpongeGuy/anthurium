# Anthurium

### Capstone
> The goal of this capstone is to release a small yet finished and polished version of this game onto itch.io by Christmas of 2026.
> This project will teach me more about the development cycle, designing good systems for iteration, what makes a game fun, and the process of promoting and releasing a game on a popular platform.

> Ming Chen is quite knowledgeable about the development cycle (specializing in video games, which this project is obviously related to) and puts much importance on planning and designing before implementation, which I believe to be quite important and yet is a skill that I lack.

Play as Pip, a little animal with many tricks up his sleeve. Befriend, defeat, and interact with the many beasts found in Dreamland to survive. Survive as long as you can throughout Dreamland and discover the mystery of the Anthurium, a mysterious ancient reality-warping plant deity.

*Anthurium* is a modern top-down survival and exploration arcade game with low fidelity graphics and a bizarre, familiar yet otherworldly aesthetic. *Anthurium* leans into emergent gameplay elements, where simple elements come together to make an experience much much greater than the sum of its parts. A significant portion of the game is a sandbox involving a variety of creatures, all of which have their own unique needs, abilities, and behaviors.

While experiencing _Anthurium_, the player will play out the fantasy of being the protagonist at the center of a charmingly esoteric mystery, the fantasy of being a little animal in a wild and fantastical ecosystem, and if the player becomes sufficiently talented at the game, the fantasy of knowing how to effectively utilize in-game tools and systems to maximize a final score’s value.

The player's goal is to survive until the Anthurium's final bloom; an event that is built up to throughout a round of the game. A round is typically five minutes, but can be slowed down or accelerated through different methods.

The Anthurium itself is a strange, ever-changing collection of plants, which can change the state of the game in various ways. The Anthurium, depending on its mood, can either feed surrounding animals, go on the offensive, spawn more animals, expand and grow, or many other things. Over time, the Anthurium builds up power eventually leading to a BLOOM EVENT, which is a semi-randomly chosen event the player must survive or solve in order to complete the round. (The Anthurium will give visual and auditory cues on which event will occur as the round progresses).

_Anthurium_ will be playable on PC through itch.io. Eventually, _Anthurium_ has the capability of being launched on consoles; _Anthurium_ is a controller-only game created using the Godot engine, so porting to different platforms will be a trivial task.



---
# Controls
*Anthurium* is a game meant for controllers and does not make use of the mouse at all.

## Game Controls
These are keymaps relating to controlling a beast while playing the game.

| Name                   | Button   |
| ---------------------- | -------- |
| Movement/Select        | LS/D-Pad |
| Ability 1              | A        |
| Ability 2              | B        |
| Ability 3              | X        |
| Ability 4              | Y        |
| Modifier               | LT       |
| Action (Context Aware) | RB       |
## Menu Controls
tbd

---
# Game Loop
### Defending yourself
When playing as Pip, you are near the bottom of the food chain; there are creatures that are much more powerful than the player and will hunt you if they are hungry!

Pip is unique in that he is near defenseless when he initially spawns in, only having a push ability and the unique ability to **pick up and throw** lightweight creatures and objects, which allows Pip to use external resources to solve situations. Pip can pick up a creature and squeeze it (by pressing the **Action** key) to make it cast its signature ability. Use this technique to interact with the environment OR kill creatures to steal their ability shards for yourself!

### Map
The map is generated using a combination of room generation and cavelike noisy generation. The caves should be small enough that gameplay feels cohesive and tense but not overwhelmingly tight to be cramped.

### Terrain
Terrain is procedurally generated to appear cavelike.
Terrain cells are interactable and can be destroyed or created. Tiles have special properties.

Wall tiles:
- hardness: a modifier which alters how much damage the tile takes per hit.
- health: when this reaches zero, the wall is destroyed.
- inventory: stores these items. if destroyed, the wall drops these items.
- interacted: keeps track of what entity last interacted with the tile.

> Walls can have treasure or special items in them.

> If there are special zones or environments behind walls, there should be visual cues of a hidden area (cracks, particles, etc.)

### Encountering prefabs
Prefab structures can be found in levels. They contain special creatures, items, or interactable entities. Most of the time, these structures can only be found or reached by using a special ability or under certain criteria.

### Vision
The player can only see tiles of the room they are currently in. All entities on invisible tiles are also invisible. There may be rooms beyond walls that are hidden and must be broken into to discover.

### The Anthurium
Three phases will occur during a round!

**Phase 1**
- The Anthurium is slow and its *Esoterica* has not had much time to flourish, so mostly **Flowering** events occur.
- The player is able to peacefully explore the starting dungeon layout and discover what creatures inhabit the map.

**Phase 2**
- The Anthurium has spread slightly and has gained some *Esoterica*.
- **Bloom** events begin to occur, changing the conditions and makeup of the game board.
- The ecosystem has matured slightly and developed; beasts have had time to reproduce.

**Phase 3**
- The Anthurium has spread significantly throughout the board and blooms are more potent.
- The Final Bloom is imminent, so the player must prepare.


The Final Bloom will occur when the Anthurium's *Esoterica* magnitude reaches over a certain threshold (50? 100? threshold increases per round completed? TBD)

Be careful! If the dungeon is damaged too much, there's a chance that there will be an **Ichor famine**. It's very hard to come back from this, and the Anthurium is likely to die, causing all the inhabitants of the dungeon to starve as a result.

##### When a round ends, 
- the Anthurium's esoterica will be reset to 0 
- the anthurium's esoterica will rise faster
- the threshold for the anthurium's final bloom will be higher, so more intense/potent blooms are more likely to happen as the run continues and the player completes rounds.
- the map will be regenerated from a different seed
- the anthurium will be placed in a random location on the map
- the anthurium's size will be reset down to its initial size
- creature spawns will be reset and randomized
- some rare creatures encountered in the last round are more likely to be encountered in following rounds

Technically, the game can go on infinitely if the player is skilled enough.




---
# Creatures
Each creature is separated into categories which describe its basic behaviors and tendencies. More primitive creatures have a drive to live, survive, and reproduce. Other creatures have other goals that they pursue.

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
Creatures will have emergent relationships with each other through their needs and behaviors (without explicitly scripted events). Creature relationships are not hardcoded, instead creatures will react to others based on their actions and intent.
Creatures can interact with, damage, heal, use abilities on, move with, and generally affect other entities, including the Anthurium.

The potential is endless for how creatures utilize their environment and what kind of behaviors they have.


### Abilities
Every creature has four **Ability Slots**. The portable form of an ability is an **Ability Shard**. Technically, every creature can discard abilities. The player can discard an ability by pausing the game and accessing a menu where they manage their abilities. Creatures can discard their abilities and drop an Ability Shard on the floor, freeing up an Ability Slot. The player is allowed to rearrange their abilities into different slots if they wish. 

Some abilities can only be used a few times before the shard is destroyed.

Some abilities have cooldowns or cast times.

Some abilities cost Ichor to cast.






---
# Anthurium
Six emotional parameters (*Esoterica*) track the Anthurium's state.
They are:
- *Felicity* (joyful contentment)
- *Furor* (divine rage)
- *Lacuna* (hollow emptiness)
- *Tremendum* (awe-inspiring power)
- *Acedia* (torpor and apathy)
- *Anamnesis* (awakening and recalling)

When it blooms, those six values form a vector that selects the nearest matching `BloomEvent` by cosine similarity. The vector's angle picks the event; its magnitude sets how intense it is.

There are two bloom tiers.
- Bloom (significant dunegon-altering event)
- Final Bloom (boss event, ends the round)

### Heartbeat
The Anthurium pulses on a semi-regular interval, sending a small amount of bloom potential through its root network. Potential flows outward and accumulates at end nodes (the outermost roots). When an end node's accumulated potential crosses a threshold, it blooms.

This means:
- a larger network = more end nodes = potential is spread thinner, blooms are slower per end node that exists! (the anthurium will need to create more hearts to beat stronger)
- a severed or small network = potential concentrates = blooms fire faster and harder
- the player can influence bloom timing by suppressing or letting the Anthurium grow
##### Flowering
The Anthurium has a small chance to do one of these things every heartbeat.

- Extends a root 2-3 tiles in a direction toward the nearest unclaimed space
- Spawns a single passive creature near a root end
- Releases an ichor mote that drifts toward the nearest hungry creature
- Reinforces a wall tile near a root (raises hardness)

### Bloom Events
Bloom events are unpredictable chaotic events that affect the dungeon in some aspect; changing the terrain, summoning entities, altering the state of the Anthurium itself, changing the rules of the game, etc. can all be Bloom Events. Here are some examples:

##### Bloom Event Examples
- the anthurium begins drawing ichor from nearby creatures
- jumpy bug swarp with mother bug appearance, kill her to stop the swarm (when mother is killed, all bugs instantly die dropping nutritious meat)
- a sinkhole opens up with a dragon worm inside
- the plant goes into overdrive, spreading and eating all matter aggressively
- interdimensional alien beings invade
- nine wizards appear and start transforming the dungeon
- the anthurium is split into multiple fragments spread out all across the board
- everything lights on fire
- everything turns into a swamp
- the undead come back to life
- the dungeon's zones are picked up and moved around
- magic, colorful, unstable living crystals grow forth from the anthurium
- summon a powerful creature


### Esoterica
The Anthurium keeps track of six parameters as it lives on in the dungeon.

| *Esoterica*                                       | Rises When...                                                                                                                                                                                                     | Falls when...                                             |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| *Felicity*<br>(Things are as they should be)      | - the Anthurium network spreads<br>- creatures are born from blooms<br>- ichor is plentiful in the dungeon                                                                                                        | - creatures are killed                                    |
| *Furor*<br>(Divine anger triggered by violation)  | - Anthurium parts are damaged or destroyed<br>- when a creature born from the Anthurium is killed<br>- terrain near the Anthurium is destroyed                                                                    | - time elapses                                            |
| *Lacuna*<br>(The ache of absence)                 | - rooms are empty of creatures<br>- the Anthurium's network has been severed or fragmented<br>- a long time has elapsed without a bloom<br>- items are used or consumed                                           | - entities are created/summoned<br>- terrain is changed   |
| *Tremendum*<br>(Awe inspired by scale and power)  | - large amounts of damage occur in a short period<br>- when a powerful creature dies<br>- when the network reaches a new size threshold                                                                           | - time elapses                                            |
| *Acedia*<br>(Hollow spiritual numbness/festering) | - the Anthurium hasn't interacted with or been interacted with a creature for some time<br>- it doesn't have enough room to grow<br>- the anthurium is starved and unable to beat its heart at full effectiveness | - the plant spreads<br>- entities interact with the plant |
| *Anamnesis*<br>(A spiritual recalling to memory)  | - time elapses<br>- the Anthurium absorbs ichor over the run                                                                                                                                                      | - the plant's parts are destroyed                         |




# Ichor
Ichor is the lifeblood of the dungeon and acts as the liquid energy that creatures use to stay alive and flourish.

The Anthurium is the dungeon's primary Ichor source. It slowly generates Ichor, which it uses to beat its heart and bloom. It produces fruit which have a high concentration of Ichor. A larger Anthurium network means more Ichor generated, therefore more Ichor will circulate into the ecosystem.

The Anthurium can also be predatory and eat creatures or terrain when it's either low on Ichor or cannot produce enough on its own.

Ichor transfer happens through
- creatures dying and dropping meat/food on the ground
- predators eating prey directly
- symbiotic creatures absorbing ichor directly from anthurium

Diminishment:
- passive time decay on every creature
- ability usage
- bloom events consuming ichor from the network to fire
- ichor lost to entropy on creature death

Multiplication:
- closed predator/prey loops
- high felicity accelerates root generation
- creature reproduction introduces new ichor containers into the ecosystem
- dense food sources act as injections




---
# Aura
Aura is a reflection of the vitality of the arena and is the score-keeping metric for runs. (kinda equivalent to arcade game's points)

Aura rises when the ecosystem is thriving (creatures/anthurium alive, ichor plentiful, terrain intact).
Aura falls when things are dying or being destroyed recklessly.
The player can drain Aura for short-term gain (kill things for special items/shards) or cultivate it for a stronger result screen score and a harder but richer Final Bloom. Aura at the moment the Final Bloom fires becomes the run's score multiplier.

Aura rises when
- Creatures are alive and active (multiplied by how many different creature species are active on the map)
- The anthurium spreads
- Terrain is intact
- Ichor is abundant

Aura falls when
- Creatures die
- The anthurium is suppressed or killed back
- Terrain is destroyed
- Ichor goes scarce



---
# Results screen
When the player dies or completes a round, a results screen will prompt the player to either quit the run or continue.

The results screen tallies up the final score and shows various metrics and data which reflect what happened and what the player did during the round.

Scoring formula for round end:
```
Final score
 =	(Distinct creature species ever active x 200)
 +	(Anamnesis at Final Bloom x 50)
 +	if the player survives: (Aura at Final Bloom x 100)
 +	else if the player dies: (Total Aura x 50)
 +	(Boss completion bonus)
 -	(Anthurium damage taken x 10)
```




# Run-to-run progression

The player unlocks more content based on
- high scores
- amount of runs played
- unique quests completed?
- achievements

Unlockables include
- Additional creature types that can appear in the dungeon
- Additional bloom events
- Additional terrain types (zones/biomes?)
- Cosmetics for pip and other creatures
- Bestiary pages
- Additional fun modes
- other things? creature creator? woagh

---

# Technical Tools, Programming Languages, and External Packages
- Godot (Engine)
- GDScript (Scripting language provided by Godot)
- C# (For more advanced and faster scripts)
- Git (Version control)
- Aseprite (Spriting, art, animation)
- BFXR (Sound effect generation library)


# Scope Definition

| Must Have                        | Completed? |
| -------------------------------- | ---------- |
| Component Class                  | yes        |
| Entity Class                     | yes        |
| Brain Class                      | yes        |
| Physics Component                | yes        |
| Tile/Cell Properties/Physics     | ongoing    |
| Main Menu                        | no         |
| Round Results Screen             | no         |
| 1 working ecosystem loop         | no         |
| Anthurium mechanics              | no         |
| 5 bloom events                   | no         |
| 2 final bloom events             | no         |
| Pause menu / hud                 | no         |
| entity tags                      | yes        |
| StateMachine/BehaviorState Class | yes        |
| Locomotion Class                 | yes        |
| Virtual Input Handler            | yes        |

| Should Have                      | Completed? |
| -------------------------------- | ---------- |
| Entity Effects (visual/auditory) | ongoing    |
| UI Effects                       | no         |
| Logo/decorative title            | no         |
| music                            | ongoing    |
| decent spritework for everything | maybe?     |

| Nice To Have                | Completed? |
| --------------------------- | ---------- |
| Dialog boxes/text animation | no         |
| crazy trippy shader effects | no         |


# Preliminary Production Timeline

Week 1 (8/24)
- [ ] ACTION needs fixed as it is bugged right now: fix the `InteractorComponent` (the part which picks the nearest entity) and make it simpler so it's less likely to have bugs.
- [ ] Design an ecosystem loop involving a producer, a couple consumers, and a wild card. These creatures' mechanisms should be related.

Week 2 (8/31)
- [ ] At least half the creatures from the designed ecosystem loop should be prototyped/close to completion. (ensure that these creatures have `EntityTag` components)
- [ ] Write the `Lobe` and `BehaviorState`s relating to hunger so that creatures have a drive to eat and stay alive.
- [ ] ichor must be fully functional AND utilized. ichor is the hunger resource and "mana", used as currency for activating some abilities.
- [ ] `Hurtbox` layers correctly interact with `Hitbox` layers!
- [ ] `Zaxis.gd`: a simulated z axis layer which allows creatures to fly or jump. produces a shadow on the ground and translates the creature's sprite based on the value of the z-axis.
- [ ] Hitbox layers correctly change based on the creature's z value, if applicable.
- [ ] FIX: only `Hurtbox` with layer `GROUND` deal damage to ground tiles.

Week 3 (9/7)
- [ ] anthurium is prototyped; esoterica functions and bloom events trigger.
- [ ] `Anthurium.gd` is a master entity which holds the `EsotericaVector` state and the cosine-similarity `BloomEvent` selection logic.
- [ ] `AnthuriumRoot.gd` is a node representing one root segment; tracks parent-root link, accumulated potential, and `is_end_node` flag.
- [ ] root extension routine: extend a root 2-3 tiles toward the nearest unclaimed space
- [ ] Ichor correctly flows from plant parts through roots into a central Anthurium ichor pool.
- [ ] implement a `BloomEvent` resource class
- [ ] `BloomEvents` have criteria to be considered "complete"
- [ ] 2 concrete `BloomEvent` resources implemented
- [ ] 1 final bloom event designed

Week 4 (9/14)
- [ ] pause screen implemented (built on `Hand`/`InteractableUI` systems).
- [ ] results screen implemented: results screen jumps on screen and ui system is activated when player dies or round is complete!
- [ ] results screen correctly tallies up points using the scoring formula (displaying all of this, animated)
- [ ] all creatures from the designed ecosystem are now implemented; all creatures interact with each other (verify not through scripted interactions, but through their behaviors).

Week 5 (9/21)
- [ ] Anthurium mechanics complete and polished.
- [ ] Heartbeat is a pulse timer on a semi-regular interval that spreads bloom potential through the bloom network (prioritizing end nodes).
- [ ] Ichor transfers from end nodes to the anthurium's core
- [ ] Flowering: weighted random roll per heartbeat for anthurium's basic "abilities"
- [ ] wire game events (creature death, plant damage, terrain destruction, room-empty checks, etc) to `EsotericaVector` deltas via signals
- [ ] `EsotericaVector` magnitude crosses a threshold, triggering the final bloom event
- [ ] Esoterica correctly changes when the Anthurium is reacting to stimuli

Week 6 (9/28)
- [ ] aura integrated and tracking complete
- [ ] aura is functional and correctly reflects the state of the game board.

Week 7 (10/5)
- [ ] Main menu implemented.
- [ ] complete the main menu: Hand class should interact well with all types of InteractableUI elements, which will power most ui elements (including the main menu).
- [ ] option PLAY should immediately launch the player into a round.
- [ ] option QUIT should exit the game.

Week 8 (10/12)
- [ ] design another ecosystem loop that overlaps the first one (ideally all creatures should have more than three overlaps in their relationships/behaviors)
- [ ] map at least 3 relationship overlaps between loop 1 and loop 2 creatures (shared prey/predator/ichor/ability interactions)

Week 9 (10/19)
- [ ] prototype loop 2 creatures (`creature6.tscn` onward) per week 8's design
- [ ] verify that overlapping relationships/behaviors produce emergent interactions with no scripted events

Week 10 (10/26)

Week 11 (11/2)

Week 12 (11/9)

Week 13 (11/16)

Week 14 (11/23)

Week 15 (11/30)

Week 16 (12/7)
- [ ] finish trailer, 
- [ ] finish reflection paper, 
- [ ] finish portfolio 

`EntityTag`: defines a group that this entity belongs to. Absolutely necessary for other entities' relationships. For example, a `mouse` may not like an `explosive` entity and choose to run away from it.
# Milestone Schedule
| Week            | Tasks/Milestones                                                                                                 |
| --------------- | ---------------------------------------------------------------------------------------------------------------- |
| Week 1 (8/24)   | <br>InteractorComponent.gd<br>ecoloop_1.example                                                                  |
| Week 2 (8/31)   | <br>creature1.tscn<br>creature2.tscn<br>creature3.tscn<br>HungryLobe.gd<br>SeekFoodState.gd<br>ChasePreyState.gd |
| Week 3 (9/7)    |                                                                                                                  |
| Week 4 (9/14)   |                                                                                                                  |
| Week 5 (9/21)   | <br>Aura.gd                                                                                                      |
| Week 6 (9/28)   |                                                                                                                  |
| Week 7 (10/5)   |                                                                                                                  |
| Week 8 (10/12)  |                                                                                                                  |
| Week 9 (10/19)  |                                                                                                                  |
| Week 10 (10/26) |                                                                                                                  |
| Week 11 (11/2)  |                                                                                                                  |
| Week 12 (11/9)  |                                                                                                                  |
| Week 13 (11/16) |                                                                                                                  |
| Week 14 (11/23) |                                                                                                                  |
| Week 15 (11/30) |                                                                                                                  |
| Week 16 (12/7)  |                                                                                                                  |