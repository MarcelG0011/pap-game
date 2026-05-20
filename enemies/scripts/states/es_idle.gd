class_name ESIdle
extends EnemyState

func enter() -> void:
	enemy.velocity.x = 0.0
	enemy.play_animation("idle")

func physics_update(_delta: float) -> void:
	# Não faz nada. O DecisionEngine decide quando sair deste estado.
	pass
