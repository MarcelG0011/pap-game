extends Control

signal purchase_completed(gems_amount: int)
signal cancelled

@onready var card_input: LineEdit = %CardNumberInput
@onready var expiry_input: LineEdit = %ExpiryInput
@onready var cvv_input: LineEdit = %CvvInput
@onready var pay_button: Button = %PayButton
@onready var cancel_button: Button = %CancelButton
@onready var package_label: Label = %PackageLabel
@onready var price_label: Label = %PriceLabel
@onready var success_overlay: ColorRect = %SuccessOverlay
@onready var success_label: Label = %SuccessLabel

var package_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Liga botões
	if pay_button:
		pay_button.pressed.connect(_on_pay_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)

	# Conecta formatação automática
	if card_input:
		card_input.text_changed.connect(_on_card_text_changed)
		card_input.text_submitted.connect(func(_t): expiry_input.grab_focus())
	if expiry_input:
		expiry_input.text_changed.connect(_on_expiry_text_changed)
		expiry_input.text_submitted.connect(func(_t): cvv_input.grab_focus())
	if cvv_input:
		cvv_input.text_changed.connect(_on_cvv_text_changed)

	# Esconde overlay de sucesso
	if success_overlay:
		success_overlay.visible = false
	if card_input:
		card_input.grab_focus()

func setup(package: Dictionary) -> void:
	package_data = package
	var gems: int = package.get("gems", 0)
	var price: String = package.get("price", "0.00")

	if package_label:
		package_label.text = "Package: %d Gems" % gems
	if price_label:
		price_label.text = "EUR %s" % price

# ---- Formatação Automática ----
func _on_card_text_changed(new_text: String) -> void:
	var cursor_pos = card_input.caret_column
	var clean_text = new_text.replace(" ", "")
	if clean_text.length() > 16: clean_text = clean_text.substr(0, 16)

	var formatted = ""
	for i in range(clean_text.length()):
		if i > 0 and i % 4 == 0:
			formatted += " "
		formatted += clean_text[i]

	card_input.set_block_signals(true)
	card_input.text = formatted
	card_input.caret_column = formatted.length() + max(cursor_pos - new_text.length(), 0)
	card_input.set_block_signals(false)

func _on_expiry_text_changed(new_text: String) -> void:
	var cursor_pos = expiry_input.caret_column
	var clean_text = new_text.replace("/", "").substr(0, 4)
	if clean_text.length() >= 2:
		clean_text = clean_text.substr(0, 2) + "/" + clean_text.substr(2)

	expiry_input.set_block_signals(true)
	expiry_input.text = clean_text
	expiry_input.caret_column = clean_text.length() + max(cursor_pos - new_text.length(), 0)
	expiry_input.set_block_signals(false)

func _on_cvv_text_changed(new_text: String) -> void:
	var clean_text = new_text.replace(" ", "").substr(0, 4)
	cvv_input.set_block_signals(true)
	cvv_input.text = clean_text
	cvv_input.set_block_signals(false)

# ---- Validações Realistas ----
func _luhn_check(card_number: String) -> bool:
	var sum = 0
	var alternate = false
	for i in range(card_number.length() - 1, -1, -1):
		var n = int(card_number[i])
		if alternate:
			n *= 2
			if n > 9: n -= 9
		sum += n
		alternate = not alternate
	return sum % 10 == 0

func _get_card_brand(card_number: String) -> String:
	if card_number.begins_with("4"): return "Visa"
	if card_number.begins_with("5"): return "Mastercard"
	if card_number.begins_with("34") or card_number.begins_with("37"): return "Amex"
	return "Card"

func _is_expiry_valid(expiry: String) -> bool:
	if not expiry.match("\\d{2}/\\d{2}"): return false
	var parts = expiry.split("/")
	var month = int(parts[0])
	var year = int(parts[1]) + 2000
	if month < 1 or month > 12: return false
	var now = Time.get_datetime_dict_from_system()
	if year < now.year: return false
	if year == now.year and month < now.month: return false
	return true

func _on_pay_pressed() -> void:
	var card: String = card_input.text.replace(" ", "")
	var expiry: String = expiry_input.text
	var cvv: String = cvv_input.text

	# Validações progressivas
	if card.length() < 13 or not _luhn_check(card):
		_show_error("Your card was declined. Please check your details.")
		return
	if not _is_expiry_valid(expiry):
		_show_error("Your card has expired. Please use another card.")
		return
	if cvv.length() < 3:
		_show_error("Your card's security code is invalid.")
		return

	# Estado de processamento
	pay_button.disabled = true
	pay_button.text = "Processing..."
	card_input.editable = false
	expiry_input.editable = false
	cvv_input.editable = false

	# Simula latência de rede
	await get_tree().create_timer(1.5).timeout

	# "Processa" pagamento
	var gems: int = package_data.get("gems", 0)
	CurrencyManager.add_gems(gems)
	purchase_completed.emit(gems)

	# Mostra sucesso com animação
	_show_success(gems)

func _show_success(gems: int) -> void:
	if success_label:
		success_label.text = "Payment Successful\n+%d Gems" % gems
	if success_overlay:
		success_overlay.modulate.a = 0.0
		success_overlay.visible = true
		var tween := create_tween()
		tween.tween_property(success_overlay, "modulate:a", 1.0, 0.3)

	await get_tree().create_timer(2.0).timeout
	_close()

func _show_error(_msg: String) -> void:
	card_input.clear()
	expiry_input.clear()
	cvv_input.clear()
	card_input.grab_focus()

	# Efeito de tremor
	var orig := position
	var tween := create_tween()
	tween.tween_property(self, "position:x", orig.x + 5, 0.05)
	tween.tween_property(self, "position:x", orig.x - 5, 0.05)
	tween.tween_property(self, "position:x", orig.x + 5, 0.05)
	tween.tween_property(self, "position:x", orig.x, 0.05)

func _on_cancel_pressed() -> void:
	cancelled.emit()
	_close()

func _close() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
