extends Node

## AudioManager Autoload
## Spravuje zvuky a hudbu v retro stylu

var bgm_player: AudioStreamPlayer
var sound_players: Array[AudioStreamPlayer] = []
const MAX_SOUND_CHANNELS: int = 8

var sounds = {
	"shoot": preload("res://Assets/Audio/jump.wav"),
	"explode": preload("res://Assets/Audio/explosion.wav"),
	"ram": preload("res://Assets/Audio/power_up.wav"),
	"coin": preload("res://Assets/Audio/coin.wav"),
	"hurt": preload("res://Assets/Audio/hurt.wav"),
	"tap": preload("res://Assets/Audio/tap.wav")
}

var bgm_stream = preload("res://Assets/Audio/time_for_adventure.mp3")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = -10.0
	bgm_player.bus = "Master"
	add_child(bgm_player)
	bgm_player.play()
	
	# SFX Pool
	for i in range(MAX_SOUND_CHANNELS):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sound_players.append(p)

func play_sound(sound_name: String, pitch_range: float = 0.15, volume_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		return
	
	var stream = sounds[sound_name]
	for p in sound_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			p.volume_db = volume_db
			p.play()
			return

func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()

func play_bgm() -> void:
	if bgm_player and not bgm_player.playing:
		bgm_player.play()
