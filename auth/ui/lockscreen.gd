extends CanvasLayer

signal unlock_requested(password: String)

@onready var password_input: LineEdit = %PasswordInput
@onready var unlock_button: Button = %UnlockButton
@onready var error_label: Label = %ErrorLabel

func _ready() -> void:
	layer = 100 # Camada superior
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	
	if error_label: error_label.hide()
	
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_pressed)
	
	if password_input:
		password_input.text_submitted.connect(_on_password_submitted)
		# Foco diferido para garantir que o LineEdit está pronto
		password_input.grab_focus.call_deferred()

func _input(_event: InputEvent) -> void:
	# Se o evento for uma tecla e o PasswordInput estiver com o foco, 
	# deixamos o Godot processar normalmente para escrever.
	if password_input.has_focus():
		return 
		
	# Caso contrário, bloqueamos o input para o resto do jogo
	get_viewport().set_input_as_handled()

func _on_unlock_pressed() -> void:
	if password_input:
		_attempt_unlock(password_input.text)

func _on_password_submitted(password: String) -> void:
	_attempt_unlock(password)

func _attempt_unlock(password: String) -> void:
	if password.is_empty():
		show_error("Digite a senha")
		return
	unlock_requested.emit(password)

func show_error(message: String) -> void:
	if error_label:
		error_label.text = message
		error_label.show()
		await get_tree().create_timer(2.5).timeout
		if error_label: error_label.hide()
	
	if password_input:
		password_input.clear()
		password_input.grab_focus()

func close() -> void:
	queue_free()
