extends Control
## Pemutar cutscene. SATU scene untuk seluruh cerita, bukan satu scene per babak.
##
## Yang membedakan satu panel dari panel lain cuma data: warna air, jumlah ikan,
## kepadatan sampah, kecepatan arus, dan kalimatnya. Semuanya ada di story.gd.
## Jadi menambah panel baru berarti menambah satu baris data -- tidak ada scene
## yang perlu disalin, tidak ada node yang perlu diberi nama unik lagi.
##
## Latarnya dirakit di kode, bukan disusun di editor, justru karena isinya
## berubah tiap panel. Node yang harus muncul-hilang-berganti-warna terus lebih
## murah dibuat dan dibuang daripada disiapkan semua di depan lalu disembunyikan.

## Kecepatan teks mengetik, huruf per detik. Cukup cepat untuk tidak menyiksa
## pembaca cepat, cukup pelan untuk terasa seperti ada yang bercerita.
@export var kecepatan_ketik: float = 42.0
## Jeda sebelum panel menerima tombol, supaya Enter yang masih tertekan dari
## layar sebelumnya tidak melompati satu panel penuh.
@export var kunci_input: float = 0.35

const TEKSTUR_IKAN := preload("res://kenney_fish-pack_2/PNG/Double/fish_green.png")
const TEKSTUR_GELEMBUNG := preload("res://kenney_fish-pack_2/PNG/Double/bubble_a.png")

@onready var _judul: Label = %Judul
@onready var _teks: Label = %Teks
@onready var _petunjuk: Label = %Petunjuk
@onready var _panggung: Node2D = %Panggung
@onready var _kotak_teks: Control = %KotakTeks

var _panel: Array = []
var _index: int = -1
var _lanjut_ke: String = ""
var _id: String = ""

var _huruf: float = 0.0
var _teks_penuh: String = ""
var _lock: float = 0.0
var _selesai_mengetik: bool = false

var _air: Polygon2D
var _ikan: Array[Sprite2D] = []
var _sampah: Array[Node2D] = []
var _waktu: float = 0.0


func _ready() -> void:
	_id = SceneRouter.cutscene_id
	_lanjut_ke = SceneRouter.cutscene_next

	var data: Dictionary = Story.CUTSCENES.get(_id, {})
	_panel = data.get("panel", [])
	_judul.text = String(data.get("judul", ""))

	_air = Polygon2D.new()
	_air.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)
	])
	_panggung.add_child(_air)
	_panggung.move_child(_air, 0)

	_petunjuk.text = "Enter / klik  lanjut          Esc  lewati"

	if _panel.is_empty():
		_bubar()
		return
	_maju()


func _process(delta: float) -> void:
	_waktu += delta
	_lock = maxf(_lock - delta, 0.0)

	# Teks mengetik. Diukur dalam HURUF, bukan lewat Tween ke visible_ratio,
	# supaya kecepatannya sama untuk kalimat pendek maupun panjang -- kalimat
	# pendek yang selesai dalam waktu yang sama akan terasa lambat sekali.
	if not _selesai_mengetik:
		_huruf += kecepatan_ketik * delta
		_teks.visible_characters = int(_huruf)
		if _huruf >= float(_teks_penuh.length()):
			_selesai_mengetik = true
			_teks.visible_characters = -1

	_gerakkan_latar(delta)


func _gerakkan_latar(delta: float) -> void:
	if _index < 0 or _index >= _panel.size():
		return
	var arus := float(_panel[_index].get("arus", 40.0))

	# Ikan berenang ke kiri mengikuti arus, lalu dibungkus kembali ke tepi kanan.
	# Hanyut, bukan berenang acak: yang mau ditunjukkan adalah AIRNYA bergerak.
	for i in _ikan.size():
		var ikan := _ikan[i]
		ikan.position.x -= (arus * 0.85 + 12.0 * float(i % 4)) * delta
		ikan.position.y += sin(_waktu * 1.7 + float(i)) * 22.0 * delta
		if ikan.position.x < -120.0:
			ikan.position.x = 1400.0
			ikan.position.y = randf_range(90.0, 640.0)

	# Sampah hanyut lebih pelan daripada ikan dan berputar. Perbedaan kecepatan
	# itu yang membuat sampah terbaca sebagai benda mati yang cuma terbawa,
	# bukan sebagai makhluk yang berenang.
	for keping in _sampah:
		keping.position.x -= (arus * 0.5 + 8.0) * delta
		keping.rotation += delta * 0.6
		if keping.position.x < -90.0:
			keping.position.x = 1370.0
			keping.position.y = randf_range(70.0, 660.0)


