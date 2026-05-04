# res://shop/ui/shop_screen.gd
extends CanvasLayer

@onready var items_container: VBoxContainer = %ItemsContainer
@onready var soul_label: Label = %SoulLabel
@onready var gems_label: Label = %GemsLabel
@onready var close_button: Button = %CloseButton
@onready var tab_container: TabContainer = %TabContainer

# Sons
#const PURCHASE_SUCCESS = preload("res://audio/sfx/purchase_success.ogg")
#const PURCHASE_FAIL = preload("res://audio/sfx/purchase_fail.ogg")
#const HOVER_SOUND = preload("res://audio/sfx/ui_hover.ogg")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	_setup_tabs()
	_update_currency_display()
	_populate_shop()
	
	close_button.pressed.connect(_on_close_pressed)
	
	# Atualiza moedas em tempo real
	CurrencyManager.currency_changed.connect(_update_currency_display)

func _setup_tabs() -> void:
	if tab_container:
		tab_container.set_tab_title(0, "🗡️ UPGRADES")
		tab_container.set_tab_title(1, "👕 COSMETICS")
		tab_container.set_tab_title(2, "⭐ SPECIAL")

func _populate_shop() -> void:
	_clear_items()
	
	var current_tab = tab_container.current_tab
	
	match current_tab:
		0: _populate_upgrades()
		1: _populate_cosmetics()
		2: _populate_special()

func _populate_upgrades() -> void:
	var upgrades = [
		{
			"id": "damage_boost",
			"name": "Damage Boost",
			"description": "Increase attack damage by 25%",
			"cost_soul": 50,
			"icon": "res://icons/damage.png",
			"max_level": 5
		},
		{
			"id": "hp_increase",
			"name": "Max HP Boost",
			"description": "Increase maximum health",
			"cost_soul": 30,
			"icon": "res://icons/health.png",
			"max_level": 10
		},
		{
			"id": "dash_cooldown",
			"name": "Dash Upgrade",
			"description": "Reduce dash cooldown",
			"cost_soul": 100,
			"icon": "res://icons/dash.png",
			"max_level": 3
		}
	]
	
	for upgrade in upgrades:
		_add_shop_item(upgrade)

func _populate_cosmetics() -> void:
	var cosmetics = [
		{
			"id": "skin_shadow",
			"name": "Shadow Skin",
			"description": "Dark and mysterious appearance",
			"cost_gems": 50,
			"icon": "res://icons/skin_shadow.png"
		},
		{
			"id": "trail_fire",
			"name": "Fire Trail",
			"description": "Leave a trail of flames",
			"cost_gems": 75,
			"icon": "res://icons/trail_fire.png"
		}
	]
	
	for cosmetic in cosmetics:
		_add_shop_item(cosmetic)

func _populate_special() -> void:
	var specials = [
		{
			"id": "soul_multiplier",
			"name": "Soul Magnet",
			"description": "Auto-collect soul from distance",
			"cost_gems": 200,
			"icon": "res://icons/magnet.png"
		}
	]
	
	for special in specials:
		_add_shop_item(special)

func _add_shop_item(item_data: Dictionary) -> void:
	var item = _create_shop_item_ui(item_data)
	items_container.add_child(item)

func _create_shop_item_ui(data: Dictionary) -> PanelContainer:
	# Container principal
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 100)
	
	# Estilo
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.border_width_all = 2
	style.corner_radius_all = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	# HBox principal
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Ícone
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if data.has("icon") and ResourceLoader.exists(data.icon):
		icon.texture = load(data.icon)
	hbox.add_child(icon)
	
	# VBox info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Nome
	var name_label = Label.new()
	name_label.text = data.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	vbox.add_child(name_label)
	
	# Descrição
	var desc_label = Label.new()
	desc_label.text = data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	# Level (se upgrade)
	if data.has("max_level"):
		var current_level = ShopManager.get_upgrade_level(data.id)
		var level_label = Label.new()
		level_label.text = "Level: %d/%d" % [current_level, data.max_level]
		level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		vbox.add_child(level_label)
	
	# Botão comprar
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(150, 50)
	
	if data.has("cost_soul"):
		buy_button.text = "💎 %d Soul" % data.cost_soul
	elif data.has("cost_gems"):
		buy_button.text = "💠 %d Gems" % data.cost_gems
	
	buy_button.pressed.connect(func(): _attempt_purchase(data))
	
	# Hover effect
	buy_button.mouse_entered.connect(func():
		#Audio.play_sound(HOVER_SOUND)
		buy_button.modulate = Color(1.2, 1.2, 1.2)
	)
	buy_button.mouse_exited.connect(func():
		buy_button.modulate = Color.WHITE
	)
	
	hbox.add_child(buy_button)
	
	return panel

func _attempt_purchase(item: Dictionary) -> void:
	var success = false
	
	if item.has("cost_soul"):
		success = ShopManager.purchase_with_soul(item.id, item.cost_soul)
	elif item.has("cost_gems"):
		success = ShopManager.purchase_with_gems(item.id, item.cost_gems)
	
	if success:
		#Audio.play_sound(PURCHASE_SUCCESS)
		_show_purchase_effect()
		_populate_shop()  # Recarrega
	else:
		#Audio.play_sound(PURCHASE_FAIL)
		_shake_screen()

func _show_purchase_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _shake_screen() -> void:
	#var original_pos = position
	#var tween = create_tween()
	#for i in 3:
		#tween.tween_property(self, "position:x", original_pos.x + 5, 0.05)
		#tween.tween_property(self, "position:x", original_pos.x - 5, 0.05)
	#tween.tween_property(self, "position", original_pos, 0.05)
	pass
	
func _update_currency_display() -> void:
	if soul_label:
		soul_label.text = "💎 %d" % CurrencyManager.get_soul()
	if gems_label:
		gems_label.text = "💠 %d" % CurrencyManager.get_gems()

func _clear_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

func _on_close_pressed() -> void:
	get_tree().paused = false
	queue_free()
