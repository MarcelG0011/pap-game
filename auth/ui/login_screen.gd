extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var show_password_button: Button = %ShowPasswordButton
@onready var remember_checkbox: CheckBox = %RememberCheckbox
@onready var login_button: Button = %LoginButton
@onready var signup_button: Button = %SignupButton
@onready var forgot_password_button: Button = %ForgotPasswordButton
@onready var error_label: Label = %ErrorLabel
@onready var login_panel: PanelContainer = %LoginPanel

var is_login_processing: bool = false

func _ready() -> void:
	#aplica tema
	_apply_custom_theme()
	#animação de entrada
	_entrance_animation()
	
	hide_game_huds()
	#conecta sinais
	_connect_signals()

	# Foco inicial
	username_input.grab_focus()
	
	# Verifica auto-login
	if AccountManager.is_logged_in:
		go_to_title_screen()
	pass
	
func _apply_custom_theme() -> void :
	#Labels
	var labels = [
		get_node_or_null("CenterContainer/LoginPanel/MarginContainer/ScrollContainer/VBoxContainer/TitleContainer/TitleLabel"),
		get_node_or_null("CenterContainer/LoginPanel/MarginContainer/ScrollContainer/VBoxContainer/PasswordLabel"),
		get_node_or_null("CenterContainer/LoginPanel/MarginContainer/ScrollContainer/VBoxContainer/UsenamerLabel")
	]
	
	for label in labels:
		if label:
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
			label.add_theme_font_size_override("font_size", 16)
	
	# Title especial
	var title = get_node_or_null("CenterContainer/LoginPanel/MarginContainer/VBoxContainer/TitleLabel")
	if title:
		title.add_theme_font_size_override("font_size", 28)
		title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	
	# Inputs
	for input in [username_input, password_input]:
		if input:
			input.add_theme_color_override("font_color", Color(1, 1, 1))
			input.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.6))
	
	# Botões
	_style_button(login_button, Color(0.3, 0.5, 0.7), 18)
	_style_button(signup_button, Color(0.4, 0.4, 0.5), 14)
	_style_button(forgot_password_button, Color(0.3, 0.3, 0.4), 12)
	
	# Error label
	if error_label:
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		error_label.add_theme_font_size_override("font_size", 14)
		error_label.visible = false
	pass
	
func _style_button(button: Button, base_color: Color, font_size: int) -> void:
	if not button:
		return
	
	# Normal
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_color = base_color.lightened(0.2)
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	button.add_theme_stylebox_override("normal", style_normal)
	
	# Hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.15)
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_color = base_color.lightened(0.3)
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	button.add_theme_stylebox_override("hover", style_hover)
	
	# Pressed
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.1)
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_color = base_color
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Font
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	pass

func _entrance_animation() -> void:
	if login_panel:
		login_panel.modulate.a = 0
		login_panel.scale = Vector2(0.9, 0.9)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		tween.tween_property(login_panel, "modulate:a", 1.0, 0.5)
		tween.tween_property(login_panel, "scale", Vector2.ONE, 0.5)
	pass
		
func _connect_signals() -> void:
	login_button.pressed.connect(_on_login_pressed)
	signup_button.pressed.connect(_on_signup_pressed)
	forgot_password_button.pressed.connect(_on_forgot_password_pressed)
	show_password_button.pressed.connect(_toggle_password_visibility)
	
	username_input.text_submitted.connect(func(_text): password_input.grab_focus())
	password_input.text_submitted.connect(func(_text): _on_login_pressed())
	
	AccountManager.login_successful.connect(_on_login_successful)
	AccountManager.login_failed.connect(_on_login_failed)
	
	# Hover effects
	login_button.mouse_entered.connect(func(): _button_hover_effect(login_button))
	signup_button.mouse_entered.connect(func(): _button_hover_effect(signup_button))
	pass


func _button_hover_effect(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

	pass
	
func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	
	# Shake animation melhorada
	var original_pos = login_panel.position
	var tween = create_tween()
	tween.tween_property(login_panel, "position:x", original_pos.x + 10, 0.05)
	tween.tween_property(login_panel, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(login_panel, "position:x", original_pos.x + 10, 0.05)
	tween.tween_property(login_panel, "position:x", original_pos.x, 0.05)
	
	# Piscar error
	var error_tween = create_tween()
	error_tween.set_loops(3)
	error_tween.tween_property(error_label, "modulate:a", 0.3, 0.2)
	error_tween.tween_property(error_label, "modulate:a", 1.0, 0.2)
	pass


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
	# Animação de sucesso
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	go_to_title_screen()

func _on_login_failed(error: String) -> void:
	is_login_processing = false
	login_button.disabled = false
	login_button.text = "LOGIN"
	
	show_error(error)
	password_input.text = ""
	password_input.grab_focus()

func _on_signup_pressed() -> void:
	var signup_screen = load("res://auth/ui/signup_screen.tscn").instantiate()
	get_tree().root.add_child(signup_screen)
	queue_free()

func _on_forgot_password_pressed() -> void:
	var forgot_screen = load("res://auth/ui/forgot_password_screen.tscn").instantiate()
	get_tree().root.add_child(forgot_screen)
	queue_free()

func _toggle_password_visibility() -> void:
	password_input.secret = not password_input.secret
	show_password_button.text = "Hide" if not password_input.secret else "Show"

func hide_error() -> void:
	error_label.visible = false

func go_to_title_screen() -> void:
	print("[LOGIN] Indo para title screen...")
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
