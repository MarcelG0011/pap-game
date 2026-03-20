class_name Enemy extends CharacterBody2D

#region /// On Ready Variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var hitbox: Area2D = $HitBox
@onready var detection_zone: Area2D = $DetectionZone
@onready var wall_detector: RayCast2D = $WallDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#endregion

#region /// Export Variables - Stats
@export_group("Stats")
@export var max_health: int = 100
@export var damage: int = 10
@export var knockback_force: float = 200.0
#endregion

#region /// Export Variables - Movement
@export_group("Movement")
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 120.0
@export var patrol_wait_time: float = 2.0
#endregion

#region /// State Variables
enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT,
	DEAD
}

var current_state: State = State.PATROL
var direction: int = 1
#endregion

#region /// Standard Variables
var current_health: int
var gravity: float = 980.0
var player: Node2D = null
var patrol_timer: float = 0.0
var is_dead: bool = false
var is_attacking: bool = false
#endregion

func _ready() -> void:
	current_health = max_health
	
	# Conecta sinais
	if detection_zone:
		detection_zone.body_entered.connect(_on_detection_zone_entered)
		detection_zone.body_exited.connect(_on_detection_zone_exited)
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Conecta sinal de fim de animação do AnimationPlayer
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	
	print("[ENEMY] Inimigo spawnou. HP: ", current_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol()
		State.CHASE:
			process_chase()
		State.ATTACK:
			process_attack()
		State.HIT:
			process_hit(delta)
	
	update_sprite_direction()
	move_and_slide()
	update_detectors()

#region /// State Machine
func process_idle(delta: float) -> void:
	velocity.x = 0
	
	patrol_timer += delta
	if patrol_timer >= patrol_wait_time:
		change_state(State.PATROL)

func process_patrol() -> void:
	velocity.x = direction * patrol_speed
	
	if wall_detector and wall_detector.is_colliding():
		flip_direction()
	
	if floor_detector and is_on_floor() and not floor_detector.is_colliding():
		flip_direction()
	
	if player:
		change_state(State.CHASE)

func process_chase() -> void:
	if not player:
		change_state(State.PATROL)
		return
	
	var dir_to_player = sign(player.global_position.x - global_position.x)
	direction = dir_to_player
	velocity.x = direction * chase_speed
	
	var distance_to_player = abs(player.global_position.x - global_position.x)
	if distance_to_player < 40:
		change_state(State.ATTACK)
	
	if wall_detector and wall_detector.is_colliding():
		velocity.x = 0

func process_attack() -> void:
	velocity.x = 0
	# A animação já está tocando, aguarda terminar

func process_hit(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 300 * delta)

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	# Exit state
	match current_state:
		State.IDLE:
			patrol_timer = 0.0
		State.ATTACK:
			is_attacking = false
	
	current_state = new_state
	
	# Enter state e play animação
	match new_state:
		State.IDLE:
			patrol_timer = 0.0
			play_animation("Idle")
		State.PATROL:
			play_animation("Run")
		State.CHASE:
			play_animation("Run")
		State.ATTACK:
			is_attacking = true
			play_animation("Attack")
		State.HIT:
			play_animation("Idle")  # ou "hit" se tiver

func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _on_animation_finished(anim_name: String) -> void:
	# Quando animação de ataque termina
	if anim_name == "Attack" and current_state == State.ATTACK:
		is_attacking = false
		if player:
			change_state(State.CHASE)
		else:
			change_state(State.PATROL)
#endregion

#region /// Combat
func take_damage(damage_amount: int, attacker_position: Vector2) -> void:
	if is_dead or current_state == State.HIT:
		return
	
	current_health -= damage_amount
	print("[ENEMY] Tomou ", damage_amount, " de dano. HP: ", current_health, "/", max_health)
	
	var knockback_direction = sign(global_position.x - attacker_position.x)
	velocity.x = knockback_direction * knockback_force
	velocity.y = -100
	
	# Flash vermelho
	if sprite:
		sprite.modulate = Color.RED
	
	if current_health <= 0:
		die()
		return
	
	change_state(State.HIT)
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_dead and sprite:
		sprite.modulate = Color.WHITE
		
		if player:
			change_state(State.CHASE)
		else:
			change_state(State.PATROL)

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	current_state = State.DEAD
	print("[ENEMY] Morreu!")
	
	set_physics_process(false)
	
	if hurtbox:
		hurtbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("monitoring", false)
	
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	
	if detection_zone:
		detection_zone.set_deferred("monitoring", false)
		detection_zone.set_deferred("monitorable", false)
	
	# Toca animação de morte
	if animation_player and animation_player.has_animation("Death"):
		animation_player.play("Death")
		await animation_player.animation_finished
	else:
		# Fade out se não tiver animação
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
			await tween.finished
	
	queue_free()
#endregion

#region /// Detection & Collision
func _on_detection_zone_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player = body
		print("[ENEMY] Player detectado! Perseguindo...")
		if current_state == State.PATROL or current_state == State.IDLE:
			change_state(State.CHASE)

func _on_detection_zone_exited(body: Node2D) -> void:
	if body == player:
		player = null
		print("[ENEMY] Player saiu da zona. Voltando a patrulhar...")
		if current_state == State.CHASE:
			change_state(State.PATROL)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			print("[ENEMY] Atacou o player! Dano: ", damage)
#endregion

#region /// Utilities
func flip_direction() -> void:
	direction *= -1
	patrol_timer = 0.0

func update_sprite_direction() -> void:
	if not sprite:
		return
		
	if direction > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

func update_detectors() -> void:
	if wall_detector:
		wall_detector.target_position.x = abs(wall_detector.target_position.x) * direction
	
	if floor_detector:
		floor_detector.target_position.x = abs(floor_detector.target_position.x) * direction
#endregion
