class_name ESTakeHit
extends EnemyState

@export var stun_duration: float = 0.4

var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	enemy.velocity.x = 0.0
	blackboard.can_decide = false

func physics_update(delta: float) -> void:
	timer += delta
	if timer >= stun_duration:
		blackboard.can_decide = true
