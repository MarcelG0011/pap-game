extends Area2D

@export var soul_value: int = 10  # Quanto vale

var velocity: Vector2 = Vector2.ZERO
var fall_gravity: float = 400.0  # ✅ RENOMEADO de gravity para fall_gravity
var bounce_damping: float = 0.6
var collected: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # ✅ CORRIGIDO para AnimatedSprite2D

func _ready() -> void:
	# Toca animação (crie uma animação "idle" ou "spin")
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	
	# Efeito de "explosão" ao spawnar
	var random_direction = Vector2(randf_range(-100, 100), randf_range(-200, -100))
	velocity = random_direction
	
	# Conecta colisão com player
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy após 30 segundos se não coletar
	await get_tree().create_timer(30.0).timeout
	if not collected:
		queue_free()

func _physics_process(delta: float) -> void:
	if collected:
		return
	
	# Física simples - moeda cai e quica
	velocity.y += fall_gravity * delta  # ✅ USA fall_gravity
	position += velocity * delta
	
	# Simula quique (chão em y = 0 local)
	if position.y > 0:
		position.y = 0
		velocity.y = -velocity.y * bounce_damping
		velocity.x *= bounce_damping
		
		# Para quando velocidade é muito baixa
		if abs(velocity.y) < 50:
			velocity = Vector2.ZERO

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	
	if body.is_in_group("Player"):
		collect(body)

func collect(player: Node2D) -> void:
	collected = true
	
	# Adiciona soul ao player
	CurrencyManager.add_soul(soul_value)
	
	# Efeito visual
	animate_collection(player)
	
	# Som (adicione depois)
	# AudioManager.play_sfx("soul_collect")

func animate_collection(player: Node2D) -> void:
	# Anima a moeda indo até o player
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", player.global_position, 0.3)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	
	await tween.finished
	queue_free()
