extends Node

signal item_purchased(item_id: String)
signal purchase_failed(reason: String)

var shop_items: Dictionary = {}

func _ready() -> void:
	print("[SHOP] Shop system initialized")
	load_shop_catalog()

# ==========================================
# CATALOG – SINGLE SOURCE OF TRUTH
# ==========================================
func load_shop_catalog() -> void:
	shop_items.clear()

	# ── Upgrades (Soul) ──────────────────────────────
	_add_upgrade("upgrade_max_hp_1", "Max HP +5",
		"Increases max HP by 5.", 100, "max_hp", 5, 5)
	_add_upgrade("upgrade_max_hp_2", "Max HP +10",
		"Increases max HP by 10.", 250, "max_hp", 10, 5)
	_add_upgrade("upgrade_damage", "Damage +1",
		"Increases base damage by 1.", 150, "damage", 1, 5)
	_add_upgrade("upgrade_speed", "Speed +10%",
		"Increases speed by 10%.", 200, "speed", 0.1, 5)

	# ── Skins (Gems) ─────────────────────────────────
	_add_skin("skin_red", "Red Warrior Skin",
		"Red skin for the character.", 50)
	_add_skin("skin_blue", "Blue Knight Skin",
		"Blue skin for the character.", 75)
	_add_skin("trail_fire", "Fire Trail",
		"Fire trail while running.", 100)
	_add_skin("emote_dance", "Dance Emote",
		"Dance emote.", 25)

	print("[SHOP] ", shop_items.size(), " items loaded in catalog.")

# ── Helpers to build the dictionary ─────────────
func _add_upgrade(id: String, upgrade_name: String, desc: String,
		price: int, stat: String, value: float, max_level: int) -> void:
	shop_items[id] = {
		"name": upgrade_name,
		"description": desc,
		"price": price,
		"currency": "soul",
		"type": "upgrade",
		"stat": stat,
		"value": value,
		"max_level": max_level
	}

func _add_skin(id: String, skin_name: String, desc: String, price: int) -> void:
	shop_items[id] = {
		"name": skin_name,
		"description": desc,
		"price": price,
		"currency": "gems",
		"type": "skin"
	}
# ==========================================

# ── Search utilities ──────────────────────
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

# ── Purchase with Soul ─────────────────────
func purchase_with_soul(item_id: String, cost: int) -> bool:
	if not CurrencyManager.has_soul(cost):
		purchase_failed.emit("Not enough Soul")
		return false
	if CurrencyManager.remove_soul(cost):
		if shop_items.has(item_id):
			apply_item_effect(item_id, shop_items[item_id])
		item_purchased.emit(item_id)
		return true
	return false

# ── Purchase with Gems ─────────────────────
func purchase_with_gems(item_id: String, cost: int) -> bool:
	if not CurrencyManager.has_gems(cost):
		purchase_failed.emit("Not enough Gems")
		return false
	if CurrencyManager.remove_gems(cost):
		if shop_items.has(item_id):
			apply_item_effect(item_id, shop_items[item_id])
		item_purchased.emit(item_id)
		return true
	return false

# ── Apply effects ─────────────────────────
func apply_item_effect(item_id: String, item: Dictionary) -> void:
	match item.type:
		"upgrade":
			apply_upgrade(item)
		"skin":
			unlock_skin(item_id, item)

func apply_upgrade(item: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("[SHOP] Player not found – cannot apply upgrade")
		return

	match item.stat:
		"max_hp":
			player.max_hp += item.value
			player.hp += item.value
			print("[SHOP] Max HP increased by ", item.value)
		"damage":
			if player.has("damage"):
				player.damage += item.value
				print("[SHOP] Damage increased by ", item.value)
		"speed":
			if player.has("speed"):
				player.speed += player.speed * item.value
				print("[SHOP] Speed increased by ", item.value * 100, "%")

func unlock_skin(item_id: String, item: Dictionary) -> void:
	if not AccountManager.is_logged_in:
		print("[SHOP] User not logged in")
		return
	if is_skin_unlocked(item_id):
		print("[SHOP] Skin already unlocked: ", item["name"])
		return
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	var query = """
	INSERT INTO user_cosmetics (user_id, cosmetic_id, unlocked_at)
	VALUES (?, ?, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, item_id, timestamp])
	print("[SHOP] Skin unlocked: ", item["name"])

func is_skin_unlocked(item_id: String) -> bool:
	if not AccountManager.is_logged_in:
		return false
	var user_id = AccountManager.get_user_id()
	var query = "SELECT id FROM user_cosmetics WHERE user_id = ? AND cosmetic_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id, item_id])
	return not DatabaseManager.db.query_result.is_empty()

func get_upgrade_level(item_id: String) -> int:
	if not AccountManager.is_logged_in:
		return 1
	var user_id = AccountManager.get_user_id()
	var query = "SELECT level FROM user_upgrades WHERE user_id = ? AND upgrade_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id, item_id])
	if not DatabaseManager.db.query_result.is_empty():
		return DatabaseManager.db.query_result[0]["level"]
	return 1
	

func get_gem_packages() -> Array:
	return [
		{"gems": 100, "price": "0.99", "bonus": ""},
		{"gems": 500, "price": "3.99", "bonus": "+50 Bonus!"},
		{"gems": 1000, "price": "6.99", "bonus": "+200 Bonus!"},
		{"gems": 2500, "price": "14.99", "bonus": "+500 Bonus!"}
	]
