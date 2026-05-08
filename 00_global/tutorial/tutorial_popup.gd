# res://ui/tutorial/tutorial_popup.gd
# ==============================================================
#  SOULBOUND: ECHOES OF ETERNITY — Tutorial Popup
#  Fonte: Alagard  (res://assets/fonts/Alagard.ttf)
#  DB:    SQLite via DatabaseManager
# ==============================================================
extends CanvasLayer

signal popup_closed

# ── Nós ──────────────────────────────────────────────────────
@onready var dark_overlay:        ColorRect         = $DarkOverlay
@onready var popup_panel:         PanelContainer    = $DarkOverlay/CenterContainer/PopupPanel
@onready var step_badge:          Label             = %StepBadge
@onready var step_dots_container: HBoxContainer     = %StepDots
@onready var media_container:     Control           = %MediaContainer
@onready var media_background:    ColorRect         = %MediaBackground
@onready var glow_circle:         ColorRect         = %GlowCircle
@onready var tutorial_image:      TextureRect       = %TutorialImage
@onready var tutorial_video:      VideoStreamPlayer = %TutorialVideo
@onready var media_icon_label:    Label             = %MediaIconLabel
@onready var particles:           CPUParticles2D    = %Particles
@onready var title_label:         Label             = %TitleLabel
@onready var divider_line:        HSeparator        = %DividerLine
@onready var description_label:   RichTextLabel     = %DescriptionLabel
@onready var tip_box:             PanelContainer    = %TipBox
@onready var tip_label:           RichTextLabel     = %TipLabel
@onready var progress_label:      Label             = %ProgressLabel
@onready var got_it_button:       Button            = %GotItButton
@onready var skip_button:         Button            = %SkipButton
@onready var corner_tl:           ColorRect         = %CornerTL
@onready var corner_tr:           ColorRect         = %CornerTR
@onready var corner_bl:           ColorRect         = %CornerBL
@onready var corner_br:           ColorRect         = %CornerBR

# ── Fonte ─────────────────────────────────────────────────────
const FONT_PATH := "res://general/fonts/alagard.ttf"
var _font: FontFile = null

# ── Paleta dark-fantasy ───────────────────────────────────────
const C_BG_PANEL    := Color(0.059, 0.063, 0.094, 0.99)
const C_BG_MEDIA    := Color(0.031, 0.035, 0.063, 1.0)
const C_BG_TIP      := Color(0.157, 0.235, 0.471, 0.12)
const C_BORDER_MAIN := Color(0.392, 0.549, 0.863, 0.38)
const C_BORDER_TIP  := Color(0.392, 0.549, 0.863, 0.55)
const C_TEXT_TITLE  := Color(0.784, 0.847, 0.973)
const C_TEXT_BODY   := Color(0.706, 0.765, 0.882, 0.88)
const C_TEXT_BADGE  := Color(0.471, 0.588, 0.824, 0.85)
const C_TEXT_PROG   := Color(0.400, 0.510, 0.706, 0.80)
const C_BTN_PRI     := Color(0.196, 0.314, 0.627, 0.60)
const C_BTN_PRI_BDR := Color(0.392, 0.549, 0.863, 0.55)
const C_BTN_PRI_HOV := Color(0.235, 0.373, 0.706, 0.75)
const C_BTN_SKP_BDR := Color(0.314, 0.392, 0.549, 0.35)
const C_DOT_ACTIVE  := Color(0.392, 0.588, 0.902, 0.95)
const C_DOT_INACTIVE:= Color(0.314, 0.431, 0.706, 0.28)
const C_GLOW        := Color(0.157, 0.235, 0.549, 0.28)
const C_DIVIDER     := Color(0.314, 0.471, 0.784, 0.25)

# ── Estado ────────────────────────────────────────────────────
var tutorial_id:  String = ""
var current_step: int    = 0
var total_steps:  int    = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_load_font()
	_apply_theme()
	_setup_particles()
	_wire_buttons()
	_entrance_animation()


