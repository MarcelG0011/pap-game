@icon("res://general/icons/death_area.svg")
class_name InstantDeathArea extends Area2D

@export_group("Settings")
@export var death_audio : AudioStream
@export var delay_before_state_change : float = 0.0

func _ready() -> void:
	# Configuração de segurança via código
	monitorable = false
	# Conecta o sinal se não estiver conectado no editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("InstantDeathArea: Player detetado!")
		_trigger_death_sequence(body)

func _trigger_death_sequence(player: Player) -> void:
	if player.is_dead:
		return
		
	# Se quiseres um pequeno atraso dramático (0.1s)
	if delay_before_state_change > 0:
		await get_tree().create_timer(delay_before_state_change).timeout
	
	# Chama a função no player
	player.trigger_instant_death()
