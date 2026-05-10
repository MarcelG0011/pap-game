# res://auth/ui/forgot_password_screen.gd
extends Control

enum Step { USERNAME, SECURITY_QUESTION, NEW_PASSWORD, SUCCESS }

# Referencias com verificações
@onready var username_container: VBoxContainer = get_node_or_null("%UsernameContainer")
@onready var question_container: VBoxContainer = get_node_or_null("%QuestionContainer")
@onready var password_container: VBoxContainer = get_node_or_null("%PasswordContainer")
@onready var success_container: VBoxContainer = get_node_or_null("%SuccessContainer")

@onready var username_input: LineEdit = get_node_or_null("%UsernameInput")
@onready var security_question_label: Label = get_node_or_null("%SecurityQuestionLabel")
@onready var security_answer_input: LineEdit = get_node_or_null("%SecurityAnswerInput")
@onready var new_password_input: LineEdit = get_node_or_null("%NewPasswordInput")
@onready var confirm_password_input: LineEdit = get_node_or_null("%ConfirmPasswordInput")

@onready var next_button: Button = get_node_or_null("%NextButton")
@onready var back_button: Button = get_node_or_null("%BackButton")
@onready var back_to_login_button: Button = get_node_or_null("%BackToLoginButton")
@onready var error_label: Label = get_node_or_null("%ErrorLabel")

var current_step: Step = Step.USERNAME
var current_username: String = ""

func _ready() -> void:
	_verify_nodes()
	_connect_signals()
	_show_step(Step.USERNAME)

func _verify_nodes() -> void:
	var missing = []
	
	if not username_container: missing.append("UsernameContainer")
	if not question_container: missing.append("QuestionContainer")
	if not password_container: missing.append("PasswordContainer")
	if not success_container: missing.append("SuccessContainer")
	if not username_input: missing.append("UsernameInput")
	if not security_answer_input: missing.append("SecurityAnswerInput")
	if not new_password_input: missing.append("NewPasswordInput")
	if not confirm_password_input: missing.append("ConfirmPasswordInput")
	if not next_button: missing.append("NextButton")
	if not back_button: missing.append("BackButton")
	if not error_label: missing.append("ErrorLabel")
	
	if not missing.is_empty():
		push_error("[FORGOT PASSWORD] Nós faltando: " + str(missing))

func _connect_signals() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if back_to_login_button:
		back_to_login_button.pressed.connect(_on_back_to_login_pressed)
	
	if username_input:
		username_input.text_submitted.connect(func(_t): _on_next_pressed())
	
	if security_answer_input:
		security_answer_input.text_submitted.connect(func(_t): _on_next_pressed())
	
	if new_password_input and confirm_password_input:
		new_password_input.text_submitted.connect(func(_t): confirm_password_input.grab_focus())
		confirm_password_input.text_submitted.connect(func(_t): _on_next_pressed())

func _show_step(step: Step) -> void:
	current_step = step
	_hide_error()
	
	# Esconde todos
	if username_container: username_container.visible = false
	if question_container: question_container.visible = false
	if password_container: password_container.visible = false
	if success_container: success_container.visible = false
	
	# Mostra step atual
	match step:
		Step.USERNAME:
			if username_container: username_container.visible = true
			if next_button: next_button.text = "NEXT"
			if back_button: back_button.visible = false
			if username_input: username_input.grab_focus()
		
		Step.SECURITY_QUESTION:
			if question_container: question_container.visible = true
			if next_button: next_button.text = "VERIFY"
			if back_button: back_button.visible = true
			if security_answer_input: security_answer_input.grab_focus()
		
		Step.NEW_PASSWORD:
			if password_container: password_container.visible = true
			if next_button: next_button.text = "RESET PASSWORD"
			if back_button: back_button.visible = true
			if new_password_input: new_password_input.grab_focus()
		
		Step.SUCCESS:
			if success_container: success_container.visible = true
			if next_button: next_button.visible = false
			if back_button: back_button.visible = false

func _on_next_pressed() -> void:
	match current_step:
		Step.USERNAME:
			_verify_username()
		Step.SECURITY_QUESTION:
			_verify_answer()
		Step.NEW_PASSWORD:
			_reset_password()

func _verify_username() -> void:
	if not username_input:
		return
	
	var username = username_input.text.strip_edges()
	
	if username.is_empty():
		_show_error("Enter username or email")
		return
	
	var user = DatabaseManager.get_user_by_username(username)
	if user.is_empty():
		user = DatabaseManager.get_user_by_email(username)
	
	if user.is_empty():
		_show_error("User not found")
		return
	
	var question = user.get("security_question", "")
	if question.is_empty():
		_show_error("No security question set")
		return
	
	current_username = username
	
	if security_question_label:
		security_question_label.text = question
	
	_show_step(Step.SECURITY_QUESTION)

# Atualiza apenas a função _verify_answer()

func _verify_answer() -> void:
	if not security_answer_input:
		return
	
	var answer = security_answer_input.text.strip_edges()
	
	if answer.is_empty():
		_show_error("Enter your answer")
		return
	
	var user = DatabaseManager.get_user_by_username(current_username)
	if user.is_empty():
		user = DatabaseManager.get_user_by_email(current_username)
	
	#Compara case-insensitive
	var answer_hash = answer.to_lower().strip_edges().sha256_text()
	var stored_hash = user.get("security_answer_hash", "")
	
	if answer_hash != stored_hash:
		_show_error("Incorrect answer")
		if security_answer_input:
			security_answer_input.text = ""
		return
	
	_show_step(Step.NEW_PASSWORD)
	pass

func _reset_password() -> void:
	if not new_password_input or not confirm_password_input:
		return
	
	var new_pass = new_password_input.text
	var confirm_pass = confirm_password_input.text
	
	if new_pass.is_empty():
		_show_error("Enter new password")
		return
	
	if new_pass.length() < 6:
		_show_error("Password must be 6+ characters")
		return
	
	if new_pass != confirm_pass:
		_show_error("Passwords don't match")
		return
	
	var user = DatabaseManager.get_user_by_username(current_username)
	if user.is_empty():
		user = DatabaseManager.get_user_by_email(current_username)
	
	var user_id = user.get("id", 0)
	var pass_hash = new_pass.sha256_text()
	
	DatabaseManager.update_password(user_id, pass_hash)
	
	_show_step(Step.SUCCESS)

func _on_back_pressed() -> void:
	match current_step:
		Step.SECURITY_QUESTION:
			_show_step(Step.USERNAME)
		Step.NEW_PASSWORD:
			_show_step(Step.SECURITY_QUESTION)

func _on_back_to_login_pressed() -> void:
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")

func _show_error(msg: String) -> void:
	if error_label:
		error_label.text = msg
		error_label.visible = true

func _hide_error() -> void:
	if error_label:
		error_label.visible = false
