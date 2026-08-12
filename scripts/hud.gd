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

const TrashScript := preload("res://scripts/trash.gd")

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

## Satu contoh gambar per tingkat sampah, untuk penunjuk "sudah bisa dimakan".
## Sengaja gambar yang sama dengan yang hanyut di sungai -- penunjuk yang
## memakai ikon lain memaksa pemain menerjemahkan dua bahasa sekaligus.
const CONTOH_SAMPAH := [
	preload("res://assets/environment/plastic_bottle.png"),
	preload("res://assets/environment/kresek_bag.png"),
	preload("res://assets/environment/trash_pile.png"),
]

## Petak penunjuk, satu per tingkat sampah.
var _petak_makan: Array[TextureRect] = []
var _bingkai_makan: Array[Panel] = []
var _label_makan: Label = null

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
	_bangun_penunjuk_makan()
	set_process(false)


## Penunjuk "sekarang kamu bisa makan yang mana", ala Feeding Frenzy.
##
## Feeding Frenzy tidak pernah menggambar cincin di sekeliling ikan yang belum
## bisa dimakan. Yang dipakainya cuma dua hal: ukuran benda di layar, dan satu
## penunjuk kecil di tepi layar yang memperlihatkan sampai mana mulutmu sampai.
## Itu jauh lebih baik daripada lencana per benda, karena pemain belajar
## MEMBANDINGKAN UKURAN -- kemampuan yang terus berguna sepanjang permainan --
## alih-alih belajar mencari cincin.
##
## Ukuran tiap petak di sini mengikuti radius aslinya, jadi penunjuk ini
## sekaligus mengajarkan seberapa besar tiap tingkat sampah sebenarnya.
func _bangun_penunjuk_makan() -> void:
	if get_node_or_null("PenunjukMakan") != null:
		return

	var wadah := Control.new()
	wadah.name = "PenunjukMakan"
	wadah.position = Vector2(26.0, 198.0)
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wadah)

	_label_makan = Label.new()
	_label_makan.text = "MUAT DI MULUTMU"
	_label_makan.add_theme_font_size_override("font_size", 14)
	_label_makan.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_label_makan.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.07, 0.9))
	_label_makan.add_theme_constant_override("outline_size", 6)
	wadah.add_child(_label_makan)

	var kiri := 0.0
	for i in CONTOH_SAMPAH.size():
		# Petaknya menaik ukurannya mengikuti radius sampah aslinya, jadi
		# penunjuk ini sekaligus mengajarkan seberapa besar tiap tingkat.
		var sisi: float = 30.0 + float(TrashScript.TIER_DATA[i]["radius"]) * 0.95

		# Bingkai gelap di belakang tiap petak. Tanpa ini gambarnya hilang
		# ditelan latar sungai yang juga gelap -- percobaan pertama penunjuk ini
		# gagal justru karena itu, bukan karena ukurannya.
		var bingkai := Panel.new()
		bingkai.size = Vector2(sisi, sisi)
		bingkai.position = Vector2(kiri, 24.0 + (76.0 - sisi))
		bingkai.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wadah.add_child(bingkai)
		_bingkai_makan.append(bingkai)

		var gambar := TextureRect.new()
		gambar.texture = CONTOH_SAMPAH[i]
		gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gambar.size = Vector2(sisi - 12.0, sisi - 12.0)
		gambar.position = Vector2(6.0, 6.0)
		gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bingkai.add_child(gambar)
		_petak_makan.append(gambar)

		kiri += sisi + 8.0

	_segarkan_penunjuk_makan(1)


func _segarkan_penunjuk_makan(level: int) -> void:
	for i in _petak_makan.size():
		var bisa: bool = level >= int(TrashScript.TIER_DATA[i]["butuh_level"])

		# Yang belum bisa dimakan tidak disembunyikan, cuma diredupkan. Pemain
		# harus tetap melihat bahwa masih ADA yang lebih besar -- itu yang
		# membuat naik ukuran terasa punya tujuan.
		_petak_makan[i].modulate = Color(1, 1, 1, 1) if bisa else Color(0.5, 0.55, 0.6, 0.4)

		# Warna bingkai yang membawa jawabannya, bukan kepekatan gambarnya.
		# Meredupkan saja tidak cukup: gambar sampah memang sudah gelap, jadi
		# "redup" dan "terang" nyaris tidak terbedakan di atas air yang gelap.
		var kotak := StyleBoxFlat.new()
		kotak.set_corner_radius_all(8)
		kotak.set_border_width_all(3)
		if bisa:
			kotak.bg_color = Color(0.11, 0.24, 0.18, 0.85)
			kotak.border_color = Color(0.45, 0.92, 0.62, 0.95)
		else:
			kotak.bg_color = Color(0.06, 0.08, 0.1, 0.72)
			kotak.border_color = Color(1, 1, 1, 0.14)
		_bingkai_makan[i].add_theme_stylebox_override("panel", kotak)


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
	_segarkan_penunjuk_makan(new_level)


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
