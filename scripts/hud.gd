extends CanvasLayer
## Semua angka dan tulisan di layar.
##
## HUD tidak pernah mencari pemain sendiri lewat get_node("../PlayerFish").
## Kalau begitu, HUD rusak setiap kali struktur map digeser. Yang menyuapkan
## referensi pemain adalah map_manager lewat bind_player().
##
## Pembagian cara membaca datanya disengaja:
##   - Skor & nyawa & pelat bos -> lewat SINYAL. Jarang berubah, sayang kalau
##     diperiksa 60 kali per detik.
##   - Bar pertumbuhan          -> lewat _process(). Nilainya pecahan dan
##     berubah terus, jadi memang cocok dibaca tiap frame.

@onready var _score_label: Label = %ScoreLabel
@onready var _size_label: Label = %SizeLabel
@onready var _growth_bar: ProgressBar = %GrowthBar
@onready var _hearts: Node2D = %Hearts
@onready var _dash_bar: ProgressBar = %DashBar
@onready var _dash_label: Label = %DashLabel
@onready var _warnings: Node2D = %Warnings
@onready var _banner: Label = %Banner
@onready var _boss_panel: Control = %BossPanel
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _overlay: Control = %Overlay
@onready var _overlay_title: Label = %OverlayTitle
@onready var _overlay_hint: Label = %OverlayHint

var _player: Node = null
var _banner_left: float = 0.0
## Peringatan yang sedang tampil. Tiap isinya {node, side, y, left}.
var _active_warnings: Array = []
var _blink_time: float = 0.0

## Warna hati saat masih ada dan saat sudah habis.
const HEART_FULL := Color(0.93, 0.29, 0.35)
const HEART_EMPTY := Color(0.18, 0.24, 0.25)

## Dash siap vs sedang mengisi. Bedanya sengaja mencolok: saat bertarung dengan
## bos, pemain tidak sempat membaca angka -- yang terbaca cuma "terang / redup".
const DASH_READY := Color(1, 1, 1, 1)
const DASH_CHARGING := Color(1, 1, 1, 0.42)


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	_on_score_changed(GameState.score)

	_banner.modulate.a = 0.0
	for marker in _warnings.get_children():
		marker.visible = false
	_boss_panel.visible = false
	_overlay.visible = false
	set_process(false)


func bind_player(player: Node) -> void:
	_player = player
	_on_size_level_changed(player.size_level)
	_on_health_changed(player.health, player.max_health)
	player.size_level_changed.connect(_on_size_level_changed)
	player.health_changed.connect(_on_health_changed)
	set_process(true)


func _process(delta: float) -> void:
	_growth_bar.value = _player.growth_ratio()

	var dash: float = _player.dash_ratio()
	_dash_bar.value = dash
	var ready_now: bool = dash >= 1.0
	_dash_bar.modulate = DASH_READY if ready_now else DASH_CHARGING
	_dash_label.modulate = DASH_READY if ready_now else DASH_CHARGING

	if _banner_left > 0.0:
		_banner_left -= delta
		# Sepertiga waktu terakhir dipakai memudar, sisanya tampil penuh.
		_banner.modulate.a = clampf(_banner_left * 3.0, 0.0, 1.0)

	_update_warnings(delta)


# --- Peringatan bahaya melintas ---------------------------------------------

## Dipanggil lewat sinyal rush_warned dari TrashDirector.
## side: +1 bahaya datang dari tepi kanan, -1 dari tepi kiri.
func show_hazard_warning(side: int, world_y: float, lead_time: float) -> void:
	var marker := _free_warning_marker()
	if marker == null:
		return
	marker.visible = true
	_active_warnings.append({"node": marker, "side": side, "y": world_y, "left": lead_time})
	AudioManager.play("warning", 1.0, 1.0, 0.0)


func _free_warning_marker() -> Node2D:
	for marker in _warnings.get_children():
		if not marker.visible:
			return marker
	# Semua penanda sedang terpakai. Lebih baik satu peringatan tidak tampil
	# daripada menumpuk node baru tiap kali -- tiga jalur sekaligus sudah lebih
	# dari cukup untuk dibaca mata.
	return null


## Penanda hidup di CanvasLayer (ruang layar), sedangkan bahayanya ada di ruang
## dunia. Jadi tiap frame posisi Y dunia diterjemahkan ke Y layar lewat
## canvas_transform. Kalau penandanya ditaruh di dunia, dia akan ikut hanyut
## keluar pandangan justru saat pemain paling butuh melihatnya.
func _update_warnings(delta: float) -> void:
	if _active_warnings.is_empty():
		return

	_blink_time += delta
	var canvas := get_viewport().get_canvas_transform()
	var view := get_viewport().get_visible_rect().size
	var blink := 0.45 + 0.55 * absf(sin(_blink_time * 9.0))

	for i in range(_active_warnings.size() - 1, -1, -1):
		var w: Dictionary = _active_warnings[i]
		w["left"] -= delta
		var marker: Node2D = w["node"]

		if w["left"] <= 0.0:
			marker.visible = false
			_active_warnings.remove_at(i)
			continue

		var screen_y: float = (canvas * Vector2(0.0, float(w["y"]))).y
		marker.position.y = clampf(screen_y, 34.0, view.y - 34.0)
		marker.modulate.a = blink

		var side: int = int(w["side"])
		var arrow: Node2D = marker.get_node("Arrow")
		arrow.position.x = view.x - 46.0 if side > 0 else 46.0
		arrow.scale.x = -1.0 if side > 0 else 1.0
		marker.get_node("Lane").points = PackedVector2Array([Vector2.ZERO, Vector2(view.x, 0.0)])


# --- Angka dasar ------------------------------------------------------------

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Skor: %d" % new_score


func _on_size_level_changed(new_level: int) -> void:
	_size_label.text = "Ukuran: %d" % new_level


func _on_health_changed(current: int, _maximum: int) -> void:
	# Hati yang sudah habis tidak disembunyikan, cuma diredupkan. Dengan begitu
	# pemain tetap melihat berapa banyak yang HILANG, bukan cuma yang tersisa.
	for i in _hearts.get_child_count():
		var heart: Node2D = _hearts.get_child(i)
		var alive := i < current
		heart.modulate = HEART_FULL if alive else HEART_EMPTY
		heart.scale = Vector2.ONE * (1.0 if alive else 0.82)


# --- Pengumuman & hasil -----------------------------------------------------

func show_banner(text: String, duration: float) -> void:
	_banner.text = text
	_banner_left = duration
	_banner.modulate.a = 1.0


func show_boss_bar(current: int, maximum: int) -> void:
	_boss_panel.visible = true
	_boss_bar.max_value = maximum
	_boss_bar.value = current


func hide_boss_bar() -> void:
	_boss_panel.visible = false


func show_result(title: String, hint: String) -> void:
	_overlay_title.text = title
	_overlay_hint.text = hint
	_overlay.visible = true
	_overlay.modulate.a = 0.0
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.45)
