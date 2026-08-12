extends CanvasLayer
## Layar "MISI SELESAI". Dipasang wasit peta sebagai TEMPELAN di atas peta yang
## baru saja diselesaikan, bukan sebagai scene baru.
##
## Petanya sengaja dibiarkan kelihatan di belakang. Sungai yang sudah bersih
## adalah hadiah yang paling dihasilkan pemain sendiri; menutupinya dengan latar
## polos berarti membuang satu-satunya bukti bahwa dia berhasil.
##
## Semua angka MUNCUL BERTAHAP, bukan sekaligus. Skor berhitung naik, bintang
## menyala satu per satu, lencana masuk belakangan. Alasannya bukan hiasan:
## hadiah yang muncul sekaligus dibaca sebagai satu kejadian, sedangkan hadiah
## yang menetes dibaca sebagai beberapa kejadian baik berturut-turut -- dan itu
## terasa jauh lebih banyak walaupun isinya sama persis.

## Lama angka skor berhitung dari nol sampai penuh.
@export var lama_hitung: float = 1.1
## Jeda antar bintang menyala.
@export var jeda_bintang: float = 0.32

@onready var _judul: Label = %Judul
@onready var _nama_bab: Label = %NamaBab
@onready var _skor: Label = %Skor
@onready var _rincian: Label = %Rincian
@onready var _lencana: VBoxContainer = %Lencana
@onready var _bintang_baris: HBoxContainer = %BintangBaris
@onready var _petunjuk: Label = %Petunjuk
@onready var _kotak: Control = %Kotak

const WARNA_BINTANG_NYALA := Color(1.0, 0.84, 0.35)
const WARNA_BINTANG_MATI := Color(1, 1, 1, 0.14)

var _bintang: Array[Polygon2D] = []


func _ready() -> void:
	layer = 20
	# Layar ini muncul tepat saat permainan dibekukan wasit, dan pada beberapa
	# jalur get_tree().paused sudah true. Tanpa baris ini, animasinya tidak
	# pernah jalan dan pemain melihat panel kosong.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## Satu-satunya pintu masuk. Dipanggil wasit peta sesudah rondenya dinyatakan
## menang, dengan angka yang SUDAH final -- layar ini tidak menghitung apa pun
## sendiri dan tidak menyentuh GameState. Kalau dia ikut menghitung, akan ada
## dua tempat yang tahu cara menilai satu ronde, dan keduanya pasti berbeda
## suatu hari.
func tampilkan(bab: int, skor: int, rekor_baru: bool, sempurna: bool, petunjuk: String) -> void:
	var data := GameState.chapter_data(bab)
	_judul.text = "MISI SELESAI"
	_nama_bab.text = String(data.get("title", "")).to_upper()
	_petunjuk.text = petunjuk
	_skor.text = "0"
	_rincian.text = "%s berhasil membersihkan %s." % [
		GameState.display_name(), String(data.get("title", "sungai ini"))
	]

	_susun_bintang()
	_susun_lencana(bab, rekor_baru, sempurna)

	visible = true
	_kotak.scale = Vector2(0.92, 0.92)
	_kotak.modulate.a = 0.0
	var masuk := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	masuk.tween_property(_kotak, "scale", Vector2.ONE, 0.42)
	masuk.parallel().tween_property(_kotak, "modulate:a", 1.0, 0.3)

	_hitung_skor(skor)
	_nyalakan_bintang(Story.bintang(bab, skor))


func _susun_bintang() -> void:
	for anak in _bintang_baris.get_children():
		anak.queue_free()
	_bintang.clear()
	for i in 3:
		# Bintang digambar sebagai Polygon2D, bukan huruf "★". Font bawaan tidak
		# dijamin punya glyph itu, dan bintang yang berubah jadi kotak kosong di
		# komputer juri adalah kegagalan yang mahal untuk sesuatu yang sepele.
		var wadah := Control.new()
		wadah.custom_minimum_size = Vector2(92, 92)
		var bentuk := Polygon2D.new()
		bentuk.polygon = _bentuk_bintang(40.0, 17.0)
		bentuk.position = Vector2(46, 46)
		bentuk.color = WARNA_BINTANG_MATI
		wadah.add_child(bentuk)
		_bintang_baris.add_child(wadah)
		_bintang.append(bentuk)


func _bentuk_bintang(luar: float, dalam: float) -> PackedVector2Array:
	var titik := PackedVector2Array()
	for i in 10:
		var jari := luar if i % 2 == 0 else dalam
		# Dimulai dari -PI/2 supaya ujungnya menghadap ke ATAS. Bintang yang
		# miring sedikit saja langsung terbaca sebagai gambar yang salah.
		var sudut := -PI * 0.5 + TAU * float(i) / 10.0
		titik.append(Vector2.RIGHT.rotated(sudut) * jari)
	return titik


func _hitung_skor(akhir: int) -> void:
	var jalan := create_tween()
	jalan.tween_method(
		func(nilai: float) -> void: _skor.text = str(int(round(nilai))),
		0.0, float(akhir), lama_hitung
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _nyalakan_bintang(jumlah: int) -> void:
	for i in _bintang.size():
		if i >= jumlah:
			continue
		# Bintang menyala SESUDAH skornya selesai berhitung, bukan barengan.
		# Kalau barengan, mata pemain harus memilih mau melihat yang mana.
		await get_tree().create_timer(lama_hitung + jeda_bintang * float(i)).timeout
		if not is_inside_tree():
			return
		var bintang := _bintang[i]
		bintang.color = WARNA_BINTANG_NYALA
		var pop := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		bintang.scale = Vector2(0.4, 0.4)
		pop.tween_property(bintang, "scale", Vector2.ONE, 0.34)
		# Nada naik tiap bintang. Telinga menghitung sendiri tanpa perlu melihat.
		AudioManager.play("level_up", 0.0, 1.0 + 0.14 * float(i), 0.0)


func _susun_lencana(bab: int, rekor_baru: bool, sempurna: bool) -> void:
	for anak in _lencana.get_children():
		anak.queue_free()

	if sempurna:
		_tambah_lencana("RENCANA SEMPURNA", Color(0.45, 0.92, 0.98))
	if rekor_baru:
		_tambah_lencana("REKOR BARU", Color(1.0, 0.84, 0.35))

	# Bab berikutnya hanya diumumkan kalau memang baru saja terbuka. Mengumumkan
	# hal yang sama tiap kali bab diulang membuat kabar itu berhenti terasa
	# seperti kabar.
	var berikutnya := bab + 1
	var data_berikutnya := GameState.chapter_data(berikutnya)
	if not data_berikutnya.is_empty() and not GameState.is_completed(berikutnya):
		_tambah_lencana("TERBUKA: %s" % String(data_berikutnya.get("title", "")).to_upper(),
			Color(0.62, 0.93, 0.75))


func _tambah_lencana(teks: String, warna: Color) -> void:
	var label := Label.new()
	label.text = teks
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", warna)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.07, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.modulate.a = 0.0
	_lencana.add_child(label)

	var urutan := float(_lencana.get_child_count() - 1)
	var muncul := create_tween()
	muncul.tween_interval(lama_hitung + jeda_bintang * 3.0 + 0.2 * urutan)
	muncul.tween_property(label, "modulate:a", 1.0, 0.35)
