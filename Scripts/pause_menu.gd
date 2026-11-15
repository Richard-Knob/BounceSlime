extends CanvasLayer

## PauseMenu & Start Menu (Pixel Art Style)
## Zobrazí se automaticky při spuštění hry (jako hlavní menu)
## a během hraní se otevírá klávesou ESC nebo tlačítkem v rohu.

@export var player: Node2D
@export var terrain: TileMapLayer
@export var background: TileMapLayer

@onready var overlay: Control = $Overlay
@onready var title_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var resume_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var new_game_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NewGameButton
@onready var save_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LoadButton
@onready var restart_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton
@onready var status_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var pause_button: Button = $PauseButton

enum MenuState {
	START_MENU, # Úvodní menu při spuštění hry
	PAUSE_MENU, # Menu pauzy během hraní
	HIDDEN      # Skryto, probíhá hra
}

var current_state: MenuState = MenuState.START_MENU
var game_started: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_find_required_nodes()

	# Napojení signálů tlačítek
	resume_button.pressed.connect(_on_resume_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)

	# Zobrazíme menu hned při startu hry a pozastavíme strom hry
	show_start_menu()

func _find_required_nodes() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not terrain or not is_instance_valid(terrain):
		terrain = get_tree().current_scene.find_child("Terrain", true, false)
	if not background or not is_instance_valid(background):
		background = get_tree().current_scene.find_child("Background", true, false)

func show_start_menu() -> void:
	current_state = MenuState.START_MENU
	game_started = false
	get_tree().paused = true
	overlay.visible = true

	if pause_button:
		pause_button.visible = false

	title_label.text = "== GAME JAM =="
	resume_button.visible = false
	new_game_button.visible = true
	new_game_button.text = "NOVA HRA"
	save_button.visible = false
	load_button.visible = true
	restart_button.visible = false
	quit_button.visible = true

	status_label.text = ""
	_update_load_button_state()

	# Výběr výchozího tlačítka pro ovládání klávesnicí
	new_game_button.grab_focus()

func show_pause_menu() -> void:
	current_state = MenuState.PAUSE_MENU
	get_tree().paused = true
	overlay.visible = true

	if pause_button:
		pause_button.visible = false

	title_label.text = "== PAUZA =="
	resume_button.visible = true
	resume_button.text = "POKRACOVAT"
	new_game_button.visible = false
	save_button.visible = true
	load_button.visible = true
	restart_button.visible = true
	restart_button.text = "RESTARTOVAT"
	quit_button.visible = true

	status_label.text = ""
	_update_load_button_state()
	resume_button.grab_focus()

func hide_menu_and_resume() -> void:
	current_state = MenuState.HIDDEN
	game_started = true
	overlay.visible = false
	get_tree().paused = false

	if pause_button:
		pause_button.visible = true

func _update_load_button_state() -> void:
	if SaveManager.has_save_file():
		load_button.disabled = false
		load_button.tooltip_text = "Nacist posledni ulozenou pozici"
	else:
		load_button.disabled = true
		load_button.tooltip_text = "Zatim neni vytvoren zadny save"

func _unhandled_input(event: InputEvent) -> void:
	# Klávesa ESC nebo akce ui_cancel
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if current_state == MenuState.HIDDEN:
			show_pause_menu()
			get_viewport().set_input_as_handled()
		elif current_state == MenuState.PAUSE_MENU:
			hide_menu_and_resume()
			get_viewport().set_input_as_handled()
		# Pokud jsme v úvodním menu (START_MENU), ESC neignorujeme, hráč si musí vybrat

	# F5 Quick Save (funguje jen během aktivní hry)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		if game_started and current_state == MenuState.HIDDEN:
			quick_save()
			get_viewport().set_input_as_handled()

	# F6 Quick Load
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		if SaveManager.has_save_file():
			quick_load()
			get_viewport().set_input_as_handled()

func _on_new_game_pressed() -> void:
	GameManager.reset_state()
	hide_menu_and_resume()

func _on_resume_pressed() -> void:
	hide_menu_and_resume()

func _on_save_pressed() -> void:
	_find_required_nodes()
	var success = SaveManager.save_game(player, terrain)
	if success:
		status_label.text = "✓ HRA USPESNE ULOZENA!"
		status_label.modulate = Color(0.4, 1.0, 0.4)
		_update_load_button_state()
	else:
		status_label.text = "! CHYBA PRI UKLADANI !"
		status_label.modulate = Color(1.0, 0.3, 0.3)

func _on_load_pressed() -> void:
	_find_required_nodes()
	var success = SaveManager.load_game(player, terrain, background)
	if success:
		status_label.text = "✓ HRA BYLA NACITENA!"
		status_label.modulate = Color(0.4, 1.0, 0.4)

		# Pokud jsme načetli v úvodním menu, rovnou vstoupíme do hry
		if current_state == MenuState.START_MENU:
			hide_menu_and_resume()
	else:
		status_label.text = "! CHYBA PRI NACITANI !"
		status_label.modulate = Color(1.0, 0.3, 0.3)

func _on_restart_pressed() -> void:
	GameManager.reset_state()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_pause_button_pressed() -> void:
	if current_state == MenuState.HIDDEN:
		show_pause_menu()
	elif current_state == MenuState.PAUSE_MENU:
		hide_menu_and_resume()

func quick_save() -> void:
	_find_required_nodes()
	var success = SaveManager.save_game(player, terrain)
	if success:
		_update_load_button_state()
		_show_temporary_toast("✓ QUICK SAVE (F5)")

func quick_load() -> void:
	if not SaveManager.has_save_file():
		_show_temporary_toast("! ZADNY SAVE (F6)")
		return
	_find_required_nodes()
	var success = SaveManager.load_game(player, terrain, background)
	if success:
		_show_temporary_toast("✓ QUICK LOAD (F6)")

func _show_temporary_toast(msg: String) -> void:
	if pause_button:
		var orig_text = pause_button.text
		pause_button.text = msg
		var timer = get_tree().create_timer(1.8)
		timer.timeout.connect(func():
			if is_instance_valid(pause_button):
				pause_button.text = orig_text
		)
