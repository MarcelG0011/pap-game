extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var confirm_password_input: LineEdit = %ConfirmPasswordInput
@onready var signup_button: Button = %SignupButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel

var is_signup_processing: bool = false

func _ready() -> void:
	print("[SIGNUP] Tela de cadastro inicializada")
	
	# Conecta sinais
	signup_button.pressed.connect(_on_signup_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Enter para próximo campo
	username_input.text_submitted.connect(func(_t): email_input.grab_focus())
	email_input.text_submitted.connect(func(_t): password_input.grab_focus())
	password_input.text_submitted.connect(func(_t): confirm_password_input.grab_focus())
	confirm_password_input.text_submitted.connect(func(_t): _on_signup_pressed())
	
	# Conecta sinais do AccountManager
	AccountManager.signup_successful.connect(_on_signup_successful)
	AccountManager.signup_failed.connect(_on_signup_failed)
	
	# Foco inicial
	username_input.grab_focus()

func _on_signup_pressed() -> void:
	if is_signup_processing:
		return
	
	hide_error()
	
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text
	var confirm_password = confirm_password_input.text
	
	# Tenta criar conta
	is_signup_processing = true
	signup_button.disabled = true
	signup_button.text = "Criando conta..."
	
	AccountManager.signup(username, email, password, confirm_password)

func _on_signup_successful(username: String) -> void:
	print("[SIGNUP] Conta criada: ", username)
	
	# Faz login automaticamente
	AccountManager.login(username, password_input.text, true)
	
	AccountManager.set_security_question(
		"Qual o nome do seu primeiro animal de estimacao?",
		"default"  # Resposta padrão (usuário pode mudar depois)
	)
	
	# Animação de sucesso
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	go_to_title_screen()

func _on_signup_failed(error: String) -> void:
	print("[SIGNUP] Falhou: ", error)
	
	is_signup_processing = false
	signup_button.disabled = false
	signup_button.text = "CREATE ACCOUNT"
	
	show_error(error)

func _on_back_pressed() -> void:
	var login_screen = load("res://auth/ui/login_screen.tscn").instantiate()
	get_tree().root.add_child(login_screen)
	queue_free()

func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true

func hide_error() -> void:
	error_label.visible = false

func go_to_title_screen() -> void:
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
