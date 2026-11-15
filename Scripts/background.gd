extends TileMapLayer

@export var player: Node2D

# Blocks declaration
const BACKGROUND: Vector2i = Vector2i(0, 0)

func background_generation():
	var player_position: Vector2i = local_to_map(to_local(player.global_position))

	for x in range(0, player.render_distance + 1):
		for y in range(0, player.render_distance + 1):
			set_cell(Vector2i(player_position.x + x, player_position.y + y), 0, BACKGROUND)
			set_cell(Vector2i(player_position.x - x, player_position.y - y), 0, BACKGROUND)
			set_cell(Vector2i(player_position.x + x, player_position.y - y), 0, BACKGROUND)
			set_cell(Vector2i(player_position.x - x, player_position.y + y), 0, BACKGROUND)

func erase_far_cells():
	var player_position: Vector2i = local_to_map(to_local(player.global_position))
	var cells = get_used_cells()

	for cell in cells:
		if abs(cell.x - player_position.x) > player.render_distance or abs(cell.y - player_position.y) > player.render_distance:
			erase_cell(cell)

func reload_background() -> void:
	clear()
	background_generation()

func _process(delta: float) -> void:
	background_generation()

	erase_far_cells()
