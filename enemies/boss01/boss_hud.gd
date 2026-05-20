extends CanvasLayer

var boss_bar: TextureProgressBar
var boss_label: Label

func _ready() -> void:
	# Cria a barra de vida
	boss_bar = TextureProgressBar.new()
	boss_bar.name = "BossBar"
	boss_bar.size = Vector2(200, 20)
	boss_bar.position = Vector2(140, 10)  # Ajusta conforme a viewport (480x270)
	boss_bar.max_value = 100
	boss_bar.value = 100
	add_child(boss_bar)

	# Cria o label do nome do boss
	boss_label = Label.new()
	boss_label.name = "BossLabel"
	boss_label.position = Vector2(140, 35)
	boss_label.add_theme_font_size_override("font_size", 14)
	add_child(boss_label)

	# Começa invisível
	visible = false

func show_boss(boss_name: String, max_hp: float) -> void:
	boss_label.text = boss_name
	boss_bar.max_value = max_hp
	boss_bar.value = max_hp
	visible = true

func update_hp(hp: float) -> void:
	boss_bar.value = hp

func hide_boss() -> void:
	visible = false
