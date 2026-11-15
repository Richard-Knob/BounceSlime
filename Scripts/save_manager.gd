extends Node

## SaveManager Autoload
## Spravuje ukládání a načítání stavu hry (pozice hráče, seed generování světa, rychlost atd.)
## Ukládá data ve formátu JSON do "user://savegame.json"

const SAVE_FILE_PATH: String = "user://savegame.json"

signal game_saved(success: bool)
signal game_loaded(success: bool)

## Zkontroluje, zda existuje uložený soubor
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## Vrátí základní metadata o savu (např. čas uložení)
func get_save_metadata() -> Dictionary:
	if not has_save_file():
		return {}
	var data = load_raw_data()
	if data and typeof(data) == TYPE_DICTIONARY:
		return {
			"timestamp": data.get("timestamp", "Neznámý čas"),
			"version": data.get("version", 1)
		}
	return {}

## Uloží aktuální stav hry
func save_game(player: Node2D, terrain: Node2D) -> bool:
	if not player:
		push_error("SaveManager: Nelze uložit, chybí reference na hráče!")
		game_saved.emit(false)
		return false

	var save_data = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"player": {
			"position_x": player.global_position.x,
			"position_y": player.global_position.y,
			"velocity_x": player.velocity.x if "velocity" in player else 0.0,
			"velocity_y": player.velocity.y if "velocity" in player else 0.0,
		},
		"terrain": {
			"world_seed": terrain.world_seed if terrain and "world_seed" in terrain else 0
		},
		"game_manager": {
			"ram_count": GameManager.ram_count,
			"enemies_killed": GameManager.enemies_killed
		}
	}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("SaveManager: Chyba při otevírání souboru pro zápis: %s (kód: %s)" % [SAVE_FILE_PATH, err])
		game_saved.emit(false)
		return false

	var json_str = JSON.stringify(save_data, "\t")
	file.store_string(json_str)
	file.close()

	print("SaveManager: Hra úspěšně uložena do: ", SAVE_FILE_PATH)
	game_saved.emit(true)
	return true

## Načte surová JSON data ze souboru
func load_raw_data() -> Variant:
	if not has_save_file():
		return null

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("SaveManager: Chyba při čtení souboru: %s (kód: %s)" % [SAVE_FILE_PATH, err])
		return null

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("SaveManager: Chyba při parsování JSONu: %s na řádku %s" % [json.get_error_message(), json.get_error_line()])
		return null

	return json.data

## Načte hru a aplikuje data na hráče a terén
func load_game(player: Node2D, terrain: Node2D, background: Node2D = null) -> bool:
	var data = load_raw_data()
	if not data or typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager: Neplatná nebo chybějící data savu.")
		game_loaded.emit(false)
		return false

	# 1. Obnovení hráče
	if player and data.has("player"):
		var p_data: Dictionary = data["player"]
		var px: float = float(p_data.get("position_x", player.global_position.x))
		var py: float = float(p_data.get("position_y", player.global_position.y))
		player.global_position = Vector2(px, py)

		if "velocity" in player:
			var vx: float = float(p_data.get("velocity_x", 0.0))
			var vy: float = float(p_data.get("velocity_y", 0.0))
			player.velocity = Vector2(vx, vy)

	# 2. Obnovení terénu a jeho seedu
	if terrain and data.has("terrain"):
		var t_data: Dictionary = data["terrain"]
		var saved_seed: int = int(t_data.get("world_seed", terrain.world_seed if "world_seed" in terrain else 0))
		if terrain.has_method("set_world_seed"):
			terrain.set_world_seed(saved_seed)
		else:
			if "world_seed" in terrain:
				terrain.world_seed = saved_seed
			if "noise" in terrain and terrain.noise:
				terrain.noise.seed = saved_seed
			if terrain.has_method("clear"):
				terrain.clear()
			if terrain.has_method("world_generation"):
				terrain.world_generation()

	# 3. Aktualizace pozadí
	if background:
		if background.has_method("reload_background"):
			background.reload_background()
		elif background.has_method("clear"):
			background.clear()
			if background.has_method("background_generation"):
				background.background_generation()

	# 4. Odstranění aktivních nepřátel a projektilů, aby hráč ihned po načtení nezemřel
	var tree = player.get_tree() if player else get_tree()
	if tree:
		for enemy in tree.get_nodes_in_group("enemy"):
			enemy.queue_free()
		for bullet in tree.get_nodes_in_group("bullet"):
			bullet.queue_free()

	# 5. Obnovení GameManager dat (RAM, Killy)
	if data.has("game_manager"):
		var gm_data: Dictionary = data["game_manager"]
		GameManager.ram_count = int(gm_data.get("ram_count", 0))
		GameManager.enemies_killed = int(gm_data.get("enemies_killed", 0))
		GameManager.ram_changed.emit(GameManager.ram_count)

	print("SaveManager: Hra byla úspěšně načtena ze savu.")
	game_loaded.emit(true)
	return true

## Smaže existující uložený soubor
func delete_save() -> bool:
	if not has_save_file():
		return false
	var dir = DirAccess.open("user://")
	if dir:
		var err = dir.remove("savegame.json")
		return err == OK
	return false
