# res://auth/lockscreen.gd
extends CanvasLayer

signal unlock_requested(password: String)

@onready var password_input: LineEdit = %PasswordInput
@onready var unlock_button: Button = %UnlockButton
@onready var error_label: Label = %ErrorLabel
@onready var background: ColorRect = %Background  # Fundo que cobre tudo

func _ready() -> void:
	# Process mode ALWAYS para funcionar pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# PAUSA O JOGO
	get_tree().paused = true
	
	# Garante que está visível
	visible = true
	
	# Conecta sinais
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_pressed)
	
	if password_input:
		password_input.text_submitted.connect(_on_password_submitted)
		password_input.grab_focus()
	
	print("[LOCKSCREEN] Tela de bloqueio ativada - Jogo pausado")

func _on_unlock_pressed() -> void:
	if password_input:
		_attempt_unlock(password_input.text)

func _on_password_submitted(password: String) -> void:
	_attempt_unlock(password)

func _attempt_unlock(password: String) -> void:
	if password.is_empty():
		_show_error("Digite a senha")
		return
	
	unlock_requested.emit(password)

func show_error(message: String) -> void:
	_show_error(message)

func _show_error(message: String) -> void:
	if error_label:
		error_label.text = message
		error_label.visible = true
		
		await get_tree().create_timer(3.0).timeout
		
		if error_label:
			error_label.visible = false
	
	if password_input:
		password_input.clear()
		password_input.grab_focus()

func close() -> void:
	# DESPAUSA O JOGO
	get_tree().paused = false
	queue_free()
	print("[LOCKSCREEN] Tela desbloqueada - Jogo despausado")
