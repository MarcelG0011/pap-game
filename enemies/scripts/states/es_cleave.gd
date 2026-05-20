class_name ESCleave
extends EnemyState

@export var anticipation_time: float = 0.7
@export var recovery_time: float = 0.5

var phase: int = 0
var timer: float = 0.0

func enter() -> void:
	phase = 0
	timer = 0.0
	enemy.velocity.x = 0.0
	blackboard.can_decide = false
	enemy.play_animation("cleave")

func physics_update(delta: float) -> void:
	timer += delta
	match phase:
		0:
			if timer >= anticipation_time:
				phase = 1
				timer = 0.0
				_execute_damage()
		1:
			if timer >= recovery_time:
				blackboard.can_decide = true

func _execute_damage() -> void:
	var attack_area = enemy.get_node_or_null("CleaveAttackArea")
	if attack_area:
		attack_area.activate(0.3)
