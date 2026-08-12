extends Node2D
## Perakit suasana sungai: tanaman, batu, gelembung, debu air, dan berkas cahaya.
##
## Map 1 punya semua ini karena disusun satu per satu di editor -- sebelas
## tanaman, enam batu, empat kolom gelembung, semuanya ditempatkan tangan. Map 2
## tidak pernah kebagian, dan Map 3 lahir belakangan tanpa satu pun. Hasilnya
## dua sungai yang terasa kosong padahal isinya sama sibuknya.
##
## Node ini merakit semuanya dari kode, dari satu kotak dunia. Jadi menambahkan
## suasana ke peta baru berarti menempelkan satu node, bukan menyalin empat
## puluh node dan memperbaiki posisinya satu-satu.
##
## KEDALAMAN dibangun lewat tiga lapis yang bergerak berbeda:
##
##   LATAR   siluet gelap, kecil, nyaris tidak bergerak. Membuat air terasa
##           punya ruang di belakang, bukan sekadar warna.
##   TENGAH  gelembung dan debu air yang naik pelan. Inilah yang membuat airnya
##           terbaca sebagai AIR, bukan sebagai kabut biru.
##   DEPAN   tanaman besar dan gelap di tepi bawah layar. Benda yang lewat DI
##           DEPAN pemain adalah cara termurah membuat kamera terasa berada di
##           dalam air, bukan menonton dari balik kaca.
##
## Semuanya digoyang pelan dengan fase acak-tetap. Tanaman air yang benar-benar
## diam terbaca sebagai gambar tempel; yang bergoyang serempak terbaca sebagai
## animasi. Yang bergoyang masing-masing sendiri barulah terbaca sebagai hidup.

const RUMPUT_LATAR := [
	preload("res://kenney_fish-pack_2/PNG/Double/background_seaweed_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/background_seaweed_c.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/background_seaweed_e.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/background_seaweed_g.png"),
]
const BATU_LATAR := [
	preload("res://kenney_fish-pack_2/PNG/Double/background_rock_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/background_rock_b.png"),
]
const RUMPUT_DEPAN := [
	preload("res://kenney_fish-pack_2/PNG/Double/seaweed_green_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/seaweed_grass_a.png"),
]
const BATU_DEPAN := [
	preload("res://kenney_fish-pack_2/PNG/Double/rock_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/rock_b.png"),
]
const GELEMBUNG := preload("res://kenney_fish-pack_2/PNG/Double/bubble_a.png")

@export_group("Urutan gambar")
## Lapisan belakang (tanaman jauh, serpihan, debu air) digambar di sini.
##
## Harus diatur per peta, dan salah mengaturnya membuat SELURUH suasana tak
## terlihat: Map 2 punya poligon air yang menutupi layar di z 0, jadi apa pun
## yang bernilai negatif tenggelam di belakangnya. Map 3 sebaliknya -- papan
## puzzle-nya sendiri ada di z -10, jadi suasananya harus lebih rendah lagi
## supaya tidak menutupi petak yang harus dibaca pemain.
@export var z_belakang: int = 0
## Lapisan depan: tanaman besar yang lewat di depan ikan.
@export var z_depan: int = 20

@export_group("Kotak dunia")
@export var ukuran_dunia: Vector2 = Vector2(2048.0, 1152.0)
## Tinggi dasar sungai di bagian bawah. Tanaman tumbuh dari sini.
@export var tinggi_dasar: float = 160.0

@export_group("Isi")
@export var jumlah_rumput_latar: int = 16
@export var jumlah_batu_latar: int = 7
@export var jumlah_rumput_depan: int = 7
@export var jumlah_batu_depan: int = 4
@export var kolom_gelembung: int = 4
## Serpihan tumbuhan yang melayang di tengah kolom air.
##
## Ini yang paling penting sejak kameranya didekatkan: hiasan yang cuma ada di
## DASAR sungai praktis tidak pernah masuk layar lagi. Pemain menghabiskan
## hampir seluruh waktunya di tengah air, jadi di situlah suasananya harus ada.
@export var jumlah_melayang: int = 22

@export_group("Rasa")
## Warna semburat lapisan latar. Makin pekat, makin terasa jauh.
@export var semburat_latar: Color = Color(0.42, 0.58, 0.58, 0.5)
@export var semburat_depan: Color = Color(0.1, 0.18, 0.17, 0.92)
@export var goyang_derajat: float = 5.0
@export var goyang_laju: float = 0.55

var _goyang: Array = []
var _hanyut: Array = []
var _waktu: float = 0.0


