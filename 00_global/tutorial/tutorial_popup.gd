# res://ui/tutorial/tutorial_popup.gd
extends CanvasLayer

signal popup_closed

@onready var panel: Panel = $Panel
@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var image_rect: TextureRect = %ImageRect
@onready var video_player: VideoStreamPlayer = %VideoPlayer
@onready var progress_label: Label = %ProgressLabel
@onready var continue_button: Button = %ContinueButton
@onready var skip_button: Button = %SkipButton

var tutorial_id: String = ""
var current_step: int = 1
var total_steps: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pausa jogo
	get_tree().paused = true
	
	# Conecta botões
	continue_button.pressed.connect(_on_continue_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Animação entrada
	_fade_in()

func setup(id: String, title: String, body: String, media_path: String, step: int = 1, total: int = 1) -> void:
	tutorial_id = id
	current_step = step
	total_steps = total
	
	# Título
	if title_label:
		title_label.text = title
	
	# Corpo
	if body_label:
		body_label.text = body
	
	# Progresso
	if progress_label:
		if total_steps > 1:
			progress_label.text = "Step %d of %d" % [step, total]
			progress_label.visible = true
		else:
			progress_label.visible = false
	
	# Skip button (só visível se multi-passo)
	if skip_button:
		skip_button.visible = (total_steps > 1)
	
	# Botão texto
	if continue_button:
		if step < total_steps:
			continue_button.text = "NEXT"
		else:
			continue_button.text = "GOT IT!"
	
	# Media
	_load_media(media_path)
	
	# Foco
	continue_button.grab_focus()

func _load_media(path: String) -> void:
	if path.is_empty():
		_hide_media()
		return
	
	if not ResourceLoader.exists(path):
		push_warning("[TUTORIAL] Media não encontrada: ", path)
		_hide_media()
		return
	
	var ext = path.get_extension().to_lower()
	
	# Vídeo
	if ext in ["ogv", "webm"]:
		var stream = load(path)
		if stream:
			video_player.stream = stream
			video_player.visible = true
			video_player.play()
			image_rect.visible = false
	# Imagem
	elif ext in ["png", "jpg", "jpeg", "webp"]:
		var texture = load(path)
		if texture:
			image_rect.texture = texture
			image_rect.visible = true
			video_player.visible = false
	else:
		push_warning("[TUTORIAL] Formato não suportado: ", ext)
		_hide_media()

func _hide_media() -> void:
	if image_rect:
		image_rect.visible = false
	if video_player:
		video_player.visible = false
		video_player.stop()

func _fade_in() -> void:
	if not panel:
		return
	
	panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _fade_out() -> void:
	if not panel:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tween.finished

func _on_continue_pressed() -> void:
	await _close()

func _on_skip_pressed() -> void:
	# Marca TODOS como vistos
	TutorialManager.reset_all_tutorials()
	await _close()

func _close() -> void:
	await _fade_out()
	
	# Para vídeo
	if video_player and video_player.is_playing():
		video_player.stop()
	
	# Despausa
	get_tree().paused = false
	
	# Emite
	popup_closed.emit()
	
	# Remove
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_continue_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()
