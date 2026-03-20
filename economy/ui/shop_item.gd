extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

var item_id: String = ""
var item_data: Dictionary = {}

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func setup(id: String, data: Dictionary) -> void:
	item_id = id
	item_data = data
	
	# Configura labels
	name_label.text = data.get("name", "Unknown")
	description_label.text = data.get("description", "")
	
	var price = data.get("price", 0)
	var currency = data.get("currency", "soul")
	
	# Formata preco
	if currency == "soul":
		price_label.text = "%d Soul" % price
	elif currency == "gems":
		price_label.text = "%d Gems" % price
	
	# Verifica se pode comprar
	update_button_state()
	
	# Se for cosmetico, verifica se ja tem
	if data.type == "cosmetic":
		check_cosmetic_status()

func update_button_state() -> void:
	var price = item_data.get("price", 0)
	var currency = item_data.get("currency", "soul")
	
	var can_afford = false
	
	if currency == "soul":
		can_afford = CurrencyManager.has_soul(price)
	elif currency == "gems":
		can_afford = CurrencyManager.has_gems(price)
	
	buy_button.disabled = not can_afford
	
	if not can_afford:
		buy_button.text = "INSUFFICIENT"
	else:
		buy_button.text = "BUY"

func check_cosmetic_status() -> void:
	if ShopManager.is_cosmetic_unlocked(item_id):
		status_label.text = "OWNED"
		status_label.visible = true
		buy_button.disabled = true
		buy_button.text = "OWNED"
	else:
		status_label.visible = false

func _on_buy_pressed() -> void:
	print("[SHOP ITEM] Tentando comprar: ", item_id)
	
	# Se for cosmetico e ja tem, nao pode comprar
	if item_data.type == "cosmetic" and ShopManager.is_cosmetic_unlocked(item_id):
		print("[SHOP ITEM] Ja possui este item")
		return
	
	# Tenta comprar
	var success = ShopManager.purchase_item(item_id)
	
	if success:
		# Feedback visual
		show_purchase_success()
	else:
		# Feedback de falha
		show_purchase_failed()

func show_purchase_success() -> void:
	# Animacao de sucesso
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Atualiza estado
	update_button_state()
	check_cosmetic_status()

func show_purchase_failed() -> void:
	# Animacao de falha (shake)
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(self, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(self, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(self, "position:x", original_pos.x, 0.05)
	
	# Atualiza estado
	update_button_state()
