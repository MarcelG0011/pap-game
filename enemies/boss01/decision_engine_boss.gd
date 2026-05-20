class_name DecisionEngineBoss
extends DecisionEngine

@onready var es_walk: ESWalk = %ESWalk
@onready var es_stun: ESStun = %ESStun
@onready var es_death: ESDeath = %ESDeath
@onready var es_cleave: ESCleave = %ESCleave

func decide() -> EnemyState:
	if blackboard.health <= 0:
		return es_death
	
	if blackboard.damage_source:
		return es_stun
	
	if not blackboard.can_decide:
		return null
	
	# Se houver alvo (jogador detetado)
	if blackboard.target:
		var dist = blackboard.distance_to_target
		# Se o jogador estiver perto, faz cleave (com uma probabilidade)
		if dist < 80.0 and randf() < 0.4:
			return es_cleave
		# Persegue o jogador
		var dir = sign(blackboard.target.global_position.x - enemy.global_position.x)
		enemy.change_dir(dir)
		return es_walk
	
	# Patrulha: nunca para, continua a andar entre os limites definidos
	return es_walk
