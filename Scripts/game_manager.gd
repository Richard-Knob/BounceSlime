extends Node

## GameManager Autoload
## Řídí cíl hry: 1 000 metrů + 30 RAM modulů k vítězství

signal ram_changed(count: int, target: int)
signal distance_changed(current: float, target: float)
signal overclock_state_changed(active: bool)
signal game_won_signal()

const TARGET_DISTANCE_M: float = 1000.0
const TARGET_RAM_COUNT: int = 30
const PIXELS_PER_METER: float = 10.0 # 10 000 px = 1000 m

var ram_count: int = 0
var enemies_killed: int = 0
var game_time: float = 0.0
var game_won: bool = false

var shields: int = 2 # Ochranné štíty pro hráče
var is_overclocked: bool = false
var overclock_time_left: float = 0.0

var distance_m: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not get_tree().paused and not game_won:
		game_time += delta
		
		# Aktualizace Overclocku
		if is_overclocked:
			overclock_time_left -= delta
			if overclock_time_left <= 0:
				is_overclocked = false
				overclock_state_changed.emit(false)

func reset_state() -> void:
	ram_count = 0
	enemies_killed = 0
	game_time = 0.0
	game_won = false
	shields = 2
	is_overclocked = false
	overclock_time_left = 0.0
	distance_m = 0.0
	ram_changed.emit(ram_count, TARGET_RAM_COUNT)
	overclock_state_changed.emit(false)

func add_ram(amount: int = 1) -> void:
	ram_count += amount
	AudioManager.play_sound("ram", 0.1, 2.0)
	ram_changed.emit(ram_count, TARGET_RAM_COUNT)
	
	# Každých 5 sebraných RAM modulů spustí turbo Overclock!
	if ram_count % 5 == 0:
		activate_overclock(5.0)
	
	check_victory()

func activate_overclock(duration: float = 5.0) -> void:
	is_overclocked = true
	overclock_time_left = duration
	AudioManager.play_sound("ram", 0.3, 4.0)
	overclock_state_changed.emit(true)

func add_kill() -> void:
	enemies_killed += 1
	AudioManager.play_sound("explode", 0.2)

func absorb_hit_with_ram() -> bool:
	# Ochranný štít absorbuje zásah
	if shields > 0:
		shields -= 1
		AudioManager.play_sound("hurt", 0.1, 2.0)
		return true
	return false

func update_player_distance(player_x: float) -> void:
	distance_m = max(distance_m, player_x / PIXELS_PER_METER)
	distance_changed.emit(distance_m, TARGET_DISTANCE_M)
	check_victory()

func check_victory() -> void:
	if game_won:
		return
	# Podmínka vítězství: 1 000 metrů A ZÁROVEŇ 30 RAM modulů!
	if distance_m >= TARGET_DISTANCE_M and ram_count >= TARGET_RAM_COUNT:
		trigger_victory()

func trigger_victory() -> void:
	if game_won:
		return
	game_won = true
	AudioManager.play_sound("power_up", 0.0, 5.0)
	game_won_signal.emit()
