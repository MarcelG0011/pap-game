# res://ui/settings/settings_screen.gd
extends CanvasLayer

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
	
	# --- AUDIO (Correção de volume para linear se usares sliders de 0 a 1) ---
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
		music_slider.value = AudioServer.get_bus_volume_linear(2)
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
		sfx_slider.value = AudioServer.get_bus_volume_linear(3)
	
	if ui_slider:
		ui_slider.value_changed.connect(_on_ui_changed)
		ui_slider.value = AudioServer.get_bus_volume_linear(4)
	
	# --- AUTOSAVE ---
	if autosave_checkbox:
		autosave_checkbox.toggled.connect(_on_autosave_toggled)
		# Verifica se a variável existe no AutosaveManager
		autosave_checkbox.button_pressed = AutosaveManager.autosave_enabled
	
	if autosave_interval_spinbox:
		autosave_interval_spinbox.value_changed.connect(_on_autosave_interval_changed)
		autosave_interval_spinbox.value = AutosaveManager.autosave_interval / 60.0
	
	# --- INATIVIDADE (Aqui estavam os erros) ---
	if inactivity_checkbox:
		inactivity_checkbox.toggled.connect(_on_inactivity_toggled)
		if InactivityMonitor:
			# MUDANÇA: inactivity_enabled -> is_enabled
			inactivity_checkbox.button_pressed = InactivityMonitor.is_enabled
	
	if inactivity_timeout_spinbox:
		inactivity_timeout_spinbox.value_changed.connect(_on_inactivity_timeout_changed)
		if InactivityMonitor:
			# MUDANÇA: inactivity_timeout -> inactivity_timeout
			inactivity_timeout_spinbox.value = InactivityMonitor.inactivity_timeout / 60.0
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	print("[SETTINGS] Inicializado com sucesso")

# Audio callbacks
func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)
	SaveManager.save_configuration()

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(3, value)
	SaveManager.save_configuration()

func _on_ui_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(4, value)
	SaveManager.save_configuration()

# Autosave callbacks
func _on_autosave_toggled(enabled: bool) -> void:
	if AutosaveManager:
		AutosaveManager.set_autosave_enabled(enabled)

func _on_autosave_interval_changed(minutes: float) -> void:
	if AutosaveManager:
		AutosaveManager.set_autosave_interval(minutes)

# Inactivity callbacks
func _on_inactivity_toggled(enabled: bool) -> void:
	if InactivityMonitor:
		# MUDANÇA: set_inactivity_enabled -> set_enabled
		InactivityMonitor.set_enabled(enabled)

func _on_inactivity_timeout_changed(minutes: float) -> void:
	if InactivityMonitor:
		# MUDANÇA: set_inactivity_timeout -> set_timeout
		InactivityMonitor.set_timeout(minutes)

func _on_back_pressed() -> void:
	print("[SETTINGS] A fechar...")
	# Isto remove o nó da árvore e permite que o TitleScreen o abra novamente depois
	queue_free()
