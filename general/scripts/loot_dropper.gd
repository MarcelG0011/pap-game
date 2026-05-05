# res://general/loot_dropper.gd
@icon("res://general/icons/loot_drop.svg")
class_name LootDropper
extends Marker2D

@export var items: Array[LootData]

func _ready() -> void:
	if owner is Enemy:
		owner.was_killed.connect(drop_loot)
	elif owner is Breakable:
		owner.destroyed.connect(drop_loot)
	else:
		push_warning("[LOOT] Owner não é Enemy nem Breakable: ", owner)
	pass
	
func drop_loot() -> void:
	# Guarda a posição ANTES do owner ser destruído
	var drop_position = global_position
	
	for i in items:
		if not i:
			push_warning("[LOOT] LootData null encontrado!")
			continue
		
		var roll = randf()
		
		if roll > i.drop_chance:
			continue
		
		var drop_scene = load(i.item)
		if not drop_scene:
			push_error("[LOOT] ERRO: Não conseguiu carregar ", i.item)
			continue
		
		var count: int = randi_range(i.minimum, i.maximum)
		
		for j in count:
			var drop = drop_scene.instantiate()
			
			var level = get_tree().current_scene
			level.call_deferred("add_child", drop)
			
			# Define posição (depois de adicionar)
			drop.call_deferred("set_global_position", drop_position)
			
			# Define velocidade inicial com variação
			if drop is CharacterBody2D:
				var spread_x = randf_range(-50, 50)
				var spread_y = randf_range(-200, -400)
				drop.velocity = Vector2(spread_x, spread_y)
	pass
