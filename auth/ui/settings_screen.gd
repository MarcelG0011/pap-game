# res://ui/settings/settings_screen.gd
extends CanvasLayer

# Referencias aos controles
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var autosave_checkbox: CheckBox = %AutosaveCheckbox
@onready var autosave_interval_spinbox: SpinBox = %AutosaveIntervalSpinbox
@onready var inactivity_checkbox: CheckBox = %InactivityCheckbox
@onready var inactivity_timeout_spinbox: SpinBox = %InactivityTimeoutSpinbox
@onready var back_button: Button = %BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conecta sliders de áudio (SEMPRE existem)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
		music_slider.value = AudioServer.get_bus_volume_db(2)
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
		sfx_slider.value = AudioServer.get_bus_volume_db(3)
	
	if ui_slider:
		ui_slider.value_changed.connect(_on_ui_changed)
		ui_slider.value = AudioServer.get_bus_volume_db(4)
	
	# Conecta autosave (SE EXISTIR)
	if autosave_checkbox:
		autosave_checkbox.toggled.connect(_on_autosave_toggled)
		autosave_checkbox.button_pressed = AutosaveManager.autosave_enabled
	else:
		push_warning("[SETTINGS] AutosaveCheckbox não encontrado")
	
	if autosave_interval_spinbox:
		autosave_interval_spinbox.value_changed.connect(_on_autosave_interval_changed)
		autosave_interval_spinbox.value = AutosaveManager.autosave_interval / 60.0
	
	# Conecta inactividade (SE EXISTIR)
	if inactivity_checkbox:
		inactivity_checkbox.toggled.connect(_on_inactivity_toggled)
		if InactivityMonitor:
			inactivity_checkbox.button_pressed = InactivityMonitor.inactivity_enabled
	
	if inactivity_timeout_spinbox:
		inactivity_timeout_spinbox.value_changed.connect(_on_inactivity_timeout_changed)
		if InactivityMonitor:
			inactivity_timeout_spinbox.value = InactivityMonitor.inactivity_timeout / 60.0
	
	# Botão voltar
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
		InactivityMonitor.set_inactivity_enabled(enabled)

func _on_inactivity_timeout_changed(minutes: float) -> void:
	if InactivityMonitor:
		InactivityMonitor.set_inactivity_timeout(minutes)

func _on_back_pressed() -> void:
	queue_free()
