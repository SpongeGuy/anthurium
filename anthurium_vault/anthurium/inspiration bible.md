---
kanban_order: W1Z
---
# one line pitch
An action arcade game where you survive in a chaotic, ever-changing world.

*Anthurium* is a modern top-down survival and exploration arcade game with low fidelity graphics and a bizarre, familiar yet otherworldly aesthetic. *Anthurium* leans into emergent gameplay elements, where simple elements come together to make an experience much much greater than the sum of its parts. A significant portion of the game is a sandbox involving a variety of creatures, all of which have their own unique needs, abilities, and behaviors.

# target audience, platform
Players who love classic arcade games like Robotron, classic Zeldas like Link's Awakening, roguelikes, and adventure games like Rain World will probably enjoy playing *Anthurium*.

People will be able to play *Anthurium* on PC and console using a controller (or keyboard, for accessibility).

# reference set
FORGET-ME-NOT has these creatures that look incredibly colorful and unique on the dark background of the game. Some of the creatures have bizarre mechanics that you wouldn't expect, like the worm or the guy who clones himself. I wanna take that experience and make it crazier and more varied while still keeping it cohesive and straightforward-feeling.
FORGET-ME-NOT makes use of a sound synthesis engine called sfxr, which I will adapt into my game; creatures will have specific and characteristic voices which can be generated and played during runtime, making the game feel more interactive and dynamic.

Link's Awakening is an older game on an older system and the developers needed to use very precise methods to get Link to move the way he did. I would like to implement that sharp-feeling and satisfying movement to *Anthurium* while improving upon some mechanics.

Mina the Hollower is a very new game that is clearly inspired by Link's Awakening but features more polish and oomph to its design. I want to borrow its implementation of a pseudo z-level to the game (which also existed in Link's Awakening) to make the game feel more exciting with some creature interactions and puzzles.

Super Mario RPG is an old game with a fun menu system. I don't necessarily need to implement the menu system of mario rpg but it would be fun to do so, and I could adapt it to new systems that involve moving through UI.

Deltarune is a modern RPG that holds many secrets, some of which aren't very obvious while playing the game blind. Deltarune's mariana-level depth of story, continuity, and mystery is something that I would strive for if I wrote a story for *Anthurium*.

There are some PICO-8 games and classic arcade games that I draw inspiration from like TAD or ROBOTRON: 2084. I am going to borrow some style from these games (the more popular PICO-8 games are dripping with style). I think it is a good idea for me to implement an arcade-style start/select screen in lieu of a proper main menu because it's more stylish and captures attention better (especially for a "demo mode" for a showcase or convention).

# mood board / style board
![john](https://www.lexaloffle.com/media/75969/tad_noo_noo.gif)
![tad2](https://www.lexaloffle.com/media/75969/tad17_not%20like%20this.gif)
![aquarium](https://www.lexaloffle.com/media/30300/fishing_2.gif)
![forgetmenot](https://youtu.be/Weak4zFU3jU?si=pU6ewG1NpfH1LwMd)
![link2](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmedia1.tenor.com%2Fm%2FDKjQeFsAqykAAAAd%2Flinks-awakening-dx-links-awakening.gif&f=1&nofb=1&ipt=3fb22a16b472c0a38cd19625fcdee51af7f19d54ad1bc6c0dafa66127574ddf4)
![https://www.lexaloffle.com/media/75969/tad_noo_noo.gif](the)
![link1](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmedia1.tenor.com%2Fm%2FNP4rkQ_KwmAAAAAd%2Flinks-awakening-dx-game-boy-color.gif&f=1&nofb=1&ipt=851ab65187d08b03b3a0769c386e7ef36dc9dd3d8eb62ed1707c3064851a9825)
![link3](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fmedia1.tenor.com%2Fm%2FZ09OrWcpR0UAAAAd%2Flinks-awakening-dx-game-boy-color.gif&f=1&nofb=1&ipt=cc28d7f305035c5d8f30dc51ab1e6aa707f7ee431e450b6effee9e5a5f186aa4)
![mina](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fsm.ign.com%2Fign_za%2Fphoto%2Fdefault%2Fgif-bonebirdgameplay-1643782697447_swa4.gif&f=1&nofb=1&ipt=7e9f200bed3c495fca276defff2db5d21f055f0e67a13f35fb4d913b51fa51df)
![mina2](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fsm.ign.com%2Ft%2Fign_es%2Fphoto%2Fdefault%2Fgif-bossstinky-1643782697452_mcu8.1080.gif&f=1&nofb=1&ipt=3bf38405faeedd0a5f4805eb14e742fc86d8fb0e2925cb631c2ebc1d5cf044f6)
![mina3](https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fsm.ign.com%2Fign_za%2Fphoto%2Fdefault%2Fgif-bosscrypt-1643782697448_m7fu.gif&f=1&nofb=1&ipt=98842a24ce18f216c2e662dd0ec192f9c05b2459a99693d4691bf382b9f90e66)

# core gameplay loop
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

# feature list: must / should / could

# player experience snapshots