func _unhandled_input(event: InputEvent) -> void:
	if _lock > 0.0:
		return

	if event.is_action_pressed("ui_cancel"):
		# Melewati cutscene tetap menandainya sudah ditonton. Pemain yang memilih
		# melewati sudah memutuskan; memaksanya menonton lagi di percobaan
		# berikutnya adalah menghukum keputusan yang sah.
		_bubar()
		get_viewport().set_input_as_handled()
		return

	var maju := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		maju = true
	if not maju:
		return

	get_viewport().set_input_as_handled()
	# Tombol pertama menyelesaikan ketikan, tombol kedua baru pindah panel.
	# Pembaca cepat tidak perlu menunggu, pembaca pelan tidak dilompati.
	if not _selesai_mengetik:
		_selesai_mengetik = true
		_teks.visible_characters = -1
		return
	_maju()


func _maju() -> void:
	_index += 1
	if _index >= _panel.size():
		_bubar()
		return
	_pasang(_panel[_index])


func _pasang(panel: Dictionary) -> void:
	var atas: Color = panel.get("air_atas", Color(0.24, 0.42, 0.45))
	var bawah: Color = panel.get("air_bawah", Color(0.07, 0.16, 0.2))
	_air.vertex_colors = PackedColorArray([atas, atas, bawah, bawah])

	_bersihkan()
	_isi_ikan(int(panel.get("ikan", 0)), panel.get("warna_ikan", Color.WHITE))
	_isi_sampah(int(panel.get("sampah", 0)))

	_teks_penuh = String(panel.get("teks", "")).format({"nama": GameState.display_name()})
	_teks.text = _teks_penuh
	_teks.visible_characters = 0
	_huruf = 0.0
	_selesai_mengetik = false
	_lock = kunci_input

	# Panel masuk dengan redup singkat. Tanpa ini, pergantian panel terlihat
	# seperti gambar yang rusak sekejap, bukan seperti halaman yang dibalik.
	_panggung.modulate.a = 0.35
	_kotak_teks.modulate.a = 0.0
	var masuk := create_tween()
	masuk.tween_property(_panggung, "modulate:a", 1.0, 0.4)
	masuk.parallel().tween_property(_kotak_teks, "modulate:a", 1.0, 0.3)

	if bool(panel.get("getar", false)):
		AudioManager.play("warning", -2.0, 0.7, 0.0)
	else:
		AudioManager.play("link_tick", -12.0, 0.8, 0.0)


func _bersihkan() -> void:
	for ikan in _ikan:
		ikan.queue_free()
	for keping in _sampah:
		keping.queue_free()
	_ikan.clear()
	_sampah.clear()


func _isi_ikan(jumlah: int, warna: Color) -> void:
	for i in jumlah:
		var ikan := Sprite2D.new()
		ikan.texture = TEKSTUR_IKAN
		ikan.modulate = warna
		# Ikan di kejauhan dibuat lebih kecil DAN lebih pudar. Dua isyarat
		# sekaligus, karena ukuran saja gampang terbaca sebagai "ikan kecil"
		# alih-alih "ikan jauh".
		var jauh := randf()
		ikan.scale = Vector2.ONE * lerpf(0.85, 0.35, jauh)
		ikan.modulate.a = lerpf(1.0, 0.3, jauh)
		ikan.position = Vector2(randf_range(-100.0, 1380.0), randf_range(90.0, 640.0))
		ikan.flip_h = true
		_panggung.add_child(ikan)
		_ikan.append(ikan)


func _isi_sampah(jumlah: int) -> void:
	for i in jumlah:
		var keping := Polygon2D.new()
		var r := randf_range(11.0, 26.0)
		# Segi empat miring acak, bukan kotak rapi: sampah sungguhan tidak ada
		# yang bentuknya seragam, dan keseragaman langsung terbaca sebagai pola.
		keping.polygon = PackedVector2Array([
			Vector2(-r, -r * randf_range(0.5, 1.0)),
			Vector2(r * randf_range(0.6, 1.2), -r * 0.7),
			Vector2(r, r * randf_range(0.5, 1.0)),
			Vector2(-r * randf_range(0.7, 1.1), r * 0.8),
		])
		keping.color = Color(
			randf_range(0.32, 0.55), randf_range(0.3, 0.45), randf_range(0.25, 0.4), 0.85
		)
		keping.position = Vector2(randf_range(-80.0, 1360.0), randf_range(70.0, 660.0))
		keping.rotation = randf_range(0.0, TAU)
		_panggung.add_child(keping)
		_sampah.append(keping)


func _bubar() -> void:
	GameState.mark_story_seen(_id)
	if not _lanjut_ke.is_empty():
		SceneRouter.go_to(_lanjut_ke)
		return
	# Tanpa tujuan khusus, serahkan kembali ke rantai. Di tengah rantai bab, dia
	# akan meneruskan ke papan instruksi lalu ke petanya; di cutscene penutup
	# yang berdiri sendiri, rantainya kosong dan dia mengantar ke menu.
	SceneRouter.lanjutkan_rantai()