func _ready() -> void:
	# Acakan bersumber dari nama node, bukan dari waktu: satu peta harus terlihat
	# sama tiap kali dibuka. Sungai yang isinya berpindah-pindah tiap kali
	# diulang membuat pemain kehilangan tempat yang dia hafal.
	var acak := RandomNumberGenerator.new()
	acak.seed = hash(name) + 991

	_rakit_latar(acak)
	_rakit_gelembung(acak)
	_rakit_melayang(acak)
	_rakit_debu()
	_rakit_depan(acak)


func _process(delta: float) -> void:
	_waktu += delta
	for data in _goyang:
		var node: Node2D = data["node"]
		if not is_instance_valid(node):
			continue
		# Tiap tanaman punya fase dan lajunya sendiri. Itu yang memisahkan
		# "hidup" dari "beranimasi".
		node.rotation = sin(_waktu * float(data["laju"]) + float(data["fase"])) \
			* deg_to_rad(goyang_derajat) * float(data["kuat"])

	for data in _hanyut:
		var serpih: Node2D = data["node"]
		if not is_instance_valid(serpih):
			continue
		serpih.position.x -= float(data["laju"]) * delta
		serpih.position.y = float(data["y"]) \
			+ sin(_waktu * 0.5 + float(data["fase"])) * float(data["apung"])
		serpih.rotation += float(data["putar"]) * delta
		# Dibungkus kembali ke tepi kanan supaya sungainya tidak pernah kehabisan
		# serpihan, berapa lama pun satu babak berjalan.
		if serpih.position.x < -90.0:
			serpih.position.x = ukuran_dunia.x + 90.0


func _dasar_y() -> float:
	return ukuran_dunia.y - tinggi_dasar


func _rakit_latar(acak: RandomNumberGenerator) -> void:
	for i in jumlah_rumput_latar:
		var rumput := _sprite(RUMPUT_LATAR[acak.randi() % RUMPUT_LATAR.size()], z_belakang)
		var tinggi := acak.randf_range(90.0, 190.0)
		_skala_ke_tinggi(rumput, tinggi)
		rumput.position = Vector2(acak.randf_range(0.0, ukuran_dunia.x),
			_dasar_y() + acak.randf_range(-6.0, 26.0))
		rumput.modulate = semburat_latar
		rumput.flip_h = acak.randf() < 0.5
		add_child(rumput)
		_daftar_goyang(rumput, acak, 0.6)

	for i in jumlah_batu_latar:
		var batu := _sprite(BATU_LATAR[acak.randi() % BATU_LATAR.size()], z_belakang)
		_skala_ke_tinggi(batu, acak.randf_range(60.0, 130.0))
		batu.position = Vector2(acak.randf_range(0.0, ukuran_dunia.x),
			_dasar_y() + acak.randf_range(0.0, 34.0))
		batu.modulate = semburat_latar
		batu.rotation = acak.randf_range(-0.2, 0.2)
		add_child(batu)


## Kolom gelembung. Sebagian dari dasar sungai, sebagian dari tengah air.
##
## Yang dari tengah air itu bukan kemalasan menempatkan: gelembung memang lepas
## dari tumbuhan dan celah batu di segala kedalaman. Dan justru itu yang terus
## terlihat saat kamera dekat.
func _rakit_gelembung(acak: RandomNumberGenerator) -> void:
	for i in kolom_gelembung:
		var kolom := CPUParticles2D.new()
		kolom.texture = GELEMBUNG
		kolom.z_index = z_belakang + 2
		kolom.amount = acak.randi_range(6, 12)
		kolom.lifetime = acak.randf_range(4.5, 7.5)
		kolom.preprocess = 4.0
		kolom.randomness = 0.6
		kolom.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		kolom.emission_rect_extents = Vector2(acak.randf_range(20.0, 60.0), 8.0)
		kolom.direction = Vector2.UP
		kolom.spread = 12.0
		kolom.gravity = Vector2(0.0, -12.0)
		kolom.initial_velocity_min = 26.0
		kolom.initial_velocity_max = 64.0
		kolom.scale_amount_min = 0.05
		kolom.scale_amount_max = 0.19
		kolom.color = Color(0.78, 0.94, 1.0, 0.4)
		# Dua dari tiga kolom lahir di tengah kolom air, bukan di dasar.
		var y := _dasar_y()
		if i % 3 != 0:
			y = acak.randf_range(ukuran_dunia.y * 0.2, ukuran_dunia.y * 0.85)
		kolom.position = Vector2(acak.randf_range(80.0, ukuran_dunia.x - 80.0), y)
		add_child(kolom)


