extends Control

signal purchase_simulated(gems_amount: int)
signal cancelled

@onready var package_info: Label = %PackageInfo
@onready var price_info: Label = %PriceInfo
@onready var simulate_button: Button = %SimulateButton
@onready var cancel_button: Button = %CancelButton
@onready var result_label: Label = %ResultLabel

var package_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conecta botões
	simulate_button.pressed.connect(_on_simulate_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# ✅ NÃO pausa aqui - a loja já pausou
	# get_tree().paused = true  ← REMOVA

func setup(package: Dictionary) -> void:
	package_data = package
	
	# Atualiza labels
	var gems = package.get("gems", 0)
	var bonus = package.get("bonus", "")
	var price = package.get("price", "0.00")
	
	package_info.text = "Package: %d Gems %s" % [gems, bonus]
	price_info.text = "Price: EUR %s" % price

func _on_simulate_pressed() -> void:
	print("[PAYMENT DEMO] Simulando compra...")
	
	# Desabilita botão
	simulate_button.disabled = true
	simulate_button.text = "PROCESSING..."
	
	# Timer com PROCESS_MODE_ALWAYS
	var timer = Timer.new()
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = 1.5
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	await timer.timeout
	timer.queue_free()
	
	# "Processa" o pagamento
	var gems_amount = package_data.get("gems", 0)
	
	print("[PAYMENT DEMO] Adicionando ", gems_amount, " gems")
	
	# Adiciona gems
	CurrencyManager.add_gems(gems_amount)
	
	# Mostra sucesso
	show_success(gems_amount)

func show_success(gems: int) -> void:
	result_label.text = "SUCCESS!\n+%d Gems added to your account" % gems
	result_label.visible = true
	
	print("[PAYMENT DEMO] Sucesso! Gems adicionados: ", gems)
	
	# Esconde botões
	simulate_button.visible = false
	
	# Muda botão cancel para "Close"
	cancel_button.text = "Close"
	
	# Emite sinal
	purchase_simulated.emit(gems)
	
	# Timer com PROCESS_MODE_ALWAYS
	var timer = Timer.new()
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	await timer.timeout
	timer.queue_free()
	
	_on_cancel_pressed()

func _on_cancel_pressed() -> void:
	print("[PAYMENT DEMO] Fechando popup")
	
	# ✅ NÃO despausa - a loja ainda está aberta
	# get_tree().paused = false  ← JÁ REMOVIDO
	
	cancelled.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
