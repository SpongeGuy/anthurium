extends Component
class_name WorldInterface


# -----------------------------------------
# helper component to sample a cell's properties to control various behaviors
# samples the cell the entity is curerntly stood on
# -----------------------------------------


func sample_cell(body: CharacterBody2D) -> CellData:
	if not WorldGrid._grid:
		return null
		
	var coords = WorldGrid.world_to_tile(body.global_position)
	return WorldGrid.get_cell(coords)


func cell_movement_modifier() -> float:
	var current_cell: CellData = sample_cell(entity)
	if current_cell == null or current_cell.terrain != CellData.TerrainType.GROUND:
		return 1.0
	return current_cell.movement_multiplier
	
func cell_friction_multiplier() -> float:
	var current_cell: CellData = sample_cell(entity)
	if current_cell == null or current_cell.terrain != CellData.TerrainType.GROUND:
		return 1.0
	return current_cell.friction
	

