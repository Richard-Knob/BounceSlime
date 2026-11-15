extends CharacterBody2D

@export var speed = 150
@export var render_distance: int = 30
@export var friction: float = 2

const BULLET = preload("res://Scenes/bullet.tscn")

var trauma: float = 0.0
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta: float) -> void:
	# Screen Shake útlum
	if trauma > 0.0:
		trauma = max(0.0, trauma - delta * 2.5)
		if camera:
			camera.offset = Vector2(
				randf_range(-1.0, 1.0) * trauma * 10.0,
				randf_range(-1.0, 1.0) * trauma * 10.0
			)
	
	# Vizuální efekt Overclocku
	if sprite:
		if GameManager.is_overclocked:
			sprite.modulate = Color(1.4, 1.2, 0.4)
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0)

func add_screenshake(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func recoil() -> Vector2:
	var aim_direction = get_global_mouse_position() - global_position
	var recoil_direction = -1 * aim_direction
	if GameManager.is_overclocked:
		recoil_direction *= 1.35
	return recoil_direction

func shoot() -> void:
	AudioManager.play_sound("shoot", 0.25)
	
	if GameManager.is_overclocked:
		add_screenshake(0.35)
		# Trojitý Overclock výstřel (rozptyl -15°, 0°, +15°)
		var base_dir = (get_global_mouse_position() - global_position).normalized()
		var angles = [-deg_to_rad(15), 0.0, deg_to_rad(15)]
		for a in angles:
			var bullet = BULLET.instantiate()
			var dir = base_dir.rotated(a)
			bullet.direction = dir
			bullet.rotation = dir.angle() + deg_to_rad(90)
			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position
	else:
		add_screenshake(0.18)
		var bullet = BULLET.instantiate()
		bullet.direction = (get_global_mouse_position() - global_position).normalized()
		bullet.rotation = bullet.direction.angle() + deg_to_rad(90)
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position

func _physics_process(delta: float) -> void:
	# Aktualizace uražené vzdálenosti do GameManageru
	GameManager.update_player_distance(global_position.x)

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("shoot"):
		velocity += recoil()
		shoot()

	if velocity.x < 0 and velocity.x <= -1 * friction:
		velocity.x += friction
	elif velocity.x < 0 and velocity.x > -1 * friction:
		velocity.x = 0

	if velocity.x > 0 and velocity.x >= friction:
		velocity.x -= friction
	elif velocity.x > 0 and velocity.x < friction:
		velocity.x = 0
	
	move_and_slide()