# ── Fonte ─────────────────────────────────────────────────────
func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	else:
		push_warning("[TUTORIAL] Fonte não encontrada: %s" % FONT_PATH)


func _set_font(node: Control, size: int) -> void:
	if not node: return
	if _font: node.add_theme_font_override("font", _font)
	node.add_theme_font_size_override("font_size", size)


func _set_font_rich(node: RichTextLabel, size: int) -> void:
	if not node: return
	if _font:
		node.add_theme_font_override("normal_font", _font)
		node.add_theme_font_override("bold_font",   _font)
	node.add_theme_font_size_override("normal_font_size", size)


# ── Setup público ─────────────────────────────────────────────
func setup(
	p_id:    String,
	p_title: String,
	p_desc:  String,
	p_tip:   String = "",
	p_media: String = "",
	p_step:  int    = 1,
	p_total: int    = 1,
	p_badge: String = ""
) -> void:
	tutorial_id  = p_id
	current_step = p_step
	total_steps  = p_total

	if title_label:
		title_label.text = p_title.to_upper()

	if description_label:
		description_label.text = p_desc

	if tip_box:
		tip_box.visible = not p_tip.is_empty()
	if tip_label and not p_tip.is_empty():
		tip_label.text = p_tip

	if step_badge:
		step_badge.text = p_badge if not p_badge.is_empty() \
			else "CHAPTER %d" % p_step

	if got_it_button:
		got_it_button.text = "CLOSE THE TOME" if p_step == p_total \
			else "UNDERSTOOD"

	_update_progress()
	_update_dots()
	_load_media(p_media)


# ── Media ─────────────────────────────────────────────────────
func _load_media(path: String) -> void:
	if path.is_empty():
		_show_default_icon(); return
	if not ResourceLoader.exists(path):
		push_warning("[TUTORIAL] Media não encontrada: %s" % path)
		_show_default_icon(); return

	match path.get_extension().to_lower():
		"ogv", "webm": _load_video(path)
		"png", "jpg", "jpeg", "webp": _load_image(path)
		_: _show_default_icon()


func _load_image(path: String) -> void:
	if tutorial_image:    tutorial_image.texture = load(path); tutorial_image.visible = true
	if tutorial_video:    tutorial_video.visible = false; tutorial_video.stop()
	if media_icon_label:  media_icon_label.visible = false


func _load_video(path: String) -> void:
	if tutorial_video:
		tutorial_video.stream = load(path)
		tutorial_video.visible = true
		tutorial_video.play()
	if tutorial_image:   tutorial_image.visible = false
	if media_icon_label: media_icon_label.visible = false


func _show_default_icon() -> void:
	if tutorial_image:   tutorial_image.visible = false
	if tutorial_video:   tutorial_video.visible = false; tutorial_video.stop()
	if media_icon_label: media_icon_label.visible = true


# ── UI helpers ────────────────────────────────────────────────
func _update_progress() -> void:
	if not progress_label: return
	progress_label.visible = total_steps > 1
	if total_steps > 1:
		progress_label.text = "%d  /  %d" % [current_step, total_steps]


func _update_dots() -> void:
	if not step_dots_container: return
	step_dots_container.visible = total_steps > 1
	for i in step_dots_container.get_child_count():
		var dot := step_dots_container.get_child(i) as ColorRect
		if not dot: continue
		dot.visible = i < total_steps
		dot.color   = C_DOT_ACTIVE if i == (current_step - 1) else C_DOT_INACTIVE


