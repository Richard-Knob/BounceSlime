extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var time_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TimeLabel
@onready var distance_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DistanceLabel
@onready var ram_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RamLabel
@onready var kills_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/KillsLabel
@onready var restart_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var menu_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	GameManager.game_won_signal.connect(_on_game_won)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_game_won() -> void:
	get_tree().paused = true
	overlay.visible = true
	
	var total_seconds = int(GameManager.game_time)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	time_label.text = "CAS: %02d:%02d" % [minutes, seconds]
	distance_label.text = "VZDALENOST: %d m [CIL 1000m OK!]" % int(GameManager.distance_m)
	ram_label.text = "RAM MODULY: %d / 30 [CIL 30 RAM OK!]" % GameManager.ram_count
	kills_label.text = "ZABITO ALTMANU: %d" % GameManager.enemies_killed
	
	restart_button.grab_focus()

func _on_restart_pressed() -> void:
	GameManager.reset_state()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.reset_state()
	get_tree().paused = false
	get_tree().reload_current_scene()
