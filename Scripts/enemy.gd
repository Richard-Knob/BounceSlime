extends Area2D

const SPEED: int = 105

@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	Engine.time_scale = 1.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Zkusíme použít ochranný RAM štít
		if GameManager.absorb_hit_with_ram():
			if body.has_method("add_screenshake"):
				body.add_screenshake(0.5)
			AudioManager.play_sound("explode")
			queue_free()
			return
		
		# Pokud hráč nemá RAM, je to smrtící zásah
		AudioManager.play_sound("hurt")
		if body.has_method("add_screenshake"):
			body.add_screenshake(0.8)
		Engine.time_scale = 0.35
		$Timer.start()

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene.call_deferred()

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var direction = (player.global_position - global_position).normalized()
	global_position += direction * SPEED * delta
