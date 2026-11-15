extends Area2D

func _on_body_entered(body: Node2D) -> void:
	AudioManager.play_sound("hurt")
	Engine.time_scale = 0.3

	$Timer.start()

func _on_timer_timeout():
	get_tree().reload_current_scene.call_deferred()

func _ready() -> void:
	Engine.time_scale = 1
