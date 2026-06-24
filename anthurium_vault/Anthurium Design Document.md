Anthurium Design Document
========================
17 Monday, November 2025 12:17:05 am

# Setting & Structure
**Anthurium** is a real-time top-down arcade roguelike set in a bizarre dream dungeon. The dungeon is split into a 5x5 grid of persistent regions called **Fragments**. While the specific terrain within each Fragment is procedurally generated on every run, the Fragment's overall properties, rules, and creatures remain fairly constant.

Each Fragment contains a central landmark called a **Focus**. This structure acts as a navigational anchor and is often the dictator of the Fragment's local rule. The Focus is also central to progressing through the dungeon through quests.

The player can strategically choose which of the 25 Fragments to begin each run in, allowing for targeted farming of specific creatures/shards or pursuit of meta-quests. Each Fragment is bordered by indestructible walls, so creatures must find gateways to pass to other Fragments.

### Pitch
```
A mysterious realm. A cosmic hypersomniac. An indestructible threat. Lots and lots and lots of creatures.  All and more can be found in the DREAM DUNGEON. 

Absorb powers from creatures you meet in the DREAM DUNGEON to battle, explore, and solve mysteries.
```


## Lore

 > *Meatspace has many pleasures yet many mysteries and horrors. One of which is the **Anthurium**; a vast and ever-growing mass of sentient plantlike ooze. Whatever the Anthurium sets its roots in is converted into more of itself, purifying everything it comes into contact with. Substances and creatures alike lose their physical structure and identity to become more of the Anthurium mass. It is debated on whether or not the creep is aware of itself or even has motive, but it grows nonetheless, acting as a purest state of matter; almost like the molecules of its victims are convinced to transform into that of the Anthurium.*

> ***Xelloks, the Chaos God** is an ancient cosmic entity who has been present since before the creation of Meatspace. Its motives remain unknown to the inhabitants of Meatspace. It is one of the only powerful cosmic creatures to have slipped past the veil which surrounds and protects Meatspace.*

