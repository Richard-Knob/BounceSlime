extends Area2D

@export var speed: float = 400.0
var direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(1)
		queue_free()
	elif area.is_in_group("enemy"):
		GameManager.add_kill()
		# 40% šance na drop RAM z nepřítele
		if randf() < 0.40:
			var ram_scene = preload("res://Scenes/ram.tscn")
			var ram = ram_scene.instantiate()
			ram.global_position = area.global_position
			get_tree().current_scene.add_child(ram)
		area.queue_free()
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
