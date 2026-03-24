extends DirectionalLight2D

func _ready() -> void:
	# Direção do feixe (para baixo)
	rotation_degrees = 90
	
	# Intensidade
	energy = 1.5
	
	# Cor (luz do dia)
	color = Color("#FFFFCC")
	
	# Blend mode
	blend_mode = Light2D.BLEND_MODE_ADD