# ── Tema ──────────────────────────────────────────────────────
func _apply_theme() -> void:
	# Overlay escuro
	if dark_overlay:
		dark_overlay.color = Color(0.02, 0.02, 0.05, 0.82)

	# Painel
	if popup_panel:
		var s := StyleBoxFlat.new()
		s.bg_color = C_BG_PANEL
		s.border_width_all = 1; s.border_color = C_BORDER_MAIN
		s.corner_radius_all = 4
		s.shadow_size = 40; s.shadow_color = Color(0, 0, 0, 0.92)
		s.shadow_offset = Vector2(0, 12)
		popup_panel.add_theme_stylebox_override("panel", s)
		popup_panel.custom_minimum_size = Vector2(520, 0)

	# Badge
	if step_badge:
		_set_font(step_badge, 11)
		step_badge.add_theme_color_override("font_color", C_TEXT_BADGE)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.235, 0.314, 0.588, 0.15)
		bs.border_width_all = 1; bs.border_color = Color(0.314, 0.431, 0.706, 0.32)
		bs.corner_radius_all = 2
		bs.content_margin_left = bs.content_margin_right  = 10.0
		bs.content_margin_top  = bs.content_margin_bottom = 3.0
		step_badge.add_theme_stylebox_override("normal", bs)

	# Media
	if media_background: media_background.color = C_BG_MEDIA
	if glow_circle:      glow_circle.color = C_GLOW
	if media_icon_label:
		_set_font(media_icon_label, 48)
		media_icon_label.add_theme_color_override("font_color", Color(0.392, 0.588, 0.902, 0.65))
		media_icon_label.text = "✦"

	# Título
	if title_label:
		_set_font(title_label, 22)
		title_label.add_theme_color_override("font_color", C_TEXT_TITLE)

	# Divisor
	if divider_line:
		var ds := StyleBoxFlat.new()
		ds.bg_color = C_DIVIDER
		divider_line.add_theme_stylebox_override("separator", ds)

	# Descrição
	if description_label:
		_set_font_rich(description_label, 15)
		description_label.add_theme_color_override("default_color", C_TEXT_BODY)
		description_label.bbcode_enabled = true
		description_label.fit_content    = true
		description_label.scroll_active  = false

	# Progresso
	if progress_label:
		_set_font(progress_label, 12)
		progress_label.add_theme_color_override("font_color", C_TEXT_PROG)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# TipBox
	if tip_box:
		var ts := StyleBoxFlat.new()
		ts.bg_color = C_BG_TIP
		ts.border_width_left = 3; ts.border_color = C_BORDER_TIP
		ts.corner_radius_top_right    = 3
		ts.corner_radius_bottom_right = 3
		ts.content_margin_left = 14.0; ts.content_margin_right  = 14.0
		ts.content_margin_top  = 10.0; ts.content_margin_bottom = 10.0
		tip_box.add_theme_stylebox_override("panel", ts)

	if tip_label:
		_set_font_rich(tip_label, 13)
		tip_label.add_theme_color_override("default_color", Color(0.627, 0.706, 0.863, 0.85))
		tip_label.bbcode_enabled = true
		tip_label.fit_content    = true
		tip_label.scroll_active  = false

	# Botões
	_style_btn_primary(got_it_button)
	_style_btn_skip(skip_button)

	# Cantos
	_draw_corners()


