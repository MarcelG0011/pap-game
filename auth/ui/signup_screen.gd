# res://auth/ui/signup_screen.gd
extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var confirm_password_input: LineEdit = %ConfirmPasswordInput
@onready var security_question_option: OptionButton = %SecurityQuestionOption
@onready var security_answer_input: LineEdit = %SecurityAnswerInput
@onready var show_password_button: Button = %ShowPasswordButton
@onready var signup_button: Button = %SignupButton
@onready var login_button: Button = %LoginButton
@onready var error_label: Label = %ErrorLabel

const SECURITY_QUESTIONS = [
	"What is your mother's maiden name?",
	"What was the name of your first pet?",
	"What country were you born in?",
	"What is your favorite movie?",
	"What is your father's middle name?",
]

var is_signup_processing: bool = false

func _ready() -> void:
	_populate_security_questions()
	_connect_signals()
	username_input.grab_focus()

func _populate_security_questions() -> void:
	if security_question_option:
		security_question_option.clear()
		for question in SECURITY_QUESTIONS:
			security_question_option.add_item(question)

func _connect_signals() -> void:
	signup_button.pressed.connect(_on_signup_pressed)
	login_button.pressed.connect(_on_login_pressed)
	show_password_button.pressed.connect(_toggle_password_visibility)
	
	username_input.text_submitted.connect(func(_t): email_input.grab_focus())
	email_input.text_submitted.connect(func(_t): password_input.grab_focus())
	password_input.text_submitted.connect(func(_t): confirm_password_input.grab_focus())
	confirm_password_input.text_submitted.connect(func(_t): security_answer_input.grab_focus())
	security_answer_input.text_submitted.connect(func(_t): _on_signup_pressed())
	
	AccountManager.signup_successful.connect(_on_signup_successful)
	AccountManager.signup_failed.connect(_on_signup_failed)

func _on_signup_pressed() -> void:
	if is_signup_processing:
		return
	
	hide_error()
	
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text
	var confirm_password = confirm_password_input.text
	var security_question = SECURITY_QUESTIONS[security_question_option.selected]
	var security_answer = security_answer_input.text.strip_edges()
	
	# Validações
	if username.is_empty():
		show_error("Enter a username")
		username_input.grab_focus()
		return
	
	if username.length() < 3:
		show_error("Username must be at least 3 characters")
		username_input.grab_focus()
		return
	
	if email.is_empty():
		show_error("Enter an email")
		email_input.grab_focus()
		return
	
	if not _is_valid_email(email):
		show_error("Invalid email format")
		email_input.grab_focus()
		return
	
	if password.is_empty():
		show_error("Enter a password")
		password_input.grab_focus()
		return
	
	if password.length() < 6:
		show_error("Password must be at least 6 characters")
		password_input.grab_focus()
		return
	
	if password != confirm_password:
		show_error("Passwords don't match")
		confirm_password_input.text = ""
		confirm_password_input.grab_focus()
		return
	
	if security_answer.is_empty():
		show_error("Enter a security answer")
		security_answer_input.grab_focus()
		return
	
	if security_answer.length() < 2:
		show_error("Security answer too short")
		security_answer_input.grab_focus()
		return
	
	# Tenta criar conta
	is_signup_processing = true
	signup_button.disabled = true
	signup_button.text = "Creating account..."
	
	AccountManager.signup(username, email, password, security_question, security_answer)

func _on_signup_successful(username: String) -> void:
	print("[SIGNUP] Conta criada com sucesso: ", username)
	
	# Animação sucesso
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Vai para login
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")

func _on_signup_failed(error: String) -> void:
	is_signup_processing = false
	signup_button.disabled = false
	signup_button.text = "SIGN UP"
	
	show_error(error)

func _on_login_pressed() -> void:
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")

func _toggle_password_visibility() -> void:
	password_input.secret = not password_input.secret
	confirm_password_input.secret = not confirm_password_input.secret
	show_password_button.text = "Hide" if not password_input.secret else "Show"

func _is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true

func hide_error() -> void:
	error_label.visible = false
