extends Control

@onready var fade_overlay: ColorRect = %FadeOverlay  

var current_logo_index: int = 0
var can_skip: bool = false
var logos: Array[TextureRect] = []

func _ready() -> void:
	print("[SPLASH] _ready() chamado")
	
	# ✅ ESCONDE TODOS OS HUDs NO INÍCIO
	hide_all_huds_on_start()
	
	collect_logos()
	show_next_logo()

# ✅ NOVA FUNÇÃO
func hide_all_huds_on_start() -> void:
	await get_tree().process_frame
	
	var huds = ["PlayerHub", "SpeedrunHub", "PauseManager"]
	for hud_name in huds:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud and "visible" in hud:
			hud.visible = false
			print("[SPLASH] ", hud_name, " escondido no inicio")

func collect_logos() -> void:
	# Coleta TODOS os logos (unique names)
	var logo_index = 1
	while true:
		var logo = get_node_or_null("%Logo" + str(logo_index))
		if logo:
			logos.append(logo)
			print("[SPLASH] Logo encontrado: Logo", logo_index)
			logo_index += 1
		else:
			break
	
	print("[SPLASH] Total de logos: ", logos.size())

func _input(event: InputEvent) -> void:
	if event.is_pressed() and can_skip:
		print("[SPLASH] Tecla pressionada - pulando")
		skip_to_title_screen()

func show_next_logo() -> void:
	print("[SPLASH] show_next_logo() - Index: ", current_logo_index, " / ", logos.size())
	
	# Se acabaram os logos, vai para title screen
	if current_logo_index >= logos.size():
		print("[SPLASH] Todos os logos mostrados - indo para title screen")
		go_to_title_screen()
		return
	
	var logo = logos[current_logo_index]
	
	# ✅ Redimensiona baseado na altura
	if logo.texture:
		var viewport_size = get_viewport_rect().size
		var texture_size = logo.texture.get_size()
		
		var target_height = viewport_size.y * 0.7  # 70% da altura
		var scale_factor = target_height / texture_size.y
		
		logo.scale = Vector2(scale_factor, scale_factor)
		
		print("[SPLASH] Logo ", current_logo_index + 1, " redimensionado")
		print("[SPLASH] Scale: ", scale_factor)
	
	can_skip = false
	
	# ANIMAÇÃO: Fade in → Espera → Fade out
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 0.5)  # Fade in
	tween.tween_callback(func(): can_skip = true)       # Permite pular
	tween.tween_interval(2.0)                            # Mostra 2s
	tween.tween_property(logo, "modulate:a", 0.0, 0.5)  # Fade out
	tween.tween_callback(func(): logo.visible = false)  # Esconde
	
	await tween.finished
	
	# Próximo logo
	current_logo_index += 1
	show_next_logo()

func skip_to_title_screen() -> void:
	print("[SPLASH] Pulando para title screen...")
	
	# Para todas as animações
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	
	# Esconde todos os logos
	for logo in logos:
		logo.visible = false
	
	go_to_title_screen()


func go_to_title_screen() -> void:
	print("[SPLASH] Splash screens finalizados")
	
	# VERIFICA AUTO-LOGIN (Remember Me)
	if AccountManager.is_logged_in:
		print("[SPLASH] Usuario ja logado: ", AccountManager.get_username())
		print("[SPLASH] Indo direto para title screen")
		get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
	else:
		print("[SPLASH] Nenhum usuario logado, indo para login")
		get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")

func go_to_login() -> void:
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
	
func hide_all_huds() -> void:
	var hud_names = ["PlayerHUD", "SpeedrunHUD", "PauseManager", "SceneManager"]
	
	for hud_name in hud_names:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud and "visible" in hud:
			hud.visible = false
			print("[SPLASH] ", hud_name, " escondido")
