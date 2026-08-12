extends Node2D
## Wasit Map 3 -- Kali Jeroan Madiun. Puzzle dorong balok ala Sokoban.
##
## Aturannya cuma satu kalimat:
##
##     Dorong balok bambu keluar dari lorong, supaya airnya bisa tembus dari
##     hulu sampai ke mulut sungai.
##
## Kenapa dibangun ulang jadi seperti ini: dua versi sebelumnya menyuruh pemain
## MENAHAN sesuatu -- menahan posisi, lalu menahan tombol. Dua-duanya bukan
## puzzle, karena tidak ada yang perlu dipindahkan ke tempat yang benar dan
## tidak ada langkah yang bisa salah secara permanen. Sokoban punya keduanya:
## tiap dorongan mengubah papan, dan sebagian dorongan tidak bisa dibatalkan.
##
## Empat hal yang membuatnya bisa dibaca, dan ketiganya jawaban langsung atas
## keluhan "ga tau titiknya di mana":
##   1. Semuanya di atas PETAK. Tidak ada lagi radius tak terlihat.
##   2. Balok bermuka RATA. Ikan menempel di muka yang jelas, tidak meluncur
##      menyusuri lengkungan seperti dulu.
##   3. Muka yang bisa didorong MENYALA plus panah arahnya, begitu ikan berada
##      di tempat yang benar.
##   4. Airnya merambat maju satu petak tiap kali jalannya terbuka -- umpan
##      balik langsung bahwa dorongan barusan berguna.
##
## Papannya ditulis sebagai gambar teks di bawah, bukan disusun sebagai node di
## editor. Satu layar teks jauh lebih cepat dibaca dan diubah daripada 50 node,
## dan salah ketiknya langsung kelihatan sebagai gambar yang miring.

enum Isi { KOSONG, BATU, KECIL, BESAR }
enum Phase { BERMAIN, SELESAI, TERKUNCI }

## Urutan gambar, dari paling belakang ke paling depan. Dikumpulkan di satu
## tempat supaya "apa menutupi apa" bisa dibaca sekali lihat, alih-alih tersebar
## sebagai angka ajaib di lima fungsi berbeda.
const Z_LANTAI := -10   ## dasar sungai, batu, genangan air, hiasan
const Z_BALOK := 0
const Z_IKAN := 5

## Jenis permukaan satu petak, dipakai menggambar batas antar wilayah.
const JENIS_LUAR := 0
const JENIS_BATU := 1
const JENIS_TEPIAN := 2
const JENIS_LORONG := 3

const TEKSTUR_RUMPUT := preload("res://kenney_fish-pack_2/PNG/Double/seaweed_green_a.png")
const TEKSTUR_BATU := preload("res://kenney_fish-pack_2/PNG/Double/rock_a.png")
## Bongkahan untuk tebing. Yang "latar" bentuknya lebih bulat dan tumpul --
## dipakai di dalam tebing; yang biasa lebih bersudut, dipakai di bibirnya.
const BONGKAH_BIBIR := [
	preload("res://kenney_fish-pack_2/PNG/Double/rock_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/rock_b.png"),
]
const BONGKAH_DALAM := [
	preload("res://kenney_fish-pack_2/PNG/Double/background_rock_a.png"),
	preload("res://kenney_fish-pack_2/PNG/Double/background_rock_b.png"),
]

## Denah papan.
##   #  batu -- ikan maupun air tidak bisa lewat
##   .  TEPIAN: ikan bisa berenang, air TIDAK mengalir ke sini
##   =  LORONG: ikan bisa berenang, DAN air mengalir lewat sini
##   k  balok kecil di lorong, satu ikan cukup
##   B  balok besar di lorong, butuh dua ikan
##   I  mulut masuk air (hulu)
##   O  mulut keluar air (hilir) -- air harus sampai sini
##
## KENAPA TEPIAN DAN LORONG DIPISAH.
##
## Versi pertama papan ini memakai satu jenis petak untuk keduanya, dan hasilnya
## MUSTAHIL diselesaikan: lorong air satu-satunya jalan ikan juga, jadi begitu
## balok pertama menyumbat lorong, ikan ikut terkurung di satu sisi dan tidak
## akan pernah bisa mencapai sisi seberang balok mana pun.
##
## Sokoban memang menuntut pemain bisa berjalan MEMUTARI balok. Tapi kalau air
## boleh lewat semua petak yang bisa dilalui ikan, jalan memutar itu otomatis
## jadi jalan pintas buat airnya juga, dan puzzlenya bubar.
##
## Pemisahan ini menyelesaikan keduanya sekaligus, dan kebetulan juga jujur
## secara fisik: lorong itu bagian dalam sungai, tepian itu bagian dangkal.
## Ikan wader lewat di mana saja; arus airnya cuma lewat yang dalam.
##
## Balok di kolom 5 sengaja terjepit batu atas-bawah: dia tidak bisa langsung
## dikeluarkan, harus digeser menyamping dulu ke kolom 4 yang punya kantong.
## Itu satu-satunya "aha" yang harus ditemukan sendiri.
const PETA := [
	"#........#",
	"#..#.#...#",
	"O=k==B=k=I",
	"#..#.#...#",
	"#........#",
]

## Dorongan paling sedikit yang bisa menyelesaikan papan di atas:
## k(2) naik = 1; B(5) geser kiri lalu naik = 2; k(7) naik = 1. Total 4.
const DORONGAN_OPTIMAL := 4

