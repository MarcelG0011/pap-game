#lockscreen.gd
extends Control

signal unlock_requested(password: String)

@onready var time_label: Label = %TimeLabel
@onready var date_label: Label = %DateLabel
@onready var password_input: LineEdit = %PasswordInput
@onready var unlock_button: Button = %UnlockButton
@onready var error_label: Label = %ErrorLabel

var failed_attempts: int = 0
var max_attempts: int = 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ✅ GARANTE QUE PREENCHE A TELA
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	position = Vector2.ZERO
	
	# Conecta sinais
	unlock_button.pressed.connect(_on_unlock_pressed)
	password_input.text_submitted.connect(_on_password_submitted)
	
	# Foco no input
	password_input.grab_focus()
	
	# Atualiza relógio
	update_time()
	
	print("[LOCKSCREEN] Tela de bloqueio ativada")
	print("[LOCKSCREEN] Size: ", size)
	print("[LOCKSCREEN] Position: ", position)

func _process(_delta: float) -> void:
	update_time()

func update_time() -> void:
	var time_dict = Time.get_datetime_dict_from_system()
	
	# Hora
	time_label.text = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	
	# Data
	var months = ["January", "February", "March", "April", "May", "June",
				  "July", "August", "September", "October", "November", "December"]
	date_label.text = "%s %d, %d" % [months[time_dict.month - 1], time_dict.day, time_dict.year]

func _on_unlock_pressed() -> void:
	attempt_unlock()

func _on_password_submitted(_text: String) -> void:
	attempt_unlock()

func attempt_unlock() -> void:
	var password = password_input.text
	
	if password.is_empty():
		show_error("Digite sua senha")
		return
	
	unlock_requested.emit(password)

func show_error(message: String) -> void:
	failed_attempts += 1
	
	error_label.text = "%s (%d/%d)" % [message, failed_attempts, max_attempts]
	error_label.visible = true
	
	password_input.text = ""
	password_input.grab_focus()
	
	# Shake animation
	var tween = create_tween()
	tween.tween_property(password_input, "position:x", password_input.position.x + 10, 0.05)
	tween.tween_property(password_input, "position:x", password_input.position.x - 10, 0.05)
	tween.tween_property(password_input, "position:x", password_input.position.x + 10, 0.05)
	tween.tween_property(password_input, "position:x", password_input.position.x, 0.05)
	
	# Bloqueia permanentemente após max tentativas
	if failed_attempts >= max_attempts:
		lock_permanently()

func lock_permanently() -> void:
	error_label.text = "Muitas tentativas! Conta bloqueada."
	password_input.editable = false
	unlock_button.disabled = true
	
	# Logout automático após 5 segundos
	await get_tree().create_timer(5.0).timeout
	AccountManager.logout()
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")
