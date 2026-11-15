extends CanvasLayer

@onready var distance_label: Label = $TopCenter/VBoxContainer/DistanceLabel
@onready var progress_bar: ProgressBar = $TopCenter/VBoxContainer/ProgressBar
@onready var ram_label: Label = $TopLeft/HBoxContainer/RamLabel
@onready var kills_label: Label = $TopRight/HBoxContainer/KillsLabel
@onready var overclock_banner: Label = $OverclockBanner

func _ready() -> void:
	overclock_banner.visible = false
	
	GameManager.distance_changed.connect(_on_distance_changed)
	GameManager.ram_changed.connect(_on_ram_changed)
	GameManager.overclock_state_changed.connect(_on_overclock_changed)
	
	_on_ram_changed(GameManager.ram_count, GameManager.TARGET_RAM_COUNT)
	_on_distance_changed(GameManager.distance_m, GameManager.TARGET_DISTANCE_M)

func _process(_delta: float) -> void:
	kills_label.text = "KILLS: %d" % GameManager.enemies_killed

func _on_distance_changed(current: float, target: float) -> void:
	var cur_int = int(current)
	var tgt_int = int(target)
	if cur_int >= tgt_int:
		distance_label.text = "CIL: %d m / %d m [OK]" % [cur_int, tgt_int]
		distance_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		distance_label.text = "CIL: %d m / %d m" % [cur_int, tgt_int]
		distance_label.modulate = Color(1.0, 1.0, 1.0)
	
	progress_bar.max_value = target
	progress_bar.value = min(current, target)

func _on_ram_changed(count: int, target: int = 30) -> void:
	if count >= target:
		ram_label.text = "RAM: %d / %d [OK]" % [count, target]
		ram_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		ram_label.text = "RAM: %d / %d" % [count, target]
		ram_label.modulate = Color(1.0, 0.9, 0.3)

func _on_overclock_changed(active: bool) -> void:
	overclock_banner.visible = active
	if active:
		overclock_banner.text = "⚡ OVERCLOCK ACTIVATED! ⚡"
		overclock_banner.modulate = Color(1.0, 0.85, 0.2)
