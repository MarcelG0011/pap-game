extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var question_label: Label = %QuestionLabel
@onready var question_text: Label = %QuestionText
@onready var answer_label: Label = %AnswerLabel
@onready var answer_input: LineEdit = %AnswerInput
@onready var new_password_label: Label = %NewPasswordLabel
@onready var new_password_input: LineEdit = %NewPasswordInput
@onready var confirm_password_label: Label = %ConfirmPasswordLabel
@onready var confirm_password_input: LineEdit = %ConfirmPasswordInput
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel
@onready var success_label: Label = %SuccessLabel

enum Step { USERNAME, ANSWER, NEW_PASSWORD }
var current_step: Step = Step.USERNAME
var username: String = ""

func _ready() -> void:
	print("[FORGOT PASSWORD] Tela inicializada")
	
	# Conecta sinais
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	username_input.text_submitted.connect(func(_t): _on_next_pressed())
	answer_input.text_submitted.connect(func(_t): _on_next_pressed())
	new_password_input.text_submitted.connect(func(_t): confirm_password_input.grab_focus())
	confirm_password_input.text_submitted.connect(func(_t): _on_next_pressed())
	
	username_input.grab_focus()

func _on_next_pressed() -> void:
	hide_messages()
	
	match current_step:
		Step.USERNAME:
			_verify_username()
		Step.ANSWER:
			_verify_answer()
		Step.NEW_PASSWORD:
			_reset_password()

func _verify_username() -> void:
	username = username_input.text.strip_edges()
	
	if username.is_empty():
		show_error("Digite seu username")
		return
	
	# Carrega contas
	var accounts = AccountManager.load_accounts()
	var account = null
	
	for acc in accounts:
		if acc.username == username:
			account = acc
			break
	
	if not account:
		show_error("Username nao encontrado")
		return
	
	# Verifica se tem pergunta de segurança
	if account.security_question.is_empty():
		show_error("Nenhuma pergunta de seguranca configurada para esta conta")
		return
	
	# Mostra pergunta de segurança
	show_security_question(account.security_question)

func show_security_question(question: String) -> void:
	current_step = Step.ANSWER
	
	# Esconde username
	username_input.visible = false
	
	# Mostra pergunta
	question_label.visible = true
	question_text.visible = true
	question_text.text = question
	
	answer_label.visible = true
	answer_input.visible = true
	answer_input.grab_focus()
	
	next_button.text = "VERIFY"

func _verify_answer() -> void:
	var answer = answer_input.text.strip_edges()
	
	if answer.is_empty():
		show_error("Digite a resposta")
		return
	
	# Verifica resposta
	if not AccountManager.verify_security_answer(username, answer):
		show_error("Resposta incorreta")
		answer_input.text = ""
		return
	
	# Resposta correta, mostra campos de nova senha
	show_new_password_fields()

func show_new_password_fields() -> void:
	current_step = Step.NEW_PASSWORD
	
	# Esconde pergunta
	question_label.visible = false
	question_text.visible = false
	answer_label.visible = false
	answer_input.visible = false
	
	# Mostra campos de senha
	new_password_label.visible = true
	new_password_input.visible = true
	confirm_password_label.visible = true
	confirm_password_input.visible = true
	new_password_input.grab_focus()
	
	next_button.text = "RESET PASSWORD"

func _reset_password() -> void:
	var new_password = new_password_input.text
	var confirm_password = confirm_password_input.text
	
	# Validações
	if new_password.length() < 6:
		show_error("Senha deve ter no minimo 6 caracteres")
		return
	
	if new_password != confirm_password:
		show_error("Senhas nao coincidem")
		return
	
	# Reseta senha
	if AccountManager.reset_password(username, new_password):
		show_success("Senha resetada com sucesso!\n\nVoltando para login...")
		
		# Volta para login após 2 segundos
		await get_tree().create_timer(2.0).timeout
		go_to_login()
	else:
		show_error("Erro ao resetar senha")

func _on_back_pressed() -> void:
	go_to_login()

func go_to_login() -> void:
	var login_screen = load("res://auth/ui/login_screen.tscn").instantiate()
	get_tree().root.add_child(login_screen)
	queue_free()

func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	success_label.visible = false

func show_success(message: String) -> void:
	success_label.text = message
	success_label.visible = true
	error_label.visible = false
	
	next_button.disabled = true

func hide_messages() -> void:
	error_label.visible = false
	success_label.visible = false
