extends CanvasLayer

@onready var time_label: Label = %TimeLabel
@onready var checkpoint_label: Label = %CheckpointLabel

var checkpoint_timer: Timer

func _ready() -> void:
	# Conecta sinais
	SpeedrunTimer.time_updated.connect(_on_time_updated)
	SpeedrunTimer.checkpoint_reached.connect(_on_checkpoint_reached)
	SpeedrunTimer.run_completed.connect(_on_run_completed)
	
	# Setup timer para esconder checkpoint
	checkpoint_timer = Timer.new()
	checkpoint_timer.one_shot = true
	checkpoint_timer.timeout.connect(_hide_checkpoint)
	add_child(checkpoint_timer)
	
	checkpoint_label.visible = false
	
	# Esconde se não tiver run ativa
	if not SpeedrunTimer.is_running:
		visible = false

func _on_time_updated(time_ms: int) -> void:
	visible = true
	time_label.text = SpeedrunTimer.format_time(time_ms)

func _on_checkpoint_reached(_checkpoint_name: String, _time_ms: int) -> void:
	checkpoint_label.text = " %s - %s" % [ SpeedrunTimer.format_time( _time_ms )]
	checkpoint_label.visible = true
	
	# Esconde após 3 segundos
	checkpoint_timer.start(3.0)

func _hide_checkpoint() -> void:
	checkpoint_label.visible = false

func _on_run_completed(_time_ms: int) -> void:
#  adicionar efeito visual 
	print("[HUD] Run completada!")
