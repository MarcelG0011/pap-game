# res://pickups/soul_pickup.gd
class_name SoulPickup
extends CharacterBody2D

#const SOUL_PICKUP_AUDIO = preload("res://audio/sfx/soul_pickup.ogg")  # ← ajusta path

@export var soul_amount: int = 5

var bounce_count: int = 8

@onready var area_2d: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_2d.body_entered.connect(_on_player_entered)
	
	# Animação de spawn
	_spawn_animation()
	

func _physics_process(delta: float) -> void:
	if bounce_count > 0:
		velocity += get_gravity() * delta
		var collision: KinematicCollision2D = move_and_collide(velocity * delta)
		if collision:
			bounce_count -= 1
			velocity = velocity.bounce(collision.get_normal()) * 0.75
			velocity.x *= 0.75
	
	# Rotação suave
	if sprite:
		sprite.rotation += delta * 2.0

func _spawn_animation() -> void:
	if sprite:
		sprite.scale = Vector2.ZERO
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.3)

func _on_player_entered(n: Node2D) -> void:
	if n is Player:
		# Adiciona soul
		CurrencyManager.add_soul(soul_amount)
		
		# Som
		#Audio.play_spatial_sound(SOUL_PICKUP_AUDIO, global_position)
		
		# Efeito visual
		_pickup_effect()
		
		# Desconecta
		area_2d.body_entered.disconnect(_on_player_entered)
		
		# Remove com delay (para efeito visual)
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _pickup_effect() -> void:
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	pass
