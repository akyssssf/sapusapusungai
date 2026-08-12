extends Control
## Papan instruksi satu bab: tujuan, kontrol, bahaya, dan cara melawannya.
##
## SATU scene dipakai untuk dua keperluan yang kelihatannya berbeda:
##
##   MANDIRI  -- layar penuh sebelum bab dimulai, bagian dari rantai
##               "cerita -> papan instruksi -> peta".
##   TEMPELAN -- dipasang di dalam menu jeda saat pemain lupa aturannya
##               di tengah permainan.
##
## Digabung karena isinya persis sama, dan aturan main yang ditulis di dua
## tempat akan berbeda cepat atau lambat -- biasanya justru setelah aturannya
## diubah dan cuma satu yang ikut diperbarui.
##
## Yang membedakan cuma apa yang terjadi saat ditutup, dan itu satu percabangan
## di satu fungsi.

signal ditutup

## Diisi menu jeda SEBELUM node ini dimasukkan ke pohon.
var mandiri: bool = true
var bab: int = 0

var _sudah_ditutup: bool = false

@onready var _judul: Label = %Judul
@onready var _tujuan: Label = %Tujuan
@onready var _kolom_kontrol: VBoxContainer = %KolomKontrol
@onready var _kolom_bahaya: VBoxContainer = %KolomBahaya
@onready var _kolom_cara: VBoxContainer = %KolomCara
@onready var _tombol: Button = %TombolLanjut

const WARNA_BAHAYA := Color(1.0, 0.62, 0.55)
const WARNA_CARA := Color(0.62, 0.93, 0.75)


func _ready() -> void:
	if mandiri and bab <= 0:
		bab = SceneRouter.briefing_chapter

	var data := Story.briefing_untuk_bab(bab)
	_judul.text = String(data.get("judul", "PAPAN INSTRUKSI"))
	_tujuan.text = String(data.get("tujuan", ""))

	for baris in data.get("kontrol", []):
		_tambah_kontrol(String(baris[0]), String(baris[1]))
	for baris in data.get("bahaya", []):
		_tambah_butir(_kolom_bahaya, String(baris), WARNA_BAHAYA)
	for baris in data.get("cara", []):
		_tambah_butir(_kolom_cara, String(baris), WARNA_CARA)

	if mandiri:
		_tombol.text = "MULAI  -  %s" % GameState.display_name().to_upper()
	else:
		_tombol.text = "TUTUP"
	_tombol.pressed.connect(_tutup)
	_tombol.grab_focus()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


## Tombol dan artinya dibuat sebagai dua Label dalam satu baris, bukan satu
## Label berisi "Spasi - dash". Alasannya keterbacaan: kolom tombol yang rata
## kiri membuat mata bisa memindai daftar tombol tanpa membaca kalimatnya.
func _tambah_kontrol(tombol: String, arti: String) -> void:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 16)

	var kiri := Label.new()
	kiri.text = tombol
	kiri.custom_minimum_size.x = 210.0
	kiri.add_theme_font_size_override("font_size", 18)
	kiri.add_theme_color_override("font_color", Color(1, 0.93, 0.7))

	var kanan := Label.new()
	kanan.text = arti
	kanan.add_theme_font_size_override("font_size", 18)
	kanan.add_theme_color_override("font_color", Color(0.86, 0.93, 0.96))
	kanan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kanan.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	baris.add_child(kiri)
	baris.add_child(kanan)
	_kolom_kontrol.add_child(baris)


func _tambah_butir(kolom: VBoxContainer, teks: String, warna: Color) -> void:
	var label := Label.new()
	label.text = "•  %s" % teks
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", warna)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 4)
	kolom.add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_tutup()


func _tutup() -> void:
	# Tombol dan tuts bisa sama-sama sampai ke sini dalam frame yang sama.
	# Tanpa penjaga ini, papan tempelan di menu jeda akan memancarkan sinyal
	# "ditutup" dua kali dan menu jeda menghitungnya sebagai dua kali tutup.
	if _sudah_ditutup:
		return
	_sudah_ditutup = true

	if not mandiri:
		ditutup.emit()
		queue_free()
		return
	# Ditandai sudah dilihat supaya papan ini tidak muncul lagi tiap kali bab
	# diulang. Pemain yang butuh membacanya lagi bisa membukanya dari menu jeda.
	GameState.mark_story_seen(Story.kunci_briefing(bab))
	SceneRouter.lanjutkan_rantai()
