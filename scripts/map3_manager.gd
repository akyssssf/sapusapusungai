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

## Denah papan.
##   #  batu, tidak bisa didorong dan menahan air
##   .  air bisa lewat
##   k  balok kecil, satu ikan cukup
##   B  balok besar, butuh dua ikan
##   I  mulut masuk air (hulu)
##   O  mulut keluar air (hilir) -- air harus sampai sini
##
## Lorong tengah adalah SATU-SATUNYA jalan air; kantong di atas dan bawah buntu,
## jadi mendorong balok ke sana benar-benar menyingkirkannya. Kolom 3 sengaja
## tidak punya kantong: balok di situ harus digeser dulu menyamping ke kolom 2
## sebelum bisa dikeluarkan. Itu satu-satunya "aha" yang harus ditemukan sendiri.
const PETA := [
	"##.##.####",
	"##.##.#..#",
	"O..k.B.k.I",
	"##.##.#..#",
	"##.##.####",
]

## Dorongan paling sedikit yang bisa menyelesaikan papan di atas:
## k(2,7) keluar, B(2,5) keluar, k(2,3) geser kiri lalu keluar = 4.
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
var _balok: Dictionary = {}          # Vector2i -> node balok
var _masuk: Vector2i = Vector2i.ZERO
var _keluar: Vector2i = Vector2i.ZERO
var _baris: int = 0
var _kolom: int = 0

var _air: Node2D = null
var _petak_air: Dictionary = {}      # Vector2i -> Polygon2D
var _sudah_terairi: Dictionary = {}
var _dorongan: int = 0
var _muatan: Dictionary = {}         # Vector2i -> float, lama ditekan
var _menunggu_lanjut: bool = false


func _ready() -> void:
	GameState.begin_run(3, scene_file_path)
	_fish = [_fish_a, _fish_b]

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
	add_child(_air)
	move_child(_air, 0)

	var batu_induk := StaticBody2D.new()
	batu_induk.collision_layer = 16
	batu_induk.collision_mask = 0
	add_child(batu_induk)

	for y in _baris:
		var baris_isi: Array = []
		var teks := String(PETA[y])
		for x in _kolom:
			var huruf := teks[x]
			var p := Vector2i(x, y)
			var isi := Isi.KOSONG

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
			_pasang_lantai(p, isi == Isi.BATU)
		_isi.append(baris_isi)

	_pasang_mulut(_masuk, "HULU", Color(0.55, 0.85, 0.98))
	_pasang_mulut(_keluar, "MULUT SUNGAI", Color(0.62, 0.93, 0.75))


func _pasang_batu(induk: StaticBody2D, p: Vector2i) -> void:
	var bentuk := RectangleShape2D.new()
	bentuk.size = Vector2.ONE * lebar_petak
	var tabrakan := CollisionShape2D.new()
	tabrakan.shape = bentuk
	tabrakan.position = tengah_petak(p)
	induk.add_child(tabrakan)


## Lantai petak digambar terpisah dari isinya supaya papannya selalu terbaca
## sebagai KISI, bahkan di petak yang kosong. Tanpa kisi, pemain tidak punya
## acuan seberapa jauh satu dorongan akan memindahkan balok.
func _pasang_lantai(p: Vector2i, batu: bool) -> void:
	var s := lebar_petak * 0.5
	var tengah := tengah_petak(p)

	var kotak := Polygon2D.new()
	kotak.polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s),
	])
	kotak.position = tengah
	kotak.color = Color(0.16, 0.15, 0.11) if batu else Color(0.09, 0.17, 0.2)
	_air.add_child(kotak)

	if batu:
		var tepi := Line2D.new()
		tepi.points = kotak.polygon + PackedVector2Array([kotak.polygon[0]])
		tepi.width = 4.0
		tepi.default_color = Color(0.26, 0.24, 0.17)
		tepi.position = tengah
		_air.add_child(tepi)
		return

	# Petak yang bisa dilalui air diberi kisi tipis; petak batu tidak, supaya
	# mata langsung memisahkan "ruang" dari "dinding".
	var kisi := Line2D.new()
	kisi.points = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s), Vector2(-s, -s),
	])
	kisi.width = 2.0
	kisi.default_color = Color(1, 1, 1, 0.07)
	kisi.position = tengah
	_air.add_child(kisi)

	# Lapisan air yang menyala saat petak ini akhirnya kebagian aliran.
	var genangan := Polygon2D.new()
	genangan.polygon = kotak.polygon
	genangan.position = tengah
	genangan.color = Color(0.35, 0.72, 0.85, 0.0)
	_air.add_child(genangan)
	_petak_air[p] = genangan


func _pasang_balok(p: Vector2i, besar: bool) -> void:
	var balok := StaticBody2D.new()
	balok.set_script(BALOK)
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
	# Kedua ikan lahir di lorong sebelah hilir, di petak kosong pertama yang
	# ketemu dari kiri -- bukan di koordinat yang ditulis mati, supaya denah
	# papan boleh diubah tanpa memindahkan ikannya secara manual.
	var titik: Array[Vector2i] = []
	for x in _kolom:
		var p := Vector2i(x, int(_baris / 2))
		if _isi[p.y][p.x] == Isi.KOSONG and p != _keluar:
			titik.append(p)
		if titik.size() >= 2:
			break
	for i in _fish.size():
		if i < titik.size():
			_fish[i].global_position = tengah_petak(titik[i]) + Vector2(0.0, -22.0 + 44.0 * float(i))


# --- Dorongan ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _phase != Phase.BERMAIN:
		return

	for p in _balok.keys():
		var balok = _balok[p]
		if not is_instance_valid(balok) or balok.sibuk:
			continue
		_urus_satu_balok(p, balok, delta)


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
			if _isi[q.y][q.x] != Isi.KOSONG:
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

	if event.is_action_pressed("switch_fish"):
		_set_active(1 - _active_index)
		return

	# R mengulang papan dari awal. Sokoban WAJIB punya ini: satu dorongan yang
	# salah bisa membuat papan mustahil diselesaikan, dan pemain yang terjebak
	# tanpa jalan keluar akan menyimpulkan game-nya rusak.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		SceneRouter.restart_chapter()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_by_point(get_global_mouse_position())


func _try_select_by_point(point: Vector2) -> void:
	var best := -1
	var best_distance := 110.0
	for i in _fish.size():
		var distance: float = point.distance_to(_fish[i].global_position)
		if distance < best_distance:
			best_distance = distance
			best = i
	if best >= 0:
		_set_active(best)


func _set_active(index: int) -> void:
	if index == _active_index and _fish[index].is_active:
		return
	_active_index = index
	for i in _fish.size():
		_fish[i].set_active(i == index)
	_hud.set_active_fish(_fish[index].display_name, _fish[index].marker_color)
	AudioManager.play("switch_fish", -3.0, 1.0 if index == 0 else 1.12)


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