@export_group("Papan")
@export var lebar_petak: float = 140.0
@export var titik_awal: Vector2 = Vector2(100.0, 100.0)

@export_group("Dorongan")
## Lama ikan harus menekan sebelum baloknya benar-benar pindah satu petak.
## Bukan nol: dorongan yang langsung jadi begitu ikan menyenggol membuat pemain
## memindahkan balok tanpa sengaja, dan di Sokoban satu langkah tak sengaja bisa
## mematikan papan.
@export var waktu_dorong: float = 0.3
## Lama balok meluncur ke petak berikutnya.
@export var lama_geser: float = 0.22

@export_group("Skor")
@export var skor_per_petak_air: int = 40
@export var skor_selesai: int = 1000
@export var bonus_langkah: int = 800
## Pengurang bonus tiap satu dorongan di atas jumlah optimal.
@export var denda_per_langkah: int = 100

@export_group("Gerbang progres")
@export var requires_map2: bool = true
@export var bypass_progress_gate: bool = true

@export_group("Ending")
@export_file("*.tscn") var ending_scene: String = "res://scenes/ui/ending_river.tscn"
@export var ending_delay: float = 2.2

const BALOK := preload("res://scripts/push_block.gd")
const MISI_SELESAI_SCENE := preload("res://scenes/ui/mission_complete.tscn")

@onready var _fish_a: CharacterBody2D = $FishA
@onready var _fish_b: CharacterBody2D = $FishB
@onready var _camera: Camera2D = $DuoCamera
@onready var _hud: CanvasLayer = $HUD
@onready var _pause: CanvasLayer = $PauseMenu

var _fish: Array[Node2D] = []
var _active_index: int = 0
var _phase: int = Phase.BERMAIN

## Isi tiap petak, diakses lewat _isi[baris][kolom].
var _isi: Array = []
## Petak mana yang dilalui arus air. Ikan boleh berenang di luar ini.
var _lorong: Array = []
var _balok: Dictionary = {}          # Vector2i -> node balok
var _masuk: Vector2i = Vector2i.ZERO
var _keluar: Vector2i = Vector2i.ZERO
var _baris: int = 0
var _kolom: int = 0

var _air: Node2D = null
var _petak_air: Dictionary = {}      # Vector2i -> Polygon2D
## Sudut kisi yang sudah diacak, supaya dua petak bertetangga memakai titik
## yang sama persis. Vector2i -> Vector2.
var _sudut_teracak: Dictionary = {}
var _sudah_terairi: Dictionary = {}
var _dorongan: int = 0
var _muatan: Dictionary = {}         # Vector2i -> float, lama ditekan
var _menunggu_lanjut: bool = false
## Sudah berapa lama pendamping tidak bergerak padahal belum sampai tujuan.
var _teman_macet: float = 0.0
## Balok yang sedang SENGAJA dibantu pendamping. Vector2i(-1, -1) = tidak ada.
var _petak_dibantu: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	GameState.begin_run(3, scene_file_path)
	_fish = [_fish_a, _fish_b]

	for ikan in _fish:
		ikan.z_index = Z_IKAN

	_baris = PETA.size()
	_kolom = String(PETA[0]).length()
	var kotak_air := Rect2(titik_awal, Vector2(float(_kolom), float(_baris)) * lebar_petak)
	for ikan in _fish:
		ikan.swim_bounds = kotak_air

	if not _progress_gate_passed():
		_phase = Phase.TERKUNCI
		for ikan in _fish:
			ikan.set_active(false)
			ikan.set_physics_process(false)
		_pause.enabled = false
		_hud.show_result("BAB INI MASIH TERKUNCI",
			"Selesaikan Sungai Ciliwung dulu  -  tekan Enter untuk pilih bab")
		return

	_bangun_papan()
	_taruh_ikan()
	_setup_camera(kotak_air)

	# Wader B tidak pernah bisa diambil alih. Ini bukan penyederhanaan malas:
	# ikan kedua yang KADANG dikendalikan pemain berarti dua bahasa kendali
	# dalam satu bab, dan pemain harus terus mengingat sedang memakai yang mana.
	_fish[1].npc = true
	_set_active(0)
	_hitung_air(false)

	_hud.show_banner(
		"Dorong balok bambu KELUAR dari lorong\nsampai airnya tembus ke mulut sungai.", 5.0)
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 1.8)


func _progress_gate_passed() -> bool:
	if not requires_map2 or bypass_progress_gate:
		return true
	return GameState.is_unlocked(3)


func _setup_camera(kotak: Rect2) -> void:
	_camera.limit_left = int(kotak.position.x - lebar_petak)
	_camera.limit_top = int(kotak.position.y - lebar_petak)
	_camera.limit_right = int(kotak.end.x + lebar_petak)
	_camera.limit_bottom = int(kotak.end.y + lebar_petak)


# --- Papan ------------------------------------------------------------------

func tengah_petak(p: Vector2i) -> Vector2:
	return titik_awal + (Vector2(p) + Vector2(0.5, 0.5)) * lebar_petak


