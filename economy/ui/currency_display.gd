extends Control

@onready var soul_label: Label = %SoulLabel
@onready var gems_label: Label = %GemsLabel

func _ready() -> void:
	# Conecta aos sinais do CurrencyManager
	CurrencyManager.soul_changed.connect(_on_soul_changed)
	CurrencyManager.gems_changed.connect(_on_gems_changed)
	
	# Atualiza valores iniciais
	_on_soul_changed(CurrencyManager.get_soul())
	_on_gems_changed(CurrencyManager.get_gems())
	
	print("[CURRENCY DISPLAY] Inicializado")

func _on_soul_changed(new_amount: int) -> void:
	soul_label.text = str(new_amount)
	print("[CURRENCY DISPLAY] Soul atualizado: ", new_amount)
	
	# Animação de "ping" ao ganhar
	animate_label(soul_label)

func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = str(new_amount)
	print("[CURRENCY DISPLAY] Gems atualizado: ", new_amount)
	
	# Animação de "ping" ao ganhar
	animate_label(gems_label)

func animate_label(label: Label) -> void:
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1)
