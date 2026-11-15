extends TileMapLayer

@export var player: Node2D

const WORLD_HEIGH: int = 20
const PLATFORM_SIZE: int = 3
const RAM_SCENE = preload("res://Scenes/ram.tscn")

# Seed and noise declaration
var world_seed: int = randi()
var noise := FastNoiseLite.new()

# Blocks declaration
const DIRT: Vector2i = Vector2i(0, 0)

var spawned_ram: Dictionary = {}

func get_height(x: int) -> int:
	var n = noise.get_noise_1d(x)
	var n2 = n * (WORLD_HEIGH / 2.0)
	return int(n2)
	
func world_generation() -> void:
	if not player or not is_instance_valid(player):
		return
	var player_position: Vector2i = local_to_map(to_local(player.global_position))

	for i in range(0, player.render_distance + 1):
		var right_x = player_position.x + i
		var right_y = get_height(right_x / PLATFORM_SIZE)
		set_cell(Vector2i(right_x, right_y), 0, DIRT)
		_try_spawn_ram(right_x, right_y)

		var left_x = player_position.x - i
		var left_y = get_height(left_x / PLATFORM_SIZE)
		set_cell(Vector2i(left_x, left_y), 0, DIRT)

func _try_spawn_ram(tile_x: int, tile_y: int) -> void:
	# Spawn RAM modulu každých 8 dlaždic, aby bylo na trase dostatek RAMek k nasbírání 30 kusů
	if tile_x > 4 and tile_x % 8 == 0 and not spawned_ram.has(tile_x):
		spawned_ram[tile_x] = true
		var ram = RAM_SCENE.instantiate()
		ram.global_position = to_global(map_to_local(Vector2i(tile_x, tile_y - 2)))
		get_parent().add_child(ram)

func _ready() -> void:
	noise.seed = world_seed
	noise.frequency = 0.3
	print("Seed: ", world_seed)

func set_world_seed(new_seed: int) -> void:
	world_seed = new_seed
	noise.seed = world_seed
	spawned_ram.clear()
	clear()
	world_generation()

func erase_far_cells() -> void:
	if not player or not is_instance_valid(player):
		return
	var player_position: Vector2i = local_to_map(to_local(player.global_position))
	var cells = get_used_cells()

	for cell in cells:
		if abs(cell.x - player_position.x) > player.render_distance or abs(cell.y - player_position.y) > player.render_distance:
			erase_cell(cell)

func _process(_delta: float) -> void:
	world_generation()
	erase_far_cells()
