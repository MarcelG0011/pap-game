extends Control

@onready var tab_container: TabContainer = %TabContainer
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var cosmetics_container: VBoxContainer = %CosmeticsContainer
@onready var gems_shop_container: VBoxContainer = %GemsShopContainer
@onready var close_button: Button = %CloseButton

var shop_item_scene = preload("res://economy/ui/shop_item.tscn")

func _ready() -> void:
	# ✅ ADICIONE PROCESS MODE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("[SHOP SCREEN] Loja aberta")
	
	# ✅ PAUSA O JOGO
	get_tree().paused = true
	
	# Conecta botão
	close_button.pressed.connect(_on_close_pressed)
	
	# Conecta sinal de compra
	ShopManager.item_purchased.connect(_on_item_purchased)
	ShopManager.purchase_failed.connect(_on_purchase_failed)
	
	# Popula loja
	populate_shop()

func populate_shop() -> void:
	# Limpa containers
	clear_container(upgrades_container)
	clear_container(cosmetics_container)
	
	# Adiciona upgrades (Soul)
	var soul_items = ShopManager.get_items_by_currency("soul")
	for item_data in soul_items:
		add_shop_item(upgrades_container, item_data.id, item_data.data)
	
	# Adiciona cosmeticos (Gems)
	var gem_items = ShopManager.get_items_by_currency("gems")
	for item_data in gem_items:
		add_shop_item(cosmetics_container, item_data.id, item_data.data)
	
	# Adiciona opcoes de compra de Gems (DEMO)
	populate_gems_shop()

func add_shop_item(container: VBoxContainer, item_id: String, item_data: Dictionary) -> void:
	var item = shop_item_scene.instantiate()
	container.add_child(item)
	
	# Configura o item
	if item.has_method("setup"):
		item.setup(item_id, item_data)

func populate_gems_shop() -> void:
	clear_container(gems_shop_container)
	
	# Pacotes de Gems (DEMO)
	var gem_packages = [
		{"gems": 100, "price": "0.99", "bonus": ""},
		{"gems": 500, "price": "3.99", "bonus": "+50 Bonus!"},
		{"gems": 1000, "price": "6.99", "bonus": "+200 Bonus!"},
		{"gems": 2500, "price": "14.99", "bonus": "+500 Bonus!"}
	]
	
	for package in gem_packages:
		add_gem_package(package)

func add_gem_package(package: Dictionary) -> void:
	var item = HBoxContainer.new()
	item.custom_minimum_size.y = 50
	
	# Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title = Label.new()
	title.text = "%d Gems %s" % [package.gems, package.bonus]
	title.add_theme_font_size_override("font_size", 14)
	
	var price_label = Label.new()
	price_label.text = "EUR %s" % package.price
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	info_vbox.add_child(title)
	info_vbox.add_child(price_label)
	
	# Botao
	var buy_button = Button.new()
	buy_button.text = "BUY [DEMO]"
	buy_button.custom_minimum_size.x = 100
	buy_button.pressed.connect(func(): _on_buy_gems_demo(package))
	
	item.add_child(info_vbox)
	item.add_child(buy_button)
	
	gems_shop_container.add_child(item)

func _on_buy_gems_demo(package: Dictionary) -> void:
	print("[SHOP] Abrindo popup de demonstracao...")
	show_payment_demo(package)

func show_payment_demo(package: Dictionary) -> void:
	var popup = load("res://economy/ui/payment_demo_popup.tscn").instantiate()
	add_child(popup)
	
	# Configura popup
	popup.setup(package)
	
	# Conecta sinais
	popup.purchase_simulated.connect(func(gems): _on_gems_purchased(gems))
	popup.cancelled.connect(func(): print("[SHOP] Compra cancelada"))

func _on_gems_purchased(gems: int) -> void:
	print("[SHOP] Gems comprados (DEMO): ", gems)
	# A UI já vai atualizar automaticamente via signal do CurrencyManager

func clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _on_item_purchased(item_id: String) -> void:
	print("[SHOP SCREEN] Item comprado: ", item_id)
	# Atualiza a UI (re-popula)
	populate_shop()

func _on_purchase_failed(reason: String) -> void:
	print("[SHOP SCREEN] Compra falhou: ", reason)
	# TODO: Mostrar mensagem de erro para o usuario

func _on_close_pressed() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
