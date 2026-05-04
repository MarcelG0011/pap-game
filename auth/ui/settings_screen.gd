# res://ui/settings/settings_screen.gd
extends CanvasLayer

@onready var panel_container: PanelContainer = %PanelContainer
@onready var close_button: Button = %CloseButton

# Referencias aos controles
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var autosave_checkbox: CheckBox = %AutoSaveCheckBox
@onready var autosave_interval_spinbox: SpinBox = %AutosaveIntervalSpinBox
@onready var inactivity_checkbox: CheckBox = %InactivityCheckBox
@onready var inactivity_timeout_spinbox: SpinBox = %InactivityTimeoutSpinBox
@onready var back_button: Button = %BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Aplica tema visual
	_apply_theme()
	
	# Animação de entrada
	_entrance_animation()
	
	# Audio sliders
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
		music_slider.value = AudioServer.get_bus_volume_linear(2)
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
		sfx_slider.value = AudioServer.get_bus_volume_linear(3)
	
	if ui_slider:
		ui_slider.value_changed.connect(_on_ui_changed)
		ui_slider.value = AudioServer.get_bus_volume_linear(4)
	
	# Autosave
	if autosave_checkbox:
		autosave_checkbox.toggled.connect(_on_autosave_toggled)
		autosave_checkbox.button_pressed = AutosaveManager.autosave_enabled
	
	if autosave_interval_spinbox:
		autosave_interval_spinbox.value_changed.connect(_on_autosave_interval_changed)
		autosave_interval_spinbox.value = AutosaveManager.autosave_interval / 60.0
	
	# Inatividade
	if inactivity_checkbox:
		inactivity_checkbox.toggled.connect(_on_inactivity_toggled)
		if InactivityMonitor:
			inactivity_checkbox.button_pressed = InactivityMonitor.is_enabled
	
	if inactivity_timeout_spinbox:
		inactivity_timeout_spinbox.value_changed.connect(_on_inactivity_timeout_changed)
		if InactivityMonitor:
			inactivity_timeout_spinbox.value = InactivityMonitor.inactivity_timeout / 60.0
	
	# Botão voltar
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	print("[SETTINGS] Inicializado com sucesso")

func _apply_theme() -> void:
	if not panel_container:
		return
	
	# Panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.18, 0.98)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3

	panel_style.border_color = Color(0.35, 0.4, 0.5)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.shadow_size = 15
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	
	panel_container.add_theme_stylebox_override("panel", panel_style)
	
	# Estiliza sliders
	_style_sliders()
	
	# Estiliza checkboxes
	_style_checkboxes()

func _style_sliders() -> void:
	for slider in [music_slider, sfx_slider, ui_slider]:
		if slider:
			_style_single_slider(slider)

func _style_single_slider(slider: HSlider) -> void:
	# Grabber (botão deslizante)
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = Color(0.5, 0.7, 0.9)
	grabber.corner_radius_top_left = 6
	grabber.corner_radius_top_right = 6
	grabber.corner_radius_bottom_left = 6
	grabber.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_area", grabber)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber)
	
	# Barra do slider
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.2, 0.2, 0.3)
	slider_style.corner_radius_top_left = 3
	slider_style.corner_radius_top_right = 3
	slider_style.corner_radius_bottom_left = 3
	slider_style.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", slider_style)
	
	# Fill (parte preenchida)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.4, 0.6, 0.8)
	fill_style.corner_radius_all = 3
	slider.add_theme_stylebox_override("grabber_area", fill_style)

func _style_checkboxes() -> void:
	for checkbox in [autosave_checkbox, inactivity_checkbox]:
		if checkbox:
			_style_single_checkbox(checkbox)

func _style_single_checkbox(checkbox: CheckBox) -> void:
	# Box quando marcado
	var checked_style = StyleBoxFlat.new()
	checked_style.bg_color = Color(0.4, 0.6, 0.8)
	checked_style.border_width_top = 2
	checked_style.border_width_bottom = 2
	checked_style.border_width_left = 2
	checked_style.border_width_right = 2

	checked_style.border_color = Color(0.5, 0.7, 0.9)
	checked_style.corner_radius_top_left = 4
	checked_style.corner_radius_top_right = 4
	checked_style.corner_radius_bottom_left = 4
	checked_style.corner_radius_bottom_right = 4
	# Box quando desmarcado
	var unchecked_style = StyleBoxFlat.new()
	unchecked_style.bg_color = Color(0.2, 0.2, 0.3)
	unchecked_style.border_width_top = 2
	unchecked_style.border_width_bottom = 2
	unchecked_style.border_width_right = 2
	unchecked_style.border_width_left = 2
	unchecked_style.border_color = Color(0.3, 0.3, 0.4)
	unchecked_style.corner_radius_top_left = 4
	unchecked_style.corner_radius_top_right = 4
	unchecked_style.corner_radius_bottom_left = 4
	unchecked_style.corner_radius_bottom_right = 4
	pass
	
func _entrance_animation() -> void:
	if not panel_container:
		return
	
	panel_container.modulate.a = 0
	var original_y = panel_container.position.y
	panel_container.position.y = original_y - 50
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(panel_container, "modulate:a", 1.0, 0.4)
	tween.tween_property(panel_container, "position:y", original_y, 0.4)
	pass

# Audio callbacks
func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
	SaveManager.save_configuration()
	pass

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)
	SaveManager.save_configuration()
	pass

func _on_ui_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(4, value)
	SaveManager.save_configuration()
	pass

# Autosave callbacks
func _on_autosave_toggled(enabled: bool) -> void:
	if AutosaveManager:
		AutosaveManager.set_autosave_enabled(enabled)
	pass

func _on_autosave_interval_changed(minutes: float) -> void:
	if AutosaveManager:
		AutosaveManager.set_autosave_interval(minutes)
	pass

# Inactivity callbacks
func _on_inactivity_toggled(enabled: bool) -> void:
	if InactivityMonitor:
		InactivityMonitor.set_enabled(enabled)
	pass

func _on_inactivity_timeout_changed(minutes: float) -> void:
	if InactivityMonitor:
		InactivityMonitor.set_timeout(minutes)
	pass

func _on_back_pressed() -> void:
	print("[SETTINGS] A fechar...")
	queue_free()
	pass
