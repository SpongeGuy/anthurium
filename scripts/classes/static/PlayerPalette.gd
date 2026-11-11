class_name PlayerPalette

static var colors: Array[Color] = [
	Color("23ff29"), # P1 green
	Color("fffe27"), # P2 yellow
	Color("1380ff"), # P3 blue
	Color("ff6219"), # P4 orange
]
 
static func color_for(slot: int) -> Color:
	return colors[posmod(slot, colors.size())]
 
