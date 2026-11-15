extends Node2D

const ENEMY = preload("res://Scenes/enemy.tscn")

@export var spawn_distance: float = 220.0
@onready var player = get_tree().get_first_node_in_group("player")
@onready var timer = $Timer

func _on_timer_timeout() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# S rostoucí vzdáleností se plynule zrychluje spawn
	var progress = clamp(player.global_position.x / 10000.0, 0.0, 1.0)
	timer.wait_time = lerp(1.5, 0.65, progress)

	var enemy = ENEMY.instantiate()
	add_child(enemy)

	var side = [-1, 1].pick_random()
	var offset = Vector2(side * spawn_distance, randf_range(-180, 180))
	enemy.global_position = player.global_position + offset