func _di_dalam(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < _kolom and p.y < _baris


func _bangun_papan() -> void:
	_air = Node2D.new()
	# Urutan gambar dipatok lewat z_index, BUKAN lewat urutan anak.
	#
	# Sebelumnya papan ini dipindah ke indeks 0 supaya "paling belakang" -- dan
	# justru itu bugnya: indeks 0 digambar PALING DULU, jadi latar sungai yang
	# ada di indeks 1 menimpanya. Seluruh kisi, batu, dan genangan air jadi tak
	# terlihat, dan pemain cuma melihat balok melayang di ruang kosong.
	#
	# Urutan anak juga rapuh: menambah satu node di scene bisa menggeser
	# segalanya. z_index menyatakan maksudnya langsung dan tidak bisa bergeser.
	_air.z_index = Z_LANTAI
	add_child(_air)

	var batu_induk := StaticBody2D.new()
	batu_induk.collision_layer = 16
	batu_induk.collision_mask = 0
	add_child(batu_induk)

	for y in _baris:
		var baris_isi: Array = []
		var baris_lorong: Array = []
		var teks := String(PETA[y])
		for x in _kolom:
			var huruf := teks[x]
			var p := Vector2i(x, y)
			var isi := Isi.KOSONG
			var lorong := huruf in ["=", "k", "B", "I", "O"]

			match huruf:
				"#":
					isi = Isi.BATU
					_pasang_batu(batu_induk, p)
				"k":
					_pasang_balok(p, false)
					isi = Isi.KECIL
				"B":
					_pasang_balok(p, true)
					isi = Isi.BESAR
				"I":
					_masuk = p
				"O":
					_keluar = p

			baris_isi.append(isi)
			baris_lorong.append(lorong)
		_isi.append(baris_isi)
		_lorong.append(baris_lorong)

	# Lantainya digambar SESUDAH seluruh denah terbaca, bukan sambil membacanya.
	# Bentuk tepi sungai bergantung pada petak TETANGGA, dan tetangga di sebelah
	# kanan belum ada isinya saat baris ini masih dibaca.
	_gambar_dasar()
	_gambar_garis_pantai()
	# Bongkahan batu digambar SESUDAH garis pantai, jadi dia menindih garisnya.
	# Justru itu yang diinginkan: garis lurus yang terpotong-potong bongkahan
	# berhenti terbaca sebagai tepi petak.
	_hiasi_tebing()
	_hiasi_tepian()

	_pasang_mulut(_masuk, "HULU", Color(0.55, 0.85, 0.98))
	_pasang_mulut(_keluar, "MULUT SUNGAI", Color(0.62, 0.93, 0.75))


func _pasang_batu(induk: StaticBody2D, p: Vector2i) -> void:
	var bentuk := RectangleShape2D.new()
	bentuk.size = Vector2.ONE * lebar_petak
	var tabrakan := CollisionShape2D.new()
	tabrakan.shape = bentuk
	tabrakan.position = tengah_petak(p)
	induk.add_child(tabrakan)


## Titik sudut kisi yang sudah diacak, dalam koordinat dunia.
##
## INI KUNCINYA supaya papan tidak terlihat seperti kertas milimeter.
## Yang diacak adalah SUDUT kisi, bukan tiap petak. Dua petak bertetangga
## berbagi sudut yang sama persis, jadi acakannya menyatu tanpa celah maupun
## tumpang tindih -- hasilnya tepi sungai yang berkelok, bukan kotak-kotak.
## Kalau tiap petak diacak sendiri, sambungannya akan robek di mana-mana.
##
## Acakannya bersumber dari koordinat sudutnya sendiri, bukan dari randf(),
## supaya bentuk sungainya sama persis tiap kali peta dimuat ulang. Sungai yang
## berubah bentuk tiap kali diulang akan terasa seperti tempat yang berbeda.
func _sudut(gx: int, gy: int) -> Vector2:
	var kunci := Vector2i(gx, gy)
	if _sudut_teracak.has(kunci):
		return _sudut_teracak[kunci]

	var dasar := titik_awal + Vector2(float(gx), float(gy)) * lebar_petak
	# Sudut di tepi luar papan tidak diacak, supaya batas peta tetap rapi.
	var di_tepi := gx == 0 or gy == 0 or gx == _kolom or gy == _baris
	if not di_tepi:
		var acak := RandomNumberGenerator.new()
		acak.seed = hash(kunci)
		var jauh := lebar_petak * 0.16
		dasar += Vector2(acak.randf_range(-jauh, jauh), acak.randf_range(-jauh, jauh))

	_sudut_teracak[kunci] = dasar
	return dasar


## Keempat sudut satu petak, searah jarum jam.
func _segi_petak(p: Vector2i) -> PackedVector2Array:
	return PackedVector2Array([
		_sudut(p.x, p.y), _sudut(p.x + 1, p.y),
		_sudut(p.x + 1, p.y + 1), _sudut(p.x, p.y + 1),
	])


func _jenis(p: Vector2i) -> int:
	if not _di_dalam(p):
		return JENIS_LUAR
	if _isi[p.y][p.x] == Isi.BATU:
		return JENIS_BATU
	return JENIS_LORONG if _lorong[p.y][p.x] else JENIS_TEPIAN


## Isi tiap petak: batu, tepian, atau lorong. Tanpa garis pemisah sama sekali --
## garisnya diurus _gambar_garis_pantai(), dan hanya di tempat yang memang
## berganti jenis.
func _gambar_dasar() -> void:
	for y in _baris:
		for x in _kolom:
			var p := Vector2i(x, y)
			var jenis := _jenis(p)
			var segi := _segi_petak(p)

			var isi := Polygon2D.new()
			isi.polygon = segi
			match jenis:
				JENIS_BATU:
					# Cukup terang untuk terbaca sebagai BATU, bukan lubang.
					# Warna sebelumnya (0.17) nyaris sehitam latar, jadi tebingnya
					# terlihat seperti kartu gelap yang mengambang di atas tepian.
					isi.color = Color(0.235, 0.215, 0.16)
				JENIS_LORONG:
					# Lorong jelas lebih gelap daripada tepian -- perbedaan
					# kedalaman inilah satu-satunya yang memberi tahu pemain ke
					# mana airnya akan lewat.
					isi.color = Color(0.055, 0.125, 0.165)
				_:
					isi.color = Color(0.115, 0.195, 0.185)
			_air.add_child(isi)

			if jenis != JENIS_LORONG:
				continue

			# Lapisan air yang menyala saat petak lorong ini kebagian aliran.
			var genangan := Polygon2D.new()
			genangan.polygon = segi
			genangan.color = Color(0.35, 0.72, 0.85, 0.0)
			_air.add_child(genangan)
			_petak_air[p] = genangan


## Garis hanya digambar di SISI yang bersebelahan dengan jenis lain.
##
## Ini yang menghapus kesan kotak-kotak: kisi penuh menggambar 4 garis di tiap
## petak, jadi seluruh papan jadi jala. Di sini garis cuma muncul di batas batu
## dan air -- persis seperti garis pantai sungguhan. Dan karena kedua petak
## bertetangga memakai sudut teracak yang sama, garisnya nyambung mulus jadi
## satu kelokan panjang.
func _gambar_garis_pantai() -> void:
	var sisi := [
		[Vector2i.UP, 0, 1], [Vector2i.RIGHT, 1, 2],
		[Vector2i.DOWN, 2, 3], [Vector2i.LEFT, 3, 0],
	]
	for y in _baris:
		for x in _kolom:
			var p := Vector2i(x, y)
			var jenis := _jenis(p)
			if jenis == JENIS_BATU:
				continue
			var segi := _segi_petak(p)

			for s in sisi:
				var tetangga := _jenis(p + s[0])
				if tetangga == jenis:
					continue
				var garis := Line2D.new()
				garis.points = PackedVector2Array([segi[s[1]], segi[s[2]]])
				garis.begin_cap_mode = Line2D.LINE_CAP_ROUND
				garis.end_cap_mode = Line2D.LINE_CAP_ROUND
				if tetangga == JENIS_BATU or tetangga == JENIS_LUAR:
					# Tipis saja. Garis tebal mengelilingi bentuk gelap membuatnya
					# terbaca sebagai KARTU BERBINGKAI, bukan sebagai massa batu --
					# yang menyudutkan tebingnya justru bingkainya sendiri.
					garis.width = 4.0
					garis.default_color = Color(0.38, 0.35, 0.25)
				else:
					# Batas lorong dengan tepian: garis samar kebiruan, cukup
					# untuk menunjukkan tepi alur airnya tanpa jadi pagar.
					garis.width = 3.0
					garis.default_color = Color(0.35, 0.72, 0.85, 0.22)
				_air.add_child(garis)


## Bongkahan batu di atas petak tebing.
##
## Tanpa ini tebingnya cuma blok gelap sepetak, dan sekeras apa pun tepinya
## dibikin berkelok, isinya tetap terbaca sebagai kotak. Yang menghapus kesan
## kotak bukan bentuk tepinya, melainkan benda-benda yang menyeberangi tepi itu.
##
## Dua lapis, dan pembagiannya disengaja:
##   BIBIR  -- bongkahan besar tepat di sisi yang menghadap air, sebagian
##             menjorok keluar petak. Inilah yang memotong garis pantai.
##   DALAM  -- bongkahan lebih kecil dan lebih gelap di tengah petak, sekadar
##             supaya bagian dalam tebing tidak rata.
##
## Bongkahan hanya boleh menjorok ke TEPIAN, tidak pernah ke lorong air. Lorong
## adalah satu-satunya hal yang harus selalu terbaca jelas di papan ini; menutupi
## tepinya dengan batu berarti mengaburkan jawaban puzzle-nya sendiri.
func _hiasi_tebing() -> void:
	var arah_sisi := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for y in _baris:
		for x in _kolom:
			var p := Vector2i(x, y)
			if _jenis(p) != JENIS_BATU:
				continue

			var acak := RandomNumberGenerator.new()
			acak.seed = hash(p) + 4242
			var pusat := tengah_petak(p)

			for arah in arah_sisi:
				var tetangga := _jenis(p + arah)
				if tetangga == JENIS_BATU or tetangga == JENIS_LUAR:
					continue

				var d := Vector2(arah)
				var tegak := Vector2(-d.y, d.x)
				# Menjorok keluar hanya kalau di seberangnya tepian; kalau lorong,
				# bongkahannya ditahan di dalam petak batu.
				# Menjorok secukupnya saja. Terlalu jauh, bongkahannya menutupi
				# tepian sampai pemain tidak lagi bisa menebak sejauh mana tebing
				# itu sebenarnya -- padahal tebing yang menghalangi renangnya.
				var menjorok := 0.05 if tetangga == JENIS_TEPIAN else -0.06

				for i in 2:
					var geser := acak.randf_range(-0.32, 0.32)
					var bongkah := Sprite2D.new()
					bongkah.texture = BONGKAH_BIBIR[acak.randi() % BONGKAH_BIBIR.size()]
					bongkah.position = pusat + d * lebar_petak * (0.5 + menjorok) \
						+ tegak * lebar_petak * geser
					_ukur(bongkah, acak.randf_range(0.5, 0.76) * lebar_petak)
					bongkah.rotation = acak.randf_range(-PI, PI)
					bongkah.flip_h = acak.randf() < 0.5
					# Jelas lebih TERANG daripada isian tebing, kalau tidak
					# bongkahannya tenggelam ke dalam warna dasarnya sendiri dan
					# tebingnya kembali terlihat rata.
					bongkah.modulate = Color(0.66, 0.62, 0.5).lerp(
						Color(0.42, 0.39, 0.29), acak.randf_range(0.0, 0.55))
					_air.add_child(bongkah)

			for i in 3:
				var dalam := Sprite2D.new()
				dalam.texture = BONGKAH_DALAM[acak.randi() % BONGKAH_DALAM.size()]
				dalam.position = pusat + Vector2(
					acak.randf_range(-0.32, 0.32), acak.randf_range(-0.32, 0.32)
				) * lebar_petak
				_ukur(dalam, acak.randf_range(0.42, 0.66) * lebar_petak)
				dalam.rotation = acak.randf_range(-PI, PI)
				dalam.flip_h = acak.randf() < 0.5
				# Lebih redup daripada bongkahan bibir supaya bagian dalam tebing
				# tetap mundur -- tapi tetap harus TERLIHAT. Versi sebelumnya
				# hampir sewarna isian tebingnya sendiri, jadi sia-sia digambar.
				dalam.modulate = Color(0.44, 0.41, 0.31, acak.randf_range(0.75, 1.0))
				_air.add_child(dalam)


## Menyetel skala sprite berdasarkan LEBAR YANG DIINGINKAN, bukan angka skala
## mentah. Semua tekstur Kenney kebetulan 128 px, tapi mengandalkan itu berarti
## satu tekstur berukuran lain suatu saat akan merusak seluruh tata letak diam-diam.
func _ukur(sprite: Sprite2D, lebar_px: float) -> void:
	var asli := sprite.texture.get_width()
	if asli <= 0:
		return
	sprite.scale = Vector2.ONE * (lebar_px / float(asli))


## Rumput air dan batu kecil di tepian.
##
## Bukan hiasan kosong: petak tepian yang polos tetap terbaca sebagai kotak
## kosong, dan mata butuh sesuatu yang tidak sejajar kisi untuk berhenti melihat
## kisinya. Semuanya di tepian saja -- lorong dibiarkan bersih supaya alur air
## dan baloknya tidak pernah tertutup apa pun.
func _hiasi_tepian() -> void:
	for y in _baris:
		for x in _kolom:
			var p := Vector2i(x, y)
			if _jenis(p) != JENIS_TEPIAN:
				continue
			var acak := RandomNumberGenerator.new()
			acak.seed = hash(p) + 7717
			if acak.randf() > 0.62:
				continue

			var hias := Sprite2D.new()
			var rumput := acak.randf() < 0.6
			hias.texture = TEKSTUR_RUMPUT if rumput else TEKSTUR_BATU
			hias.position = tengah_petak(p) + Vector2(
				acak.randf_range(-0.3, 0.3), acak.randf_range(-0.28, 0.3)
			) * lebar_petak
			_ukur(hias, acak.randf_range(0.34, 0.58) * lebar_petak)
			hias.rotation = acak.randf_range(-0.35, 0.35)
			hias.modulate = Color(0.62, 0.78, 0.66, 0.55) if rumput \
				else Color(0.5, 0.48, 0.4, 0.6)
			hias.flip_h = acak.randf() < 0.5
			_air.add_child(hias)


func _pasang_balok(p: Vector2i, besar: bool) -> void:
	var balok := StaticBody2D.new()
	balok.set_script(BALOK)
	balok.z_index = Z_BALOK
	balok.position = tengah_petak(p)
	add_child(balok)
	balok.pasang(lebar_petak, besar)
	_balok[p] = balok


func _pasang_mulut(p: Vector2i, teks: String, warna: Color) -> void:
	var label := Label.new()
	label.text = teks
	label.size = Vector2(300.0, 30.0)
	label.position = tengah_petak(p) + Vector2(-150.0, -lebar_petak * 0.5 - 40.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", warna)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.07, 0.95))
	label.add_theme_constant_override("outline_size", 9)
	add_child(label)


func _taruh_ikan() -> void:
	# Ikan lahir di TEPIAN sebelah hilir, bukan di dalam lorong -- dan bukan di
	# koordinat yang ditulis mati, supaya denah papan boleh diubah tanpa harus
	# memindahkan ikannya secara manual.
	var titik: Array[Vector2i] = []
	for x in _kolom:
		for y in _baris:
			var p := Vector2i(x, y)
			if _isi[y][x] == Isi.KOSONG and not _lorong[y][x]:
				titik.append(p)
		if titik.size() >= 2:
			break
	for i in _fish.size():
		if i < titik.size():
			_fish[i].global_position = tengah_petak(titik[i])


# --- Dorongan ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _phase != Phase.BERMAIN:
		return

	_arahkan_pendamping(delta)

	for p in _balok.keys():
		var balok = _balok[p]
		if not is_instance_valid(balok) or balok.sibuk:
			continue
		_urus_satu_balok(p, balok, delta)


# --- Wader B, si pendamping -------------------------------------------------

## Ke mana pendamping harus berenang frame ini.
##
## Cuma dua keadaan, dan urutannya penting:
##   1. Pemain sedang menempel di muka balok BESAR -> merapat ke muka yang sama.
##   2. Selain itu -> ikut di belakang pemain.
##
## Balok kecil sengaja tidak dibantu. Kalau pendamping ikut merapat ke setiap
## balok, dia akan sering berdiri tepat di petak yang pemain butuhkan
## berikutnya -- dan teman yang menghalangi jalan lebih menjengkelkan daripada
## teman yang menunggu.
func _arahkan_pendamping(delta: float) -> void:
	var pemain: Node2D = _fish[0]
	var teman: Node2D = _fish[1]
	if not is_instance_valid(pemain) or not is_instance_valid(teman):
		return

	_petak_dibantu = Vector2i(-1, -1)
	var slot := _slot_bantuan(pemain)
	var titik: Vector2 = slot if slot.is_finite() else _titik_ikut(pemain)
	teman.tujuan_npc = _lewat_kisi(teman.global_position, titik)
	_jaga_pendamping_tidak_macet(pemain, teman, delta)


## Menerjemahkan "aku mau ke sana" jadi "petak berikutnya yang harus kudatangi".
##
## Berenang lurus ke tujuan TIDAK cukup di papan Sokoban. Balok dan batu
## membentuk lorong, dan ikan yang mengarah lurus akan menempel di sisi balok
## lalu berhenti di situ selamanya -- pemain lalu menunggu teman yang tidak akan
## pernah datang. Jadi jalurnya dicari di atas kisi dulu.
func _lewat_kisi(dari_pos: Vector2, tujuan_pos: Vector2) -> Vector2:
	var dari := _petak_dari(dari_pos)
	var tujuan := _petak_dari(tujuan_pos)
	# Sudah sepetak dengan tujuannya: langsung ke titik persisnya, supaya
	# pendamping berhenti di posisi mendorong yang tepat, bukan di tengah petak.
	if dari == tujuan:
		return tujuan_pos
	return tengah_petak(_langkah_menuju(dari, tujuan))


func _petak_dari(pos: Vector2) -> Vector2i:
	var relatif := (pos - titik_awal) / lebar_petak
	return Vector2i(
		clampi(int(floor(relatif.x)), 0, _kolom - 1),
		clampi(int(floor(relatif.y)), 0, _baris - 1)
	)


func _bisa_dilewati(p: Vector2i) -> bool:
	return _di_dalam(p) and _isi[p.y][p.x] == Isi.KOSONG


## Petak pertama pada jalur terpendek dari `dari` ke `tujuan`.
##
## Pencarian lebar (BFS) biasa. Papannya cuma 50 petak dan dihitung ulang tiap
## frame -- itu jauh lebih murah daripada menyimpan jalur lalu harus ingat
## membatalkannya setiap kali ada balok bergeser.
func _langkah_menuju(dari: Vector2i, tujuan: Vector2i) -> Vector2i:
	if not _bisa_dilewati(dari) or not _bisa_dilewati(tujuan):
		return dari

	var asal := {dari: dari}
	var antre: Array[Vector2i] = [dari]

	while not antre.is_empty():
		var p: Vector2i = antre.pop_front()
		if p == tujuan:
			# Telusuri balik sampai petak yang tepat sesudah titik berangkat.
			var langkah := p
			while asal[langkah] != dari:
				langkah = asal[langkah]
			return langkah
		for arah in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + arah
			if asal.has(q) or not _bisa_dilewati(q):
				continue
			asal[q] = p
			antre.append(q)

	# Tidak ada jalur -- misalnya tujuannya terkurung balok. Diam di tempat
	# lebih baik daripada menggasak dinding; jaring pengaman yang mengurus
	# sisanya kalau keadaan ini berlangsung lama.
	return dari


## Titik di zona dorong balok besar yang sedang ditekan pemain, atau Vector2.INF
## kalau pemain memang tidak sedang menekan balok besar mana pun.
func _slot_bantuan(pemain: Node2D) -> Vector2:
	for p in _balok.keys():
		var balok = _balok[p]
		if not is_instance_valid(balok) or not balok.besar or balok.sibuk:
			continue
		for arah in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not _di_zona(pemain, p, arah):
				continue
			if not _boleh_pindah(p, arah):
				continue
			var d := Vector2(arah)
			var pusat_zona: Vector2 = tengah_petak(p) - d * lebar_petak * 0.8
			# Pendamping berdiri di SEBERANG pemain, bukan menumpuk di atasnya.
			# Dua ikan yang bertindihan persis membuat pemain kehilangan jejak
			# ikan mana yang dia pegang -- itu keluhan nyata dari versi lama.
			var tegak := Vector2(-d.y, d.x)
			var sisi := signf(tegak.dot(pemain.global_position - pusat_zona))
			if is_zero_approx(sisi):
				sisi = 1.0
			_petak_dibantu = p
			return pusat_zona - tegak * sisi * lebar_petak * 0.3
	return Vector2.INF


## Apakah ikan berada di zona dorong balok p untuk arah tertentu -- ukuran yang
## sama persis dipakai _ikan_yang_mendorong(), supaya pendamping tidak pernah
## berhenti di tempat yang ternyata tidak dihitung.
func _di_zona(ikan: Node2D, p: Vector2i, arah: Vector2i) -> bool:
	var d := Vector2(arah)
	var selisih: Vector2 = ikan.global_position - tengah_petak(p)
	var mundur := -selisih.dot(d)
	var samping := absf(selisih.dot(Vector2(-d.y, d.x)))
	return mundur >= lebar_petak * 0.3 and mundur <= lebar_petak * 1.2 \
		and samping <= lebar_petak * 0.5


## Berenang mengekor, sedikit di belakang dan agak ke samping.
func _titik_ikut(pemain: Node2D) -> Vector2:
	var arah: Vector2 = pemain.arah_niat
	if arah.is_zero_approx():
		arah = Vector2.RIGHT if pemain.velocity.x >= 0.0 else Vector2.LEFT
	arah = arah.normalized()
	return pemain.global_position - arah * lebar_petak * 0.55 \
		+ Vector2(-arah.y, arah.x) * lebar_petak * 0.22


## Jaring pengaman: kalau pendamping tersangkut lama dan jauh, dia menyusul.
##
## Papan Sokoban penuh sudut, dan ikan yang berenang lurus ke tujuannya bisa
## terjepit di sudut dalam tanpa pernah lepas. Mencari jalur sungguhan untuk
## papan sekecil ini berlebihan; yang penting pemain tidak pernah terkunci
## gara-gara temannya nyangkut di seberang peta.
func _jaga_pendamping_tidak_macet(pemain: Node2D, teman: Node2D, delta: float) -> void:
	var jarak: float = teman.global_position.distance_to(teman.tujuan_npc)
	if jarak < lebar_petak * 0.5 or teman.velocity.length() > 40.0:
		_teman_macet = 0.0
		return

	_teman_macet += delta
	if _teman_macet < 3.5:
		return
	_teman_macet = 0.0
	teman.global_position = pemain.global_position - Vector2(lebar_petak * 0.4, 0.0)
	teman.velocity = Vector2.ZERO
	AudioManager.play("switch_fish", -6.0, 1.25)


## Menentukan apakah balok di petak p sedang didorong, ke mana, dan oleh berapa
## ikan -- lalu memajukan muatannya.
func _urus_satu_balok(p: Vector2i, balok, delta: float) -> void:
	var arah_terbaik := Vector2i.ZERO
	var jumlah_terbaik := 0

	# Keempat arah diperiksa terpisah, bukan dicari dari rata-rata gerak ikan.
	# Dengan rata-rata, dua ikan yang mendorong ke arah BERBEDA akan menghasilkan
	# satu arah gabungan yang tidak diniatkan siapa pun.
	for arah in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var jumlah := _ikan_yang_mendorong(p, arah)
		if jumlah > jumlah_terbaik:
			jumlah_terbaik = jumlah
			arah_terbaik = arah

	var perlu := 2 if balok.besar else 1
	var cukup := jumlah_terbaik >= perlu and _boleh_pindah(p, arah_terbaik)
	balok.sorot_muka(arah_terbaik, cukup)

	if not cukup:
		_muatan[p] = 0.0
		return

	_muatan[p] = float(_muatan.get(p, 0.0)) + delta
	if _muatan[p] < waktu_dorong:
		return

	_muatan[p] = 0.0
	_pindahkan(p, arah_terbaik)


## Berapa ikan yang sedang menekan balok di petak p ke arah tertentu.
##
## Aturannya berbeda untuk ikan yang dipegang pemain dan yang ditinggal, dan
## perbedaan itu perlu karena pemain cuma bisa memegang satu ikan:
##
##   dipegang  -- harus berada di belakang balok DAN menahan tombol ke arah itu.
##   ditinggal -- cukup berada di belakang balok. Dia mengganjal, dan mengganjal
##                tidak butuh gerakan.
##
## Yang dibaca dari ikan aktif adalah arah_niat, BUKAN velocity. Begitu ikan
## menempel ke balok, tabrakan menghapus komponen kecepatan yang menuju balok --
## justru komponen yang berarti "aku sedang mendorong". Membaca velocity di sini
## akan membuat dorongan berhenti terbaca persis saat pemain menekan paling kuat.
func _ikan_yang_mendorong(p: Vector2i, arah: Vector2i) -> int:
	var pusat := tengah_petak(p)
	var d := Vector2(arah)
	var jumlah := 0

	for ikan in _fish:
		if not is_instance_valid(ikan):
			continue
		var selisih: Vector2 = ikan.global_position - pusat
		# Sejauh apa ikan di belakang balok, dan berapa melencengnya dari sumbu.
		var mundur := -selisih.dot(d)
		var samping := absf(selisih.dot(Vector2(-d.y, d.x)))
		if mundur < lebar_petak * 0.3 or mundur > lebar_petak * 1.2:
			continue
		if samping > lebar_petak * 0.5:
			continue
		if ikan.is_active:
			var niat: Vector2 = ikan.arah_niat
			if niat.length() < 0.3 or niat.normalized().dot(d) < 0.55:
				continue
		elif p != _petak_dibantu:
			# Pendamping cuma dihitung untuk balok yang SENGAJA dia bantu.
			#
			# Tanpa syarat ini dia mendorong apa pun yang kebetulan dilewatinya:
			# berenang menyusul pemain lewat sisi sebuah balok kecil sudah cukup
			# untuk menggesernya. Di Sokoban satu dorongan tak diniatkan bisa
			# mematikan papan -- dan pemain akan menyalahkan dirinya sendiri
			# untuk langkah yang bukan dia yang lakukan.
			continue
		jumlah += 1
	return jumlah


func _boleh_pindah(p: Vector2i, arah: Vector2i) -> bool:
	if arah == Vector2i.ZERO:
		return false
	var tujuan := p + arah
	if not _di_dalam(tujuan):
		return false
	if _isi[tujuan.y][tujuan.x] != Isi.KOSONG:
		return false
	# Mulut sungai tidak boleh disumbat balok: kalau boleh, pemain bisa membuat
	# papan yang mustahil diselesaikan tanpa sadar sudah melakukannya.
	if tujuan == _keluar or tujuan == _masuk:
		return false
	# Petak tujuan tidak boleh sedang ditempati ikan -- balok yang menindih ikan
	# bisa menjepitnya di antara dua dinding.
	for ikan in _fish:
		if is_instance_valid(ikan) and tengah_petak(tujuan).distance_to(ikan.global_position) < lebar_petak * 0.42:
			return false
	return true


func _pindahkan(p: Vector2i, arah: Vector2i) -> void:
	var tujuan := p + arah
	var balok = _balok[p]

	_isi[tujuan.y][tujuan.x] = _isi[p.y][p.x]
	_isi[p.y][p.x] = Isi.KOSONG
	_balok.erase(p)
	_muatan.erase(p)
	_balok[tujuan] = balok

	balok.geser_ke(tengah_petak(tujuan), lama_geser)
	_dorongan += 1
	_camera.shake(7.0)
	_hitung_air(true)


# --- Aliran air -------------------------------------------------------------

## Sebar air dari mulut hulu ke segala petak kosong yang tersambung.
##
## Dihitung ulang dari NOL tiap kali ada balok pindah, bukan ditambal dari
## keadaan sebelumnya. Papannya cuma 50 petak, jadi menghitung ulang seluruhnya
## praktis gratis -- dan penambalan bertahap adalah tempat bug bersembunyi,
## karena air yang seharusnya SURUT saat jalan tertutup lagi hampir selalu
## terlupakan.
func _hitung_air(dari_dorongan: bool) -> void:
	var terjangkau := {}
	var antre: Array[Vector2i] = [_masuk]
	terjangkau[_masuk] = true

	while not antre.is_empty():
		var p: Vector2i = antre.pop_front()
		for arah in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + arah
			if not _di_dalam(q) or terjangkau.has(q):
				continue
			if _isi[q.y][q.x] != Isi.KOSONG or not _lorong[q.y][q.x]:
				continue
			terjangkau[q] = true
			antre.append(q)

	var petak_baru := 0
	for p in _petak_air.keys():
		var basah: bool = terjangkau.has(p)
		var genangan: Polygon2D = _petak_air[p]
		var target := 0.5 if basah else 0.0
		if not is_equal_approx(genangan.color.a, target):
			create_tween().tween_property(genangan, "color:a", target, 0.45)
		if basah and not _sudah_terairi.has(p):
			_sudah_terairi[p] = true
			petak_baru += 1

	if dari_dorongan and petak_baru > 0:
		GameState.add_score(petak_baru * skor_per_petak_air)
		AudioManager.play("river_flows", -4.0, 1.15, 0.05)
		_hud.show_banner("Airnya maju %d petak  (+%d)" %
			[petak_baru, petak_baru * skor_per_petak_air], 1.8)

	_hud.set_progress_fine(float(_sudah_terairi.size()), maxi(_petak_air.size(), 1))
	_hud.set_progress(_dorongan, DORONGAN_OPTIMAL)

	if terjangkau.has(_keluar) and _phase == Phase.BERMAIN:
		_selesaikan()


# --- Kendali ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.TERKUNCI:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			SceneRouter.go_to_chapter_select()
			get_viewport().set_input_as_handled()
		return

	if _menunggu_lanjut:
		if event.is_action_pressed("ui_accept"):
			_menunggu_lanjut = false
			SceneRouter.go_to(ending_scene)
			get_viewport().set_input_as_handled()
		return

	if _phase != Phase.BERMAIN:
		return

	# R mengulang papan dari awal. Sokoban WAJIB punya ini: satu dorongan yang
	# salah bisa membuat papan mustahil diselesaikan, dan pemain yang terjebak
	# tanpa jalan keluar akan menyimpulkan game-nya rusak.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		SceneRouter.restart_chapter()
		get_viewport().set_input_as_handled()
		return


func _set_active(index: int) -> void:
	_active_index = index
	for i in _fish.size():
		_fish[i].set_active(i == index)
	_hud.set_active_fish(_fish[index].display_name, _fish[index].marker_color,
		_fish[1].display_name)


# --- Selesai ----------------------------------------------------------------

func _selesaikan() -> void:
	_phase = Phase.SELESAI
	_pause.enabled = false

	var kelebihan := maxi(_dorongan - DORONGAN_OPTIMAL, 0)
	var bonus := maxi(bonus_langkah - kelebihan * denda_per_langkah, 0)
	var sempurna := kelebihan == 0
	GameState.add_score(skor_selesai + bonus)

	var kabar := "Airnya tembus!  %d dorongan  (+%d)" % [_dorongan, skor_selesai + bonus]
	if sempurna:
		kabar = "RENCANA SEMPURNA -- %d dorongan, tidak ada yang terbuang!" % _dorongan
	_hud.show_banner(kabar, ending_delay)
	AudioManager.play("river_flows", 2.0, 1.0, 0.0)
	_camera.shake(20.0)

	await get_tree().create_timer(ending_delay).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return

	GameState.last_perfect = sempurna
	var rekor_baru := GameState.record_score(3, GameState.score)
	GameState.mark_map_completed(3)

	var layar: CanvasLayer = MISI_SELESAI_SCENE.instantiate()
	add_child(layar)
	layar.tampilkan(3, GameState.score, rekor_baru, sempurna, "Enter  lihat sungainya")
	_menunggu_lanjut = true
