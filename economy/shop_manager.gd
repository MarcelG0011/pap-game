extends Node

signal item_purchased(item_id: String)
signal purchase_failed(reason: String)

var shop_items: Dictionary = {}

func _ready() -> void:
	print("[SHOP] Sistema de loja inicializado")
	load_shop_catalog()

func load_shop_catalog() -> void:
	shop_items["upgrade_max_hp_1"] = {
		"name": "Max HP +5",
		"description": "Aumenta vida maxima em 5",
		"price": 100,
		"currency": "soul",
		"type": "upgrade",
		"stat": "max_hp",
		"value": 5
	}
	
	shop_items["upgrade_max_hp_2"] = {
		"name": "Max HP +10",
		"description": "Aumenta vida maxima em 10",
		"price": 250,
		"currency": "soul",
		"type": "upgrade",
		"stat": "max_hp",
		"value": 10
	}
	
	shop_items["upgrade_damage"] = {
		"name": "Damage +1",
		"description": "Aumenta dano base em 1",
		"price": 150,
		"currency": "soul",
		"type": "upgrade",
		"stat": "damage",
		"value": 1
	}
	
	shop_items["upgrade_speed"] = {
		"name": "Speed +10%",
		"description": "Aumenta velocidade em 10%",
		"price": 200,
		"currency": "soul",
		"type": "upgrade",
		"stat": "speed",
		"value": 0.1
	}
	
	shop_items["skin_red"] = {
		"name": "Red Warrior Skin",
		"description": "Skin vermelha para o personagem",
		"price": 50,
		"currency": "gems",
		"type": "cosmetic",
		"category": "skin"
	}
	
	shop_items["skin_blue"] = {
		"name": "Blue Knight Skin",
		"description": "Skin azul para o personagem",
		"price": 75,
		"currency": "gems",
		"type": "cosmetic",
		"category": "skin"
	}
	
	shop_items["trail_fire"] = {
		"name": "Fire Trail",
		"description": "Trilha de fogo ao correr",
		"price": 100,
		"currency": "gems",
		"type": "cosmetic",
		"category": "effect"
	}
	
	shop_items["emote_dance"] = {
		"name": "Dance Emote",
		"description": "Emote de danca",
		"price": 25,
		"currency": "gems",
		"type": "cosmetic",
		"category": "emote"
	}
	
	print("[SHOP] ", shop_items.size(), " items carregados")

func get_items_by_currency(currency: String) -> Array:
	var items = []
	for item_id in shop_items:
		if shop_items[item_id].currency == currency:
			items.append({
				"id": item_id,
				"data": shop_items[item_id]
			})
	return items

func get_item(item_id: String) -> Dictionary:
	return shop_items.get(item_id, {})

func purchase_item(item_id: String) -> bool:
	if not shop_items.has(item_id):
		purchase_failed.emit("Item nao existe")
		return false
	
	var item = shop_items[item_id]
	var price = item.price
	var currency = item.currency
	
	var has_enough = false
	if currency == "soul":
		has_enough = CurrencyManager.has_soul(price)
	elif currency == "gems":
		has_enough = CurrencyManager.has_gems(price)
	
	if not has_enough:
		purchase_failed.emit("Moeda insuficiente")
		print("[SHOP] Compra falhou - ", currency, " insuficiente")
		return false
	
	var success = false
	if currency == "soul":
		success = CurrencyManager.remove_soul(price)
	elif currency == "gems":
		success = CurrencyManager.remove_gems(price)
	
	if success:
		apply_item_effect(item_id, item)
		item_purchased.emit(item_id)
		print("[SHOP] Item comprado: ", item.name)
		return true
	
	return false

func apply_item_effect(item_id: String, item: Dictionary) -> void:
	match item.type:
		"upgrade":
			apply_upgrade(item)
		"cosmetic":
			unlock_cosmetic(item_id, item)

func apply_upgrade(item: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("[SHOP] Player nao encontrado para aplicar upgrade")
		return
	
	match item.stat:
		"max_hp":
			player.max_hp += item.value
			player.hp += item.value
			print("[SHOP] Max HP aumentado em ", item.value)
		"damage":
			if player.has("damage"):
				player.damage += item.value
				print("[SHOP] Damage aumentado em ", item.value)
		"speed":
			if player.has("speed"):
				player.speed += player.speed * item.value
				print("[SHOP] Speed aumentado em ", item.value * 100, "%")

func unlock_cosmetic(item_id: String, item: Dictionary) -> void:
	if not AccountManager.is_logged_in:
		print("[SHOP] Usuario nao logado")
		return
	
	if is_cosmetic_unlocked(item_id):
		print("[SHOP] Cosmetico ja desbloqueado: ", item.name)
		return
	
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO user_cosmetics (user_id, cosmetic_id, unlocked_at)
	VALUES (?, ?, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, item_id, timestamp])
	
	print("[SHOP] Cosmetico desbloqueado: ", item.name)

func get_unlocked_cosmetics() -> Array:
	if not AccountManager.is_logged_in:
		return []
	
	var user_id = AccountManager.get_user_id()
	
	var query = "SELECT cosmetic_id FROM user_cosmetics WHERE user_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id])
	
	var cosmetics = []
	for row in DatabaseManager.db.query_result:
		cosmetics.append(row["cosmetic_id"])
	
	return cosmetics

func is_cosmetic_unlocked(item_id: String) -> bool:
	if not AccountManager.is_logged_in:
		return false
	
	var user_id = AccountManager.get_user_id()
	
	var query = """
	SELECT id FROM user_cosmetics
	WHERE user_id = ? AND cosmetic_id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, item_id])
	
	return not DatabaseManager.db.query_result.is_empty()