func _make_sb(bg: Color, border: Color, ph: float = 20.0, pv: float = 11.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_width_all = 1; s.border_color = border
	s.corner_radius_all = 3
	s.content_margin_left = s.content_margin_right  = ph
	s.content_margin_top  = s.content_margin_bottom = pv
	return s


func _style_btn_primary(btn: Button) -> void:
	if not btn: return
	btn.add_theme_stylebox_override("normal",  _make_sb(C_BTN_PRI,                        C_BTN_PRI_BDR))
	btn.add_theme_stylebox_override("hover",   _make_sb(C_BTN_PRI_HOV,                    Color(0.471, 0.627, 0.941, 0.7)))
	btn.add_theme_stylebox_override("pressed", _make_sb(Color(0.157, 0.247, 0.510, 0.55), C_BTN_PRI_BDR))
	btn.add_theme_stylebox_override("focus",   _make_sb(C_BTN_PRI,                        C_BTN_PRI_BDR))
	_set_font(btn, 14)
	btn.add_theme_color_override("font_color",       Color(0.784, 0.847, 0.973))
	btn.add_theme_color_override("font_hover_color", Color(0.867, 0.922, 1.0))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _style_btn_skip(btn: Button) -> void:
	if not btn: return
	var t := Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal",  _make_sb(t, C_BTN_SKP_BDR, 16.0))
	btn.add_theme_stylebox_override("hover",   _make_sb(Color(0.235, 0.314, 0.471, 0.12), Color(0.392, 0.471, 0.667, 0.5), 16.0))
	btn.add_theme_stylebox_override("pressed", _make_sb(Color(0.157, 0.235, 0.392, 0.10), C_BTN_SKP_BDR, 16.0))
	btn.add_theme_stylebox_override("focus",   _make_sb(t, C_BTN_SKP_BDR, 16.0))
	_set_font(btn, 12)
	btn.add_theme_color_override("font_color",       Color(0.510, 0.588, 0.745, 0.75))
	btn.add_theme_color_override("font_hover_color", Color(0.627, 0.706, 0.863, 0.95))


func _draw_corners() -> void:
	var corners := [corner_tl, corner_tr, corner_bl, corner_br]
	for c in corners:
		if not c: continue
		c.color = C_BORDER_MAIN
		c.custom_minimum_size = Vector2(20, 20)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ── Partículas ────────────────────────────────────────────────
func _setup_particles() -> void:
	if not particles: return
	particles.emitting              = true
	particles.amount                = 20
	particles.lifetime              = 4.2
	particles.one_shot              = false
	particles.direction             = Vector2(0, -1)
	particles.spread                = 40.0
	particles.gravity               = Vector2(0, -15)
	particles.initial_velocity_min  = 8.0
	particles.initial_velocity_max  = 25.0
	particles.scale_amount_min      = 1.0
	particles.scale_amount_max      = 2.5
	particles.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(220, 2)
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.392, 0.627, 1.0, 0.0))
	grad.add_point(0.2, Color(0.392, 0.627, 1.0, 0.75))
	grad.add_point(0.8, Color(0.471, 0.706, 1.0, 0.55))
	grad.add_point(1.0, Color(0.392, 0.627, 1.0, 0.0))
	particles.color_ramp = grad


# ── Animações ─────────────────────────────────────────────────
func _entrance_animation() -> void:
	if not popup_panel: return
	popup_panel.modulate.a   = 0.0
	popup_panel.scale        = Vector2(0.88, 0.88)
	popup_panel.pivot_offset = popup_panel.size / 2.0
	if dark_overlay: dark_overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(popup_panel, "modulate:a", 1.0,        0.40)
	tw.tween_property(popup_panel, "scale",      Vector2.ONE, 0.40)
	if dark_overlay:
		tw.tween_property(dark_overlay, "modulate:a", 1.0, 0.30)


func _exit_animation() -> void:
	if not popup_panel: return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(popup_panel, "modulate:a", 0.0,               0.25)
	tw.tween_property(popup_panel, "scale",      Vector2(0.95, 0.95), 0.25)
	if dark_overlay:
		tw.tween_property(dark_overlay, "modulate:a", 0.0, 0.25)
	await tw.finished


# ── Botões ────────────────────────────────────────────────────
func _wire_buttons() -> void:
	if got_it_button:
		got_it_button.pressed.connect(_on_got_it_pressed)
		got_it_button.grab_focus()
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)


func _on_got_it_pressed() -> void:
	await _exit_animation()
	_close()


func _on_skip_pressed() -> void:
	TutorialManager.skip_all_current_tutorials()
	await _exit_animation()
	_close()


func _close() -> void:
	if tutorial_video and tutorial_video.is_playing():
		tutorial_video.stop()
	get_tree().paused = false
	popup_closed.emit()
	queue_free()


# ── Input ─────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("ui_cancel"):
			_on_skip_pressed()
		else:
			get_viewport().set_input_as_handled()
