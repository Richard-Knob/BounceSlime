extends Area2D

var initial_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
	initial_y = position.y
	time = randf_range(0.0, 6.28) # Random fáze, aby nebobovaly všechny stejně
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta * 4.0
	position.y = initial_y + sin(time) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.add_ram(1)
		queue_free()
