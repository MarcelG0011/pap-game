extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var show_password_button: Button = %ShowPasswordButton
@onready var remember_checkbox: CheckBox = %RememberCheckbox
@onready var login_button: Button = %LoginButton
@onready var signup_button: Button = %SignupButton
@onready var forgot_password_button: Button = %ForgotPasswordButton
@onready var error_label: Label = %ErrorLabel

var is_login_processing: bool = false

func _ready() -> void:
	print("[LOGIN] Tela de login inicializada")
	
	hide_game_huds()
	
	# Conecta sinais
	login_button.pressed.connect(_on_login_pressed)
	signup_button.pressed.connect(_on_signup_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	show_password_button.pressed.connect(_toggle_password_visibility)
	
	username_input.text_submitted.connect(func(_text): password_input.grab_focus())
	password_input.text_submitted.connect(func(_text): _on_login_pressed())
	
	# Conecta sinais do AccountManager
	AccountManager.login_successful.connect(_on_login_successful)
	AccountManager.login_failed.connect(_on_login_failed)
	
	# Foco inicial
	username_input.grab_focus()
	
	# Verifica auto-login
	if AccountManager.is_logged_in:
		print("[LOGIN] Usuario ja logado, indo para title screen")
		go_to_title_screen()

func hide_game_huds() -> void:
	var huds = ["PlayerHub", "SpeedrunHub", "PauseManager"]
	for hud_name in huds:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud and "visible" in hud:
			hud.visible = false

func _on_login_pressed() -> void:
	if is_login_processing:
		return
	
	hide_error()
	
	var username = username_input.text.strip_edges()
	var password = password_input.text
	var remember = remember_checkbox.button_pressed
	
	# Validações básicas
	if username.is_empty():
		show_error("Enter your username or email")
		username_input.grab_focus()
		return
	
	if password.is_empty():
		show_error("Enter your password")
		password_input.grab_focus()
		return
	
	# Tenta login
	is_login_processing = true
	login_button.disabled = true
	login_button.text = "Entering..."
	
	AccountManager.login(username, password, remember)

func _on_login_successful(username: String) -> void:
	print("[LOGIN] Login bem-sucedido: ", username)
	
	# Animação de sucesso
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	go_to_title_screen()

func _on_login_failed(error: String) -> void:
	print("[LOGIN] Login falhou: ", error)
	
	is_login_processing = false
	login_button.disabled = false
	login_button.text = "LOGIN"
	
	show_error(error)
	password_input.text = ""
	password_input.grab_focus()

func _on_signup_pressed() -> void:
	print("[LOGIN] Indo para tela de cadastro")
	
	var signup_screen = load("res://auth/ui/signup_screen.tscn").instantiate()
	get_tree().root.add_child(signup_screen)
	queue_free()

func _on_forgot_password_pressed() -> void:
	print("[LOGIN] Indo para recuperacao de senha")
	
	var forgot_screen = load("res://auth/ui/forgot_password_screen.tscn").instantiate()
	get_tree().root.add_child(forgot_screen)
	queue_free()

func _toggle_password_visibility() -> void:
	password_input.secret = not password_input.secret
	show_password_button.text = "Hide" if not password_input.secret else "Show"

func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	
	# Shake animation
	var original_pos = error_label.position
	var tween = create_tween()
	tween.tween_property(error_label, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(error_label, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(error_label, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(error_label, "position:x", original_pos.x, 0.05)

func hide_error() -> void:
	error_label.visible = false

func go_to_title_screen() -> void:
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")

func _input(event: InputEvent) -> void:
	# ESC para sair (opcional)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
