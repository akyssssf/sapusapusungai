extends CanvasLayer
## HUD Map 3. Berdiri sendiri, tidak memakai hud.tscn milik Map 1/2.
##
## Alasannya sederhana: dari seluruh isi HUD lama -- skor, ukuran ikan, bar
## pertumbuhan, nyawa, jeda dash, bar nyawa bos, penanda bahaya melintas --
## tidak ada satu pun yang berlaku di Map 3. Memakainya berarti membawa tujuh
## elemen mati ke layar yang cuma butuh dua.
##
## Yang dibutuhkan Map 3 cuma tiga pertanyaan yang harus selalu terjawab:
##   "seberapa lancar airnya sekarang?"  -> bar aliran
##   "ikan mana yang sedang saya pegang?" -> label ikan aktif
##   "sudah dapat berapa?"                -> skor
##
## Skornya dibaca lewat sinyal, sama seperti HUD Map 1/2: nilainya cuma berubah
## tiga kali sepanjang bab, jadi memeriksanya 60 kali per detik sia-sia.

@onready var _score_label: Label = %ScoreLabel
@onready var _flow_bar: ProgressBar = %FlowBar
@onready var _flow_label: Label = %FlowLabel
@onready var _active_label: Label = %ActiveLabel
@onready var _banner: Label = %Banner
@onready var _overlay: Control = %Overlay
@onready var _overlay_title: Label = %OverlayTitle
@onready var _overlay_hint: Label = %OverlayHint

var _banner_left: float = 0.0


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	_on_score_changed(GameState.score)
	_banner.modulate.a = 0.0
	_overlay.visible = false
	_flow_bar.max_value = 1.0
	_flow_bar.value = 0.0


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Skor: %d" % new_score


func _process(delta: float) -> void:
	if _banner_left <= 0.0:
		return
	_banner_left -= delta
	# Sepertiga waktu terakhir dipakai memudar, sisanya tampil penuh.
	_banner.modulate.a = clampf(_banner_left * 3.0, 0.0, 1.0)


## Angka bulat: dipakai saat satu sumbatan benar-benar terbuka.
func set_progress(cleared: int, total: int) -> void:
	_flow_label.text = "Aliran sungai   %d / %d sumbatan" % [cleared, maxi(total, 1)]
	set_progress_fine(float(cleared), total)


## Angka pecahan: dipakai tiap frame supaya bar ikut naik SELAMA dua ikan
## menahan posisi, bukan melompat setelah selesai. Usaha yang sedang berjalan
## harus kelihatan, kalau tidak pemain tidak tahu dia sedang berhasil.
func set_progress_fine(progress: float, total: int) -> void:
	_flow_bar.value = clampf(progress / float(maxi(total, 1)), 0.0, 1.0)


func set_active_fish(fish_name: String, colour: Color) -> void:
	_active_label.text = "Mengendalikan: %s     [Tab] ganti" % fish_name
	_active_label.add_theme_color_override("font_color", colour)


func show_banner(text: String, duration: float) -> void:
	_banner.text = text
	_banner_left = duration
	_banner.modulate.a = 1.0


func show_result(title: String, hint: String) -> void:
	_overlay_title.text = title
	_overlay_hint.text = hint
	_overlay.visible = true
	_overlay.modulate.a = 0.0
	create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.45)
