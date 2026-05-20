extends Node2D

@export var level_transition: LevelTransition
@export var boss: Enemy

func _ready() -> void:
	level_transition.area_2d.monitoring = false
	level_transition.visible = false
	boss.was_killed.connect(_on_boss_killed)

func _on_boss_killed() -> void:
	level_transition.area_2d.monitoring = true
	level_transition.visible = true
