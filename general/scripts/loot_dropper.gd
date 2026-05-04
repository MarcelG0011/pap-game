@icon("res://general/icons/loot_drop.svg")
class_name LootDropper
extends Marker2D

@export var items: Array[LootData]

func _ready() -> void:
	if owner is Enemy:
		owner.was_killed.connect(drop_loot)
	elif owner is Breakable:
		owner.destroyed.connect(drop_loot)

func drop_loot() -> void:
	# Guarda a posição ANTES do owner ser destruído
	var drop_position = global_position
	
	for i in items:
		# Verifica chance de drop
		if randf() > i.drop_chance:
			continue
		
		# Carrega a cena
		var drop_scene = load(i.item)
		if not drop_scene:
			push_error("[LOOT] Falha ao carregar: ", i.item)
			continue
		
		# Spawna múltiplas instâncias
		var count: int = randi_range(i.minimum, i.maximum)
		
		for j in count:
			var drop = drop_scene.instantiate()
			
			# ✅ CRÍTICO: Adiciona à cena ativa (level)
			var level = get_tree().current_scene
			level.call_deferred("add_child", drop)
			
			# Define posição (depois de adicionar à árvore)
			drop.call_deferred("set_global_position", drop_position)
			
			# Define velocidade inicial (se for CharacterBody2D)
			if drop is CharacterBody2D:
				drop.velocity = Vector2(
					randf_range(-50, 50),
					randf_range(-200, -400)
				)