## Serpihan tumbuhan yang hanyut pelan di tengah air, di berbagai kedalaman.
##
## Yang jauh dibuat kecil, pudar, dan bergerak lambat; yang dekat lebih besar,
## lebih pekat, dan lebih cepat. Perbedaan kecepatan itulah yang membuat air
## terasa punya kedalaman -- tanpa itu semuanya terbaca sebagai satu bidang
## datar yang ditempeli gambar.
func _rakit_melayang(acak: RandomNumberGenerator) -> void:
	for i in jumlah_melayang:
		var jauh := acak.randf()
		var serpih := _sprite(RUMPUT_LATAR[acak.randi() % RUMPUT_LATAR.size()], z_belakang + 1)
		_skala_ke_tinggi(serpih, lerpf(96.0, 28.0, jauh))
		serpih.position = Vector2(
			acak.randf_range(0.0, ukuran_dunia.x),
			acak.randf_range(ukuran_dunia.y * 0.08, ukuran_dunia.y * 0.92))
		serpih.rotation = acak.randf_range(0.0, TAU)
		serpih.modulate = semburat_latar
		serpih.modulate.a *= lerpf(1.0, 0.45, jauh)
		add_child(serpih)
		_hanyut.append({
			"node": serpih,
			"laju": lerpf(16.0, 4.0, jauh),
			"putar": acak.randf_range(-0.22, 0.22),
			"apung": acak.randf_range(4.0, 13.0),
			"fase": acak.randf_range(0.0, TAU),
			"y": serpih.position.y,
		})


## Debu air: butir halus yang melayang pelan ke kiri, mengikuti arus.
func _rakit_debu() -> void:
	var debu := CPUParticles2D.new()
	debu.z_index = z_belakang + 1
	debu.amount = 240
	debu.lifetime = 9.0
	debu.preprocess = 8.0
	debu.randomness = 0.8
	debu.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	debu.emission_rect_extents = ukuran_dunia * 0.5
	debu.position = ukuran_dunia * 0.5
	debu.direction = Vector2.LEFT
	debu.spread = 24.0
	debu.gravity = Vector2(0.0, -6.0)
	debu.initial_velocity_min = 8.0
	debu.initial_velocity_max = 28.0
	debu.scale_amount_min = 1.2
	debu.scale_amount_max = 3.4
	debu.color = Color(0.82, 0.94, 0.97, 0.34)
	add_child(debu)


## Lapisan depan: tanaman besar dan gelap yang lewat DI DEPAN ikan.
##
## Ini lapisan yang paling murah sekaligus paling terasa. Tanpa sesuatu di depan
## kamera, seluruh permainan terlihat seperti ditonton dari balik kaca akuarium.
func _rakit_depan(acak: RandomNumberGenerator) -> void:
	for i in jumlah_rumput_depan:
		var rumput := _sprite(RUMPUT_DEPAN[acak.randi() % RUMPUT_DEPAN.size()], z_depan)
		_skala_ke_tinggi(rumput, acak.randf_range(190.0, 330.0))
		rumput.position = Vector2(acak.randf_range(-40.0, ukuran_dunia.x + 40.0),
			ukuran_dunia.y + acak.randf_range(6.0, 40.0))
		rumput.modulate = semburat_depan
		rumput.flip_h = acak.randf() < 0.5
		add_child(rumput)
		_daftar_goyang(rumput, acak, 1.0)

	for i in jumlah_batu_depan:
		var batu := _sprite(BATU_DEPAN[acak.randi() % BATU_DEPAN.size()], z_depan)
		_skala_ke_tinggi(batu, acak.randf_range(130.0, 220.0))
		batu.position = Vector2(acak.randf_range(0.0, ukuran_dunia.x),
			ukuran_dunia.y + acak.randf_range(20.0, 60.0))
		batu.modulate = semburat_depan
		batu.rotation = acak.randf_range(-0.25, 0.25)
		add_child(batu)


func _sprite(tekstur: Texture2D, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tekstur
	s.z_index = z
	# Titik putarnya dipindah ke KAKI tanaman, supaya goyangannya berayun dari
	# pangkal seperti tumbuhan sungguhan, bukan berputar di tengah badannya.
	s.offset = Vector2(0.0, -float(tekstur.get_height()) * 0.5)
	return s


func _skala_ke_tinggi(s: Sprite2D, tinggi: float) -> void:
	var asli := float(s.texture.get_height())
	if asli > 0.0:
		s.scale = Vector2.ONE * (tinggi / asli)


func _daftar_goyang(node: Node2D, acak: RandomNumberGenerator, kuat: float) -> void:
	_goyang.append({
		"node": node,
		"fase": acak.randf_range(0.0, TAU),
		"laju": goyang_laju * acak.randf_range(0.7, 1.4),
		"kuat": kuat,
	})