> *Before Xelloks arrived in Meatspace, the Anthurium had managed to consume an entire planet. The planet (now known as Kazda or Khaz'dakka) orbited a large chaotic star which often ejected large amounts of material into space. It is possible that the star has ejected material and launched it directly towards Kazda, perhaps spraying Anthurium mass into space as well.*

> *Now the Chaos God has transformed into **The Dreamer**, an entity in constant stasis. It has consumed Kazda and has merged with the star of the system in an attempt to gather enough power to destroy it. Xelloks failed at instantly destroying the Anthurium. The energy Xelloks used against the Anthurium was converted into ordered energy and was absorbed by the indestructible mass. Xelloks now resides at the center of the system, its body embedded in the star as The Dreamer, forever running internal simulations to figure out how to annihilate the Anthurium. The Anthurium now is living restlessly inside The Dreamer's cosmic dream dungeon in a permanent stalemate.*

> *The player is not a natural inhabitant of Xelloks' dream; they are a sentient, self-replicating logic spark projected by Xelloks' mind to execute the final perfect sequence. The player is a soul which must choose order or chaos.*

> *Option A (Extermination / Chaos): The player succeeds Xelloks' plan by delivering the perfect sequence, breaking the stasis. The Dreamer awakens more powerful than before and the resulting chaos tears the veil protecting Meatspace apart, collapsing outer space upon it and releasing the unbound power of the Chaos God unto reality.*

> *Option B (Submission / Stability): The player stabilizes the Stellar Nexus. The Core is locked, the energy flow stops, and The Dreamer is doomed and will never awaken again as Xelloks. The Anthurium, now with full control over the energy source and its environment (Xelloks' Subspace), converts the dream into a perfect template of order, which is then projected onto all of Meatspace using Xelloks' power.*

### Chaos
In the context of Anthurium, Chaos is not simply random destruction; it is a physical manifestation of infinite and unlimited creation, energy, and change. It is the state of Xelloks' true self and the fuel of the universe, but if unbound, it tears reality apart.

In-game, the score assigned to Fragments reflects the danger and instability of that region (essentially, difficulty). A Fragment rated (5) has rules that encourage rapid, high-energy interactions and spawns. Certain effects may be amplified or strengthened.

### Stellar Energy
This energy is what powered Xelloks' failed attempt to destroy the Anthurium. It's now the primary energy source that Xelloks uses to keep the Anthurium within his Dream, but it is also the source of energy that the Anthurium needs to take over Xelloks' body and spread itself throughout the entirety of Meatspace.

The Anthurium speeds up its spread when near plasma and tries to creep towards the source. When it consumes plasma, it explodes violently, spreading more creep.

### Aether
Aether is a primordial substance; the blood of gods. It is innately magical, and those who possess it have immense reality-bending power. Aether flows through Xelloks' veins and it is what allows him to embed himself in the star and contain the Anthurium. Over the course of the game, the Anthurium could be able to make Xelloks draw blood from within his Dream.

Aether is an unfathomable substance and is an unknown state of matter. There exist beings which are made entirely of aether who surround entire planets to enable the denizens to use magic.

## Game Map
Locations are ranked by their amount of chaos from 1-5 with 1 being the most calm and 5 being the most chaotic.

| Legend            |
| ----------------- |
| (#) = chaos level |
| Ψ = dungeon exits |

|                    |                       | Map               |                  |                |
| ------------------ | --------------------- | ----------------- | ---------------- | -------------- |
| (1) Farm           | (2) Rust              | (3) Atrium Ψ      | (4) Temple       | (1) Veil       |
| (1) Hill           | (3) The Stomach       | (3) Toxic Poison  | (3) The Nerve    | (2) Mechanisms |
| (3) Axis Ψ         | (2) Singularity Vault | (5) Stellar Nexus | (4) Broken Light | (4) Crucible Ψ |
| (2) Silent Archive | (3) The Conduit       | (2) Rain Basin    | (2) The Crack    | (3) Foundry    |
| (1) Breeze         | (3) Deep Freeze       | (5) Reach Ψ       | (1) Onyx Cliffs  | (2) Loch       |



## The Anthurium
The Anthurium is an ancient plantlike entity which acts as the game's dynamic, spatial 'timer', encouraging the player to move with haste throughout the dream dungeon. It spreads consistently yet slowly over time, corrupting terrain and converting creatures into plant matter.

The Anthurium will spit pellets and create aggressive plant monsters (turrets, walkers) in certain conditions. Additionally, the Anthurium can speed up its growth in a local area in a "burst phase" if there is too much activity nearby. 

# Gameplay
If the player has not completed the "Escape the Dream Dungeon!" Meta-Quest (new player):
1. Select play [camera zooms into starfield and eventually into trippy visual haze]
2. [fade to black, loading screen, fade into gameplay] The player finds themselves in a grassy Hill (Fragment).

If the player has completed the "Escape the Dream Dungeon!" Meta-Quest:
1. Select play [an animation plays which zooms into another menu]
2. [A map comes into view] The player can choose which Fragment to start their run in. The player can only choose Fragments that they have visited, that are on the edge of the grid, and are also not dungeon exits. The names and descriptions of these Fragments must be unlocked through exploration. The player selects a Fragment.
3. [If the player has unlocked Anthurium Control] The player can choose the Fragment the Anthurium starts in. Similar conditions apply with the player's starting Fragment.
3. [If the player has unlocked playable creatures] The player can choose which creature to start their run as.
4. Review Meta-Quests menu and confirm choices view. The player can select go back or confirm.

The player chooses one of the Fragments to start in (the player will base this decision on their favorite environment and meta-quests). The player also chooses which Fragment the Anthurium will start in. 

The player navigates the procedural terrain while constantly avoiding the Anthurium. The player will use their innate ability to pick up, drop, and throw items to solve local problems. The player is harmless except that they can throw objects at creatures to damage them.

The player defeats creatures to acquire Aspect Shards. This is the key to progression; by consuming a shard, the player gains a new, powerful modular ability. The player can then use their acquired shards to manipulate the highly reactive creature ecosystem to complete Quests. Quests are given at the Focus (the structure at the center) of each Fragment. Quests must be completed to pass the gate on the edge of a Fragment.

## Creatures
All creatures operate on a behavior tree and their actions are modular. This allows for unique and unpredictable interactions with each other and the environment. The player is considered a creature. Every creature possesses the baseline abilities to pick up, drop, throw, and consume items.

When a creature is defeated, it may drop an **Aspect Shard**. Consuming this shard grants the affected creature a behavior or ability of the creature it came from.

| Creature Name | Behaviors | Aspect Shard | Possible Emergence | Appearance | Common in |
|---|---|---|---|---|---|
|Swarm Flea  |Fleas are attracted to each other and want to be in and around inside corners or long walls. Fleas have flock style movement and create swarm mist when startled or moving quickly. Fleas are attracted to Kori nests and will eat and scatter fruit from the nests.    | Deploy swarm mist when startled or moving quickly. | Swarm mist reacts explosively with the Drill Bore's gold but makes it even more valuable in the explosion. If the mist catches on fire (like from the Pyre), it expands rapidly in a shockwave, causing damage to everything. | A tiny gross fly bug |
| Jumpy Bug | Jumpy Bugs jump long distances and can jump on top of walls, even impassable ones. When Jumpy Bugs land, they stomp entities.  | Movement is converted to that of a Jumpy Bug. | Jumpy Bugs can stomp on the Gnome Statue to slam it into walls or creatures at high speed. | A water skipper / tectite zelda |
| Gnome Statue | Does nothing except get pushed around and knocks into things. It shatters if it crashes into anything at high velocity. It can make itself immovable and indestructible for a period of time. There's a magical variety of the Gnome Statue that can hop around. | Activate to make yourself immovable and indestructible for a period of time. |  | Garden gnome|
| Grunt | Simply wanders around randomly but continuously. It attacks if any creature grows too near, but it won't pursue aggressively. |  |  | A wide bodied hobgoblin type creature, polka dot patterns on his back |
| Growl | like the grunt but actively searches for a fight |  |  |
| Beetoo | Lays bombs as eggs. The eggs will detonate instantly upon contact with a damaging source. |  | The eggs can be picked up by the Magnet Mite or Bounce Blob |
| Drill Bore | Drills through walls. Leaves behind valuable gold which attracts greedy creatures. |  | The Drill Bore can be ambushed by the Wall Master very easily. The Kori can mistake gold for fruit and bring it to its nest. | Mole man holding a drill |
| Kori | Builds a nest and grows hatchlings. Runs around grabbing fruit and delivering it to its nest. The nest can be destroyed and then the hatchlings will wander. If the hatchlings get enough food they will transform into Rage Beasts. |  | Sometimes grabs other things besides fruit. | Stilt bird |
| Hoary | Cranky old man. Sneezes. Builds a solid rocking chair. If knocked away, he will always try to return to his rocking chair. |  |  | Old man wearing a flannel and jorts |
|Worm  | Multiple body segments. Can only bite you from its head. Can only move in cardinal directions. Severing the worm in half creates two unique worm creatures. Worm gets longs if it eats fruit. |  | Explosions can cause the worm to split into many worm heads. |
|Cultist  | Summons fireballs to throw at you. Moves around by teleporting. |  |  Fireballs can ignite swarm mist. Fireballs can be absorbed by Bounce Blob but cause it to overheat and split. |
|Glub Gob  | Eats as much stuff as possible. |  | If it finds a Kori nest it will eat the whole thing. |
| Beholder |Shoots a continuous laser beam and floats around aimlessly.  |  |  |
| Dungeon Cube |Quickly launches itself in one of four directions and stops if it hits a wall. And anything in its path takes huge damage and is knocked back.  |  |  |
|  Patte|  |  |  |
| Pyre |  |  |  |
| Poltergeist |  |  |  |
| Rage Beast |  |  |  |
|  Transmog|  |  |  |
| Song Moth |  |  |  |
| Waddler |  |  |  |
|Anhurgir  |  |  |  |
| Cat |  |  |  |
| Bubble Blower |  |  |  |
| Echo Bat |  |  |  |
|  Spin Wheel |    |    |    |
|  Puzzle |    |    |    |
| Clockwork Mouse  |    |    |    |
|  False Item |    |    |    |
| Ink Blot  |    |    |    |
| Wall Master  |    |    |    |
| Flame Wheel  |    |    |    |
| Kernel  |    |    |    |
| Warden  |    |    |    |
| Doormaster  |    |    |    |
| Magnet Mite  |    |    |    |
| Spike Ball  |    |    |    |
| Slug  |    |    |    |
| Imp  |    |    |    | red or purple demon |
|  Bounce Blob |    |    |    | variable color living slime ball, it has a slimy membrane surrounding a more solid center |
| Whistler  |    |    |    | colorful butterfly |
| Aureate Crawler  | Grows crystals on its body. These crystals, when fully grown, reflect lasers and bullets. Crystals react chaotically to any form of contact damage crystals can cause explosions, teleportation, summoning). After a Crawler has had a fully grown crystal for enough time, the crystal will break off and embed into the ground where it will behave the same. |    |    | Scuttle bug with variable color crystal on its back|
| Slushy  |    |    |    | ice tornado vortex |
| Boblin  | Wanders around and bobs his head   |    |    | yellow goblin |
| Alien  |    |    |    | grey alien |
| UFO  |    |    |    | classic alien ufo spaceship |
| Moo  |    |    |    | horned cow |
| Moon Lich  |    |    |    |
| Gnarp  |    |    |    |

This table of creatures is not final and can be added on to.

## Items
Items can be found all around the map and can also be created by or dropped from creatures.

There is at least one source of fruit per Fragment. This way, passive creatures can gain points reliably and sustainably for more chaotic potential. Lots of creature mechanics rely on their internal point value.

| Item Type | Role | Examples |
|---|---|---|
|Type 1: Interactive (Hold/Throw/Consume)  | Strategic Manipulation. Interactive items give the player the option to commit to a resource's usage. Throwing an item to another creature can become a tactical decision. | Fruit, Aspect Shard, Rocking Chair, Stone, Spear|
| Type 2: Immediate (On Contact) | Passive Gain/Score Tracking. Immediate items reduces interface clutter and is ideal for instant benefits or score feedback.  | Flowers, Potions, Hearts |


## Quests
Quests are the narrative drivers of the game. They are categorized into **Run Quests** (immediate objectives for local progression and challenge) and **Meta Quests** (cross-run objectives tied to the overall plot of the game). Quests are given at the Focus of each Fragment and must be completed to unlock the gate to an adjacent Fragment.



| Quest Type | Goal |Design Implementation Detail  |
|---|---|---|
| Run Quests | Run Quests are designed to be mostly short and fun sequences which test the player on the usage of their abilities and their environment. However, Run Quests can be highly varied in their content and should be designed around the pillars (exploration, experimentation, combat, strategy, chaos). Run quests are local to one Fragment and are called upon from the Focus of that Fragment. Completion of a quest is required to unlock the gate to adjacent Fragments. |  |
| Meta Quests | Meta Quests are objectives which span runs and Fragments. They reward the player with permanent upgrades, permanent game world changes, new playable creatures, new items, and knowledge to eventually guide the player to the final choice. |  |


## Progression
There are several different overarching objectives the player can complete throughout the game. The first and most basic objective the player is given is to escape the Dream Dungeon. There are four exits on the map located at the northern, eastern, western, and southern cardinal points of the map.

At first, the player only has access to four fragments:

|                    |                       | Map                |                  |                |
| ------------------ | --------------------- | ------------------ | ---------------- | -------------- |
| ***(1) Farm***     | ***(2) Rust***        | ***(3) Atrium*** Ψ | (4) Temple       | (1) Veil       |
| ***(1) Hill***     | (3) The Stomach       | (3) Toxic Poison   | (3) The Nerve    | (2) Mechanisms |
| (3) Axis Ψ         | (2) Singularity Vault | (5) Stellar Nexus  | (4) Broken Light | (4) Crucible Ψ |
| (2) Silent Archive | (3) The Conduit       | (2) Rain Basin     | (2) The Crack    | (3) Foundry    |
| (1) Breeze         | (3) Deep Freeze       | (5) Reach Ψ | (1) Onyx Cliffs  | (2) Loch       |

The player can only start at **Hill** and will travel to **Farm**, then **Rust**, then **Atrium** and escape the dungeon from there. The Anthurium will start in **The Stomach**. All other Fragments are inaccessible; quests which would normally give access to other Fragments will be unavailable.


### Meta Quests
Meta Quests are important, persistent objectives which can span multiple runs and/or multiple Fragments. Their completion is necessary for overall game progression. Their activity may influence the dream dungeon's properties or general rules and structure. A large portion of Meta Quests are optional and are not required to complete to beat the game.

#### Early Game
| Name | Objective | How to Complete | Unlocks |
|---|---|---|---|
| Escape The Dream Dungeon! | Progress through the dream dungeon and escape through the Atrium. | Play the game in a linear fashion through the 4 available Fragments and successfully complete the final quest in the Atrium and escape. | The player can now choose any visited edge Fragment to start the run. |
| Find The Master...  | Locate the source of the mysterious guiding voice. |  | Player is suggested the idea that they are in an unconventional reality. |
| Mysterious Cultists? | The Watcher mentioned cultists in the Temple. Investigate them and find out what they are worshiping. |  | Player gains more knowledge about the Dream. |

#### Mid Game
| Name | Objective | How to Complete | Unlocks |
|---|---|---|---|
| Herbicidal | Kill 100 Anthurium-related creatures. | | |
| | Throw a piece of rust into the Foundry. | | |
| Apprentice Angler | Find a fishing rod and go fishing. | | |
|Stellar Cartographer | Chart the flow of plasmic energy throughout the dream dungeon. | Visit The Crack, The Stomach, The Conduit, and The Nerve. | |
| | | | Unlock the Subpocket, an item which allows storage of 5 items which persist between runs. |
| You Are Chosen. | Find the Cat King and bribe him to enter his domain.| Deliver a caught fish to Riaow. | Unlock the Cat creature as a playable character. |
| Probed! | Be abducted by aliens. | | |
| Volatile Reactivity | Cause a violent explosion using Onyx crystals.| | |
| Sailor In Training | Learn how to sail across water. | | Enables the player to navigate water-based Fragments more reliably (if they do not have a good shard for movement). |
| | |  | The Watcher's location is pinpointed during Fragment select.|
| | Gain access to the deepest, most secure part of the Silent Archive. | |
|Meet the Dream Pilgrims | Locate the peaceful pilgrims led by Nazara and understand their purpose. | |
| | Meet with Konigen and have him accompany you while searching for his lost grappling hook. |  |
| Figment | Awaken the Revenant. | |
| Watchful Eyes | Awaken the Owl. | |
| | Impress Hazim with your knowledge of the Dream. | ||
| | | | |
| | | | |

#### End Game
| Name | Objective | How to Complete | Unlocks |
|---|---|---|---|
| The Aether Tap | Figure out how to reliably gain advantage in high-chaos regions. | Find a rare Aether Pool in a high-chaos Fragment. Detonate an explosive in the pool, creating an Aether Chip. Survive the chaotic effects of the agitated Aether pool. | Gain knowledge on how to create an Aether Chip, an item which allows the player to manifest any item (which is known to the player), consuming the chip. |
| Crashing The Party |Figure out how to break through the walls surrounding the Stellar Nexus. | | The player now knows how to enter the Stellar Nexus. |
| | Discover a way to gain immunity to the Anthurium. | |
| | Follow Nazara into the creep. | | |

### Characters
| Name          | Description                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------ |
| The Master   | Seems to have been in the dream for awhile and knows their way around. A helpful mentor to the player. Wanders around and sets camp in random Fragments. |
| Hazim, Kazda Cult Leader | Leads a cult following who worships The Dreamer. Lives in the Temple. |
| Riaow, Cat King | Lives in The Stomach.  |
| Ron | Froggy fisherman. Will exchange items for fishing equipment. Lives in the Loch. |
| Konigen | Rabbit master of sailing and boatcraft. Lives in the Onyx Cliffs. |
| Nazara, Bodhisattva | Leads a group of peaceful pilgrims who travel the inner circle. They search the circle for enlightenment and to study the Anthurium. Found traveling within one of the inner Fragments. |
