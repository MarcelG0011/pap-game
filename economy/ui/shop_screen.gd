extends CanvasLayer

@onready var items_container: VBoxContainer = %ItemsContainer
@onready var soul_label: Label = %SoulLabel
@onready var gems_label: Label = %GemsLabel
@onready var close_button: Button = %CloseButton
@onready var tab_container: TabContainer = %TabContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	_setup_tabs()
	_update_currency_display()
	_populate_shop()

	close_button.pressed.connect(_on_close_pressed)

	# Connect to currency change signals
	CurrencyManager.soul_changed.connect(_on_soul_changed)
	CurrencyManager.gems_changed.connect(_on_gems_changed)

func _setup_tabs() -> void:
	if tab_container:
		tab_container.set_tab_title(0, "🗡️ UPGRADES")
		tab_container.set_tab_title(1, "👕 SKINS")

func _populate_shop() -> void:
	_clear_items()
	var current_tab = tab_container.current_tab

	match current_tab:
		0: _populate_upgrades()
		1: _populate_skins()

func _populate_upgrades() -> void:
	var upgrades = ShopManager.get_items_by_currency("soul")
	for upgrade in upgrades:
		_add_shop_item(upgrade.id, upgrade.data)

func _populate_skins() -> void:
	var skins = ShopManager.get_items_by_currency("gems")
	for skin in skins:
		_add_shop_item(skin.id, skin.data)

func _add_shop_item(item_id: String, data: Dictionary) -> void:
	var item = _create_shop_item_ui(item_id, data)
	items_container.add_child(item)

func _create_shop_item_ui(item_id: String, data: Dictionary) -> PanelContainer:
	# Main container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 100)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	# Main HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# VBox info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# Level (if upgrade)
	if data.get("type") == "upgrade" and data.has("max_level"):
		var current_level = ShopManager.get_upgrade_level(item_id)
		var level_label = Label.new()
		level_label.text = "Level: %d/%d" % [current_level, data.max_level]
		level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		vbox.add_child(level_label)

	# Buy button
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(150, 50)

	var price = data.get("price", 0)
	var currency = data.get("currency", "soul")
	if currency == "soul":
		buy_button.text = "💎 %d Soul" % price
	elif currency == "gems":
		buy_button.text = "💠 %d Gems" % price

	buy_button.pressed.connect(func(): _attempt_purchase(item_id, data))

	# Hover effect
	buy_button.mouse_entered.connect(func(): buy_button.modulate = Color(1.2, 1.2, 1.2))
	buy_button.mouse_exited.connect(func(): buy_button.modulate = Color.WHITE)

	hbox.add_child(buy_button)

	return panel

func _attempt_purchase(item_id: String, _item: Dictionary) -> void:
	var success = ShopManager.purchase_item(item_id)
	if success:
		_show_purchase_effect()
		_populate_shop()
	else:
		_shake_screen()

func _show_purchase_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _shake_screen() -> void:
	var original_offset = offset
	var tween = create_tween()
	tween.tween_property(self, "offset:x", original_offset.x + 5, 0.05)
	tween.tween_property(self, "offset:x", original_offset.x - 5, 0.05)
	tween.tween_property(self, "offset:x", original_offset.x + 5, 0.05)
	tween.tween_property(self, "offset:x", original_offset.x, 0.05)

func _update_currency_display() -> void:
	if soul_label:
		soul_label.text = "💎 %d" % CurrencyManager.get_soul()
	if gems_label:
		gems_label.text = "💠 %d" % CurrencyManager.get_gems()

func _clear_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

func _on_soul_changed(_new_amount: int) -> void:
	if soul_label:
		soul_label.text = "💎 %d" % _new_amount

func _on_gems_changed(_new_amount: int) -> void:
	if gems_label:
		gems_label.text = "💠 %d" % _new_amount

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()
