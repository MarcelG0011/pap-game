extends CanvasLayer

@onready var tab_container: TabContainer = %TabContainer
@onready var currency_display: Control = %CurrencyDisplay
@onready var close_button: Button = %CloseButton
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var cosmetics_container: VBoxContainer = %CosmeticsContainer
@onready var gems_shop_container: VBoxContainer = %GemsShopContainer
@onready var background: ColorRect = $ColorRect

var current_currency: String = "soul"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	close_button.pressed.connect(_on_close_pressed)

	if currency_display and currency_display.has_method("update_display"):
		currency_display.update_display()

	if current_currency == "soul":
		setup("soul")

func setup(currency: String) -> void:
	current_currency = currency
	if tab_container:
		if currency == "soul":
			tab_container.set_tab_title(0, "Upgrades")
			tab_container.set_tab_hidden(0, false)
			tab_container.set_tab_hidden(1, true)
			if tab_container.get_tab_count() > 2:
				tab_container.set_tab_hidden(2, true)
			tab_container.current_tab = 0
		else:
			tab_container.set_tab_title(1, "Cosmetics")
			if tab_container.get_tab_count() > 2:
				tab_container.set_tab_title(2, "Gems Shop")
			tab_container.set_tab_hidden(0, true)
			tab_container.set_tab_hidden(1, false)
			if tab_container.get_tab_count() > 2:
				tab_container.set_tab_hidden(2, false)
			tab_container.current_tab = 1

	_populate_shop()

func _populate_shop() -> void:
	_clear_container(upgrades_container)
	_clear_container(cosmetics_container)
	_clear_container(gems_shop_container)

	if current_currency == "soul":
		_populate_upgrades()
	else:
		_populate_cosmetics()
		_populate_gems_shop()

func _populate_upgrades() -> void:
	var items = ShopManager.get_items_by_currency("soul")
	for item in items:
		_add_shop_item(upgrades_container, item.id, item.data)

func _populate_cosmetics() -> void:
	var items = ShopManager.get_items_by_currency("gems")
	for item in items:
		_add_shop_item(cosmetics_container, item.id, item.data)

func _populate_gems_shop() -> void:
	var packages = ShopManager.get_gem_packages()
	for package in packages:
		_add_gem_package(gems_shop_container, package)

func _add_gem_package(container: VBoxContainer, package: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 60)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title = Label.new()
	title.text = "%d Gems %s" % [package.gems, package.bonus]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 0.8))
	vbox.add_child(title)

	var price_label = Label.new()
	price_label.text = "EUR %s" % package.price
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(price_label)

	var buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(80, 35)
	buy_button.add_theme_font_size_override("font_size", 12)
	buy_button.pressed.connect(func(): _on_buy_gems_package(package))

	buy_button.mouse_entered.connect(func(): buy_button.modulate = Color(1.2, 1.2, 1.2))
	buy_button.mouse_exited.connect(func(): buy_button.modulate = Color.WHITE)

	hbox.add_child(buy_button)
	container.add_child(panel)

func _on_buy_gems_package(package: Dictionary) -> void:
	var popup = load("res://economy/ui/payment_demo_popup.tscn").instantiate()
	add_child(popup)
	popup.setup(package)

func _add_shop_item(container: VBoxContainer, item_id: String, data: Dictionary) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 70)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	if data.get("type") == "upgrade" and data.has("max_level"):
		var current_level = ShopManager.get_upgrade_level(item_id)
		var level_label = Label.new()
		level_label.text = "Level: %d/%d" % [current_level, data.max_level]
		level_label.add_theme_font_size_override("font_size", 11)
		level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		vbox.add_child(level_label)

	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(80, 35)
	buy_button.add_theme_font_size_override("font_size", 12)

	var price = data.get("price", 0)
	var is_skin = data.get("type") == "skin"
	var is_owned = is_skin and ShopManager.is_skin_unlocked(item_id)

	if is_owned:
		buy_button.text = "OWNED"
		buy_button.disabled = true
	else:
		if data.get("currency", "soul") == "soul":
			buy_button.text = "%d Soul" % price
		else:
			buy_button.text = "%d Gems" % price

	buy_button.pressed.connect(func(): _attempt_purchase(item_id))

	buy_button.mouse_entered.connect(func(): buy_button.modulate = Color(1.2, 1.2, 1.2))
	buy_button.mouse_exited.connect(func(): buy_button.modulate = Color.WHITE)

	hbox.add_child(buy_button)
	container.add_child(panel)

func _attempt_purchase(item_id: String) -> void:
	var data = ShopManager.get_item(item_id)
	if data.is_empty():
		return
	var success = false
	if data.currency == "soul":
		success = ShopManager.purchase_with_soul(item_id, data.price)
	else:
		success = ShopManager.purchase_with_gems(item_id, data.price)

	if success:
		_show_purchase_effect()
		_populate_shop()
	else:
		_shake_screen()

func _show_purchase_effect() -> void:
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate", Color(1.2, 1.2, 1.0), 0.1)
		tween.tween_property(background, "modulate", Color.WHITE, 0.1)

func _shake_screen() -> void:
	var orig = offset
	var tween = create_tween()
	tween.tween_property(self, "offset:x", orig.x + 3, 0.05)
	tween.tween_property(self, "offset:x", orig.x - 3, 0.05)
	tween.tween_property(self, "offset:x", orig.x + 3, 0.05)
	tween.tween_property(self, "offset:x", orig.x, 0.05)

func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()
