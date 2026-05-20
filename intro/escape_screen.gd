extends CanvasLayer

signal continue_pressed
signal main_menu_pressed

@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var background: ColorRect = $ColorRect
@onready var narration_player: AudioStreamPlayer = $NarrationPlayer

var _hud_nodes: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	continue_button.pressed.connect(func(): continue_pressed.emit(); _close())
	main_menu_button.pressed.connect(func(): main_menu_pressed.emit(); _close())

	# Guarda HUDs para esconder/mostrar
	var hud_names = ["PlayerHub", "SpeedrunHub", "CurrencyDisplay", "PauseMenu"]
	for hud_name in hud_names:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud:
			_hud_nodes.append(hud)

	# Inicia a narração se houver áudio configurado
	if narration_player and narration_player.stream:
		narration_player.play()

	# Animação de entrada
	background.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 1.0)

func _process(_delta: float) -> void:
	# Garante que os HUDs permanecem escondidos
	for hud in _hud_nodes:
		if is_instance_valid(hud) and hud.visible:
			hud.visible = false

func _close() -> void:
	# Para a narração se estiver a tocar
	if narration_player and narration_player.playing:
		narration_player.stop()

	# Mostra HUDs novamente
	for hud in _hud_nodes:
		if is_instance_valid(hud):
			hud.visible = true

	get_tree().paused = false
	queue_free()
