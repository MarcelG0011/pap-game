extends CanvasLayer

signal start_pressed

@onready var story_label: RichTextLabel = %StoryLabel
@onready var start_button: Button = %StartButton
@onready var background: ColorRect = $ColorRect
@onready var narration_player: AudioStreamPlayer = $NarrationPlayer

# Caminho do áudio – confirma que o ficheiro está mesmo nesta pasta
const NARRATION_PATH = "res://general/audio/narration_audio.mp3"

const LINES: Array[String] = [
	"You awaken in a cold, damp cell.",
	"No memory of who you are. No memory of how you got here.",
	"The distant clank of chains echoes through dark corridors.",
	"As you explore this hostile world and defeat the guardians that haunt it, fragments of your past will return.",
	"Each battle reveals a piece of the truth.",
	"The darkness hides secrets. The light brings answers.",
    "Which path will you choose?"
]

const LINE_TIMES: Array[float] = [
	0.0,   # "You awaken..."
	3.5,   # "No memory..."
	7.4,   # "The distant..."
	10.6,  # "As you explore..."
	17.7,  # "Each battle..."
	22.4,  # "The darkness..."
	27.0   # "Which path..."
]

var current_line: int = 0
var text_finished: bool = false
var narration_playing: bool = false
var transitioning: bool = false   # impede duplo clique

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	story_label.text = ""
	start_button.visible = false
	start_button.modulate.a = 0.0
	start_button.pressed.connect(_on_start_pressed)

	# Carrega e inicia a narração
	if ResourceLoader.exists(NARRATION_PATH):
		Audio.play_narration(load(NARRATION_PATH))
		narration_playing = true
	else:
		push_error("[INTRO] Ficheiro de áudio não encontrado: " + NARRATION_PATH)
		# Animação de entrada do fundo
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 1.0)

func _process(_delta: float) -> void:
	if text_finished:
		return

	if narration_playing and narration_player.playing:
		var current_time = narration_player.get_playback_position()

		if current_line < LINES.size():
			var next_time = LINE_TIMES[current_line]
			if current_time >= next_time:
				_show_line(current_line)
				current_line += 1

				if current_line >= LINES.size():
					text_finished = true
					_show_button()
	elif not narration_player.playing and narration_playing:
		while current_line < LINES.size():
			_show_line(current_line)
			current_line += 1
		text_finished = true
		_show_button()

	if start_button.visible and text_finished:
		start_button.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.003) * 0.3

func _show_line(index: int) -> void:
	var current_text = story_label.text
	if current_text != "":
		current_text += "\n\n"
	story_label.text = current_text + LINES[index]

func _show_button() -> void:
	start_button.visible = true
	var tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.5)
	start_button.grab_focus()

func _on_start_pressed() -> void:
	if transitioning:
		return
	transitioning = true

	# Para a narração
	if narration_playing:
		Audio.narration_player.stop()

	# Despausa o jogo
	get_tree().paused = false

	# Emite o sinal uma única vez
	start_pressed.emit()

	# Fade‑out no fundo (ColorRect TEM modulate)
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()

func _input(event: InputEvent) -> void:
	if not text_finished and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")):
		while current_line < LINES.size():
			_show_line(current_line)
			current_line += 1
		text_finished = true
		_show_button()
	elif text_finished and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")):
		_on_start_pressed()
	if event.is_action_pressed("ui_cancel") and text_finished:
		_on_start_pressed()
