extends Area2D

@onready var interact_label: Label = $InteractLabel

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = true
		interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_nearby = false
		interact_label.visible = false

func _input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):  # E ou Enter
		open_shop()

func open_shop() -> void:
	print("[SHOP KEEPER] Abrindo loja...")
	var shop = load("res://economy/ui/shop_screen.tscn").instantiate()
	get_tree().root.add_child(shop)
