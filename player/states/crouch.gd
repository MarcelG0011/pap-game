class_name PlayerStateCrouch extends PlayerState
@export var deceleration_rate : float = 10 

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Crouch" )
	player.collision_stand.disabled = true
	player.collision_crouch.disabled = false
	pass
	
func exit() -> void :
	player.collision_stand.disabled = false
	player.collision_crouch.disabled = true
	pass
	
func handle_input(_event: InputEvent) -> PlayerState:
	# APENAS DOWN + JUMP faz descer
	if _event.is_action_pressed("jump"):
		# Se está a segurar down E está numa onewayplatform
		if Input.is_action_pressed("down") \
		and player.one_way_plataform_ray_cast.is_colliding():
			print("[CROUCH] Descendo de plataforma com DOWN+JUMP")
			# empurra o jogador para baixo
			player.position.y += 10
			return fall
		else:
			# Jump normal se não estiver em onewayplatform
			return jump
	return null
	
func process( _delta: float ) -> PlayerState:
	# Verifica se soltou o botão de agachar
	if not Input.is_action_pressed("down"):
		return idle
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x -= player.velocity.x * deceleration_rate * _delta
	
	# NÃO FAZ MAIS NADA!
	# Crouch NUNCA cai automaticamente
	
	return next_state
