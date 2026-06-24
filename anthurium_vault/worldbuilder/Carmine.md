A winged organic stone being who lives on the spires of the [[Spire Sea]], south of [[Emer]]. Winged stones like Carmine create clones of themselves by embedding their bodies into rock faces. This process takes over a decade as the stone has to leave every so often to consume things for energy; this process is very energy intensive! However, in optimal conditions, the process will produce hundreds of winged pebbles which will grow larger and mature over a hundred years.

Winged stone younglings (pebbles) are ravenous and eat whatever they can until they are satiated.

#### For JOURNEY THROUGH MEATSPACE:
```
items will be defined in json format to ensure the most moddability possible

structure
{
	"items": [
		{
			"id"
			"name"
			"description"
			"type"				
			"rarity"
			"unique"
			"spawn_weight"

			"socket"
			"slot"
			"bag"
			"default"

			"metadata"
		},
		{
			...
		},
		{
			...
		}
	]
}

# GUIDE
"id" <string>
	Item ID. Always the item name but no caps and underscores for spaces.
"name" <string>
	Item cosmetic name. Will be displayed to the user.
"description" <string>
	Item description. Always shown below item name. Can be blank.
"type" <string>
	Can be "collectable"
		- item when collected will disappear, giving the collector the item's default stats.
		- all stats gained by the item are temporary for the stage.
		- the collector will also gain item passive and active abilities temporarily per the stage.
	or "equipment".
		- item when collected will be transferred into the collector's inventory ("bag" by default)
		- item persists in collector's inventory between stages.
"rarity" <int>
	A numeral which determines the 'rarity' or 'importance' of an item. This statistic is for clarity in item ability and stat organization (and gamerule changing fun stuff).
	0: Junk
		items which are usually collectable, like simple health refills or bonus points or coins, etc.
	1: Common
		items which are meant to appear often in a run. these items have simple statistics and not much special going on. usually stat-stick items.
	2: Unusual
		items which might not have not many stats on them but have a cool passive ability. active abilities can be on unusual items but it should not be commonplace.
	3: Rare
		items with decent stats and usually an ability on them. abilities will only show up in socket or slot equip modes. abilities should introduce game mechanics which can be built upon using unusual and common items.
	4: Legendary
		items with great stats and always an ability on them. abilities can show up on every equip mode. abilities can either be wildly unique or can support a game mechanic from other items' abiltiies.
	5: Exotic
		items which have abilities which are game-changing or have the potential to alter the circumstances of the entire run. these items can and should break the ordinary game rules.
"unique" <boolean>
	If true, only one of these items is allowed in the collector's inventory.
"spawn_weight" <float> (between 0 and 1)
	Given a spawn event (and probably item pool), this is the proportion that this item will be picked out of a pool of other items.
"socket", "slot", "bag", "default" <object>
	An object which describes what happens when the item is placed in the collector's equipment Socket, Slot, or Bag, designated as 'equipment modes'.
	"default" is only used when the item is not using an equipment mode.
	A template EQUIPMENT MODE OBJECT TEMPLATE is below.
"metadata" <object>
	Information which will not be directly used or read during gameplay.


equipment mode structure

{
	"icon_path"
	"icon_shader"
	"name_shader"
	"description"
	"description_shader"

	"stats_modifiers"
	"abilities"
}


"icon_path" <string>
	Relative filepath to item icon png.
"icon_shader" <string>
	GLSL shader which is applied to the item icon
"name_shader" <string>
	GLSL shader which is applied to the item name
"description" <string>
	Text displayed above item stats and abilities.
"description_shader" <string>
	GLSL shader applied to the item description.
"stats_modifiers" <object>
	An object representing all changes to character statistics.
"abilities" <list>
	A list of abilities the item possesses.


`stats_modifiers` example
{
	"attack_damage": {
		"base": 10,
		"multiplier", 1.0
	},
	"attack_speed": {
		"base": 0,
		"multiplier": 1.1
	}
}

`abilities` example

[
	"passive_crystal_shield",
	"passive_aetherburn",
	"active_giga_laser",
]



```