extends Node2D

@export var slime: Slime
@export_file("*.tscn") var boss_scene_path: String

func _ready() -> void:
	if slime:
		slime.was_killed.connect(_on_slime_killed)
	else:
		printerr("BossSummonTrigger: Referência ao Slime não definida!")

func _on_slime_killed() -> void:
	var boss_scene = load(boss_scene_path)
	var boss = boss_scene.instantiate()
	get_parent().add_child(boss)
	boss.global_position = slime.global_position + Vector2(0, -300)
	
	# Animação de queda
	var tween = create_tween()
	tween.tween_property(boss, "global_position:y", slime.global_position.y, 0.8).set_trans(Tween.TRANS_BOUNCE)
