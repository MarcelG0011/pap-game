extends Node

enum REVERB_TYPE { NONE, SMALL, MEDIUM, LARGE }

@export var ui_focus_audio: AudioStream
@export var ui_select_audio: AudioStream
@export var ui_cancel_audio: AudioStream
@export var ui_success_audio: AudioStream
@export var ui_error_audio: AudioStream

var current_track: int = 0
var music_tweens: Array[Tween]
var ui_audio_player: AudioStreamPlaybackPolyphonic

@onready var music_1: AudioStreamPlayer = %Music1
@onready var music_2: AudioStreamPlayer = %Music2
@onready var ui: AudioStreamPlayer = %UI

func _ready() -> void:
	ui.play()
	ui_audio_player = ui.get_stream_playback()

func play_music(audio: AudioStream) -> void:
	var current_player: AudioStreamPlayer = get_music_player(current_track)
	
	# Se já está a tocar esta música, não faz nada
	if current_player.stream == audio and current_player.playing:
		return
	
	var next_track: int = wrapi(current_track + 1, 0, 2)
	var next_player: AudioStreamPlayer = get_music_player(next_track)
	
	# Configura a próxima música
	next_player.stream = audio
	next_player.volume_db = linear_to_db(0.0)  # Começa mudo
	next_player.play()
	
	# Para tweens antigos
	for t in music_tweens:
		if t and t.is_valid():
			t.kill()
	music_tweens.clear()
	
	# Fades
	fade_track_out(current_player)
	fade_track_in(next_player)
	
	# Atualiza track atual
	current_track = next_track

func get_music_player(i: int) -> AudioStreamPlayer:
	return music_1 if i == 0 else music_2

func fade_track_out(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_db", -80.0, 1.5)
	tween.tween_callback(player.stop)

func fade_track_in(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_db", 0.0, 1.0)
	# NÃO CHAMA player.stop() AQUI!

func set_reverb(type: REVERB_TYPE) -> void:
	var reverb_fx: AudioEffectReverb = AudioServer.get_bus_effect(1, 0)
	if not reverb_fx:
		return
	
	AudioServer.set_bus_effect_enabled(1, 0, true)
	
	match type:
		REVERB_TYPE.NONE:
			AudioServer.set_bus_effect_enabled(1, 0, false)
		REVERB_TYPE.SMALL:
			reverb_fx.room_size = 0.2
		REVERB_TYPE.MEDIUM:
			reverb_fx.room_size = 0.5
		REVERB_TYPE.LARGE:
			reverb_fx.room_size = 0.8

func play_spatial_sound(audio: AudioStream, pos: Vector2) -> void:
	var ap: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	add_child(ap)
	ap.bus = "SFX"
	ap.global_position = pos
	ap.stream = audio
	ap.finished.connect(ap.queue_free)
	ap.play()

func play_ui_audio(audio: AudioStream) -> void:
	if ui_audio_player:
		ui_audio_player.play_stream(audio)

func setup_button_audio(node: Node) -> void:
	for c in node.find_children("*", "Button"):
		if not c.pressed.is_connected(ui_select):
			c.pressed.connect(ui_select)
		if not c.focus_entered.is_connected(ui_focus_change):
			c.focus_entered.connect(ui_focus_change)

#region UI Functions

func ui_focus_change() -> void:
	play_ui_audio(ui_focus_audio)

func ui_select() -> void:
	play_ui_audio(ui_select_audio)

func ui_cancel() -> void:
	play_ui_audio(ui_cancel_audio)

func ui_success() -> void:
	play_ui_audio(ui_success_audio)

func ui_error() -> void:
	play_ui_audio(ui_error_audio)

#endregion
