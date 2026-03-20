extends Control

@onready var enabled_checkbox: CheckBox = %EnabledCheckbox
@onready var timeout_slider: HSlider = %TimeoutSlider
@onready var timeout_value: Label = %TimeoutValue
@onready var save_button: Button = %SaveButton
@onready var back_button: Button = %BackButton
@onready var autosave_checkbox: CheckBox = %AutosaveCheckbox
@onready var interval_slider: HSlider = %IntervalSlider


func _ready() -> void:
	print("[SETTINGS] Tela de configuracoes inicializada")
	
	# Conecta sinais
	enabled_checkbox.toggled.connect(_on_enabled_toggled)
	timeout_slider.value_changed.connect(_on_timeout_changed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Conecta autosave
	autosave_checkbox.toggled.connect(_on_autosave_toggled)
	interval_slider.value_changed.connect(_on_interval_changed)
	
	# Carrega configurações atuais
	load_current_settings()

func load_current_settings() -> void:
	enabled_checkbox.button_pressed = InactivityMonitor.is_enabled
	timeout_slider.value = InactivityMonitor.inactivity_timeout / 60.0  # Converte segundos para minutos
	autosave_checkbox.button_pressed = AutosaveManager.autosave_enabled
	interval_slider.value = AutosaveManager.autosave_interval / 60.0
	_update_timeout_label(timeout_slider.value)

func _on_autosave_toggled(enabled: bool) -> void:
	interval_slider.editable = enabled

func _on_interval_changed(value: float) -> void:
	# Atualiza label preview
	pass


func _on_enabled_toggled(enabled: bool) -> void:
	timeout_slider.editable = enabled

func _on_timeout_changed(value: float) -> void:
	_update_timeout_label(value)

func _update_timeout_label(minutes: float) -> void:
	timeout_value.text = "%d min" % int(minutes)

func _on_save_pressed() -> void:
	# Salva configurações
	InactivityMonitor.set_enabled(enabled_checkbox.button_pressed)
	InactivityMonitor.set_timeout(timeout_slider.value)
	
	print("[SETTINGS] Configuracoes salvas!")
	print("[SETTINGS] Inatividade habilitada: ", enabled_checkbox.button_pressed)
	print("[SETTINGS] Timeout: ", timeout_slider.value, " minutos")
	
	AutosaveManager.set_autosave_enabled(autosave_checkbox.button_pressed)
	AutosaveManager.set_autosave_interval(interval_slider.value)
	
	# Feedback visual
	save_button.text = "SAVED!"
	save_button.disabled = true
	
	await get_tree().create_timer(1.0).timeout
	
	save_button.text = "SAVE SETTINGS"
	save_button.disabled = false

func _on_back_pressed() -> void:
	queue_free()
