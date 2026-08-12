extends Node2D
## Wasit Map 3 -- Kali Jeroan Madiun.
##
## Sengaja TIDAK memakai map_manager.gd. Map 1 dan 2 punya babak berburu,
## ukuran ikan, nyawa, dan bos; Map 3 tidak punya satu pun dari itu. Memaksakan
## keduanya berbagi satu file akan menghasilkan wasit yang setengah isinya
## dimatikan lewat properti -- dan file seperti itu selalu berakhir jadi sarang
## bug, karena tidak ada yang ingat cabang mana yang masih hidup.
##
## Tugas file ini cuma lima:
##   1. Memeriksa gerbang progres (Map 2 harus selesai).
##   2. Menyiapkan dua ikan dan menentukan siapa yang sedang dikendalikan.
##   3. Menghitung berapa sumbatan yang sudah terbuka.
##   4. MENJADI HAKIM URUTAN -- menentukan sumbatan mana yang kalau dibuka
##      sekarang akan melepas arus deras, dan menjalankan akibatnya.
##   5. Memanggil layar ending saat semuanya terbuka.
##
## Tugas nomor 4 itu isi puzzlenya, dan seluruh aturannya cuma satu kalimat:
##
##     Sebuah sumbatan melepas ARUS DERAS kalau tidak ada lagi sumbatan lain
##     yang masih tertutup di HILIRNYA (sebelah kirinya).
##
## Dari satu kalimat itu, urutan yang benar muncul sendiri: kerjakan dari hulu,
## sisakan yang paling hilir untuk terakhir -- dan yang terakhir itu justru
## menjadi hadiahnya, karena saat itu sudah tidak ada pekerjaan yang bisa
## dirusak arusnya. Tidak ada daftar urutan yang ditulis mati di mana pun;
## kalau sumbatannya digeser atau ditambah, jawabannya ikut berubah sendiri.

enum Phase { BERMAIN, SELESAI, TERKUNCI }

@export_group("Sungai")
@export var world_size: Vector2 = Vector2(1600, 900)
## Kotak air tempat ikan boleh berenang. Tebing atas dan bawah punya tabrakan
## sendiri; kotak ini cuma pengaman terakhir supaya ikan tidak lolos keluar peta.
@export var water_margin_top: float = 90.0
@export var water_margin_bottom: float = 90.0

@export_group("Gerbang progres")
@export var requires_map2: bool = true
## Melewati jaring pengaman di atas, supaya scene ini bisa dijalankan langsung
## dari editor. Aman dibiarkan menyala: pemain tidak pernah sampai ke sini
## kecuali lewat layar pilih bab, yang punya penguncian sendiri.
@export var bypass_progress_gate: bool = true

@export_group("Arus deras")
## Kecepatan dorongan saat kolam yang tertahan menghambur, piksel per detik.
## Sengaja di bawah kecepatan renang ikan (300): pemain harus MASIH bisa
## bergerak melawannya, cuma jadi lambat dan susah berhenti di titik yang tepat.
## Arus yang lebih kencang daripada ikan bukan tantangan, cuma kendali yang
## diambil paksa.
@export var kekuatan_arus: float = 190.0
## Berapa lama arusnya mereda. Kolam yang tertahan memang habis; kesalahan
## urutan harus MAHAL, bukan permanen.
@export var lama_arus: float = 11.0
## Hadiah kalau pemain menamatkan bab tanpa sekali pun melepas arus deras
## sebelum waktunya. Inilah yang dikejar pemain yang mengulang.
@export var bonus_rencana_sempurna: int = 600

@export_group("Skor")
## Nilai dasar tiap sumbatan yang berhasil dibuka.
@export var score_per_obstacle: int = 500
## Bonus tambahan maksimum tiap sumbatan, menyusut seiring waktu yang terpakai.
##
## Kenapa waktu yang dipakai sebagai ukuran, padahal bab ini bukan lomba lari?
## Karena di bab ini waktu ADALAH ukuran koordinasi. Pemain yang salah membaca
## aturannya akan bolak-balik menggerakkan satu ikan, membiarkan progres
## menyusut, lalu mengulang -- dan semua itu muncul sebagai detik yang terbuang.
## Tidak ada nyawa dan tidak ada sampah di sini, jadi tidak ada lagi yang bisa
## diukur dengan jujur selain berapa lama dua ikan itu baru sampai bersamaan.
@export var max_efficiency_bonus: int = 500
## Berapa detik sampai bonus efisiensi habis sama sekali. Angkanya sengaja
## longgar: pemain yang baru belajar aturannya tetap boleh dapat sebagian.
@export var bonus_fade_seconds: float = 24.0

@export_group("Ending")
@export_file("*.tscn") var ending_scene: String = "res://scenes/ui/ending_river.tscn"
## Jeda sesudah sumbatan terakhir terbuka, supaya pemain sempat melihat
## hasilnya sebelum layar berganti.
@export var ending_delay: float = 2.2

@onready var _fish_a: CharacterBody2D = $FishA
@onready var _fish_b: CharacterBody2D = $FishB
@onready var _camera: Camera2D = $DuoCamera
@onready var _hud: CanvasLayer = $HUD
@onready var _obstacles_root: Node2D = $Obstacles
@onready var _pause: CanvasLayer = $PauseMenu

var _fish: Array[Node2D] = []
var _active_index: int = 0
var _obstacles: Array[Node] = []
var _total_obstacles: int = 0
var _cleared: int = 0
var _phase: int = Phase.BERMAIN
## Lama waktu sejak sumbatan terakhir terbuka. Ditambah di _process(), bukan
## dibaca dari Time.get_ticks_msec(), justru supaya waktu selama permainan
## DIJEDA tidak ikut terhitung -- node ini berhenti diproses saat dijeda.
var _segment_time: float = 0.0

## Sisa waktu arus deras yang sedang berjalan, dan titik lepasnya.
var _arus_sisa: float = 0.0
var _arus_dari_x: float = 0.0
## Pernah melepas arus deras padahal masih ada pekerjaan tersisa. Sekali true,
## bonus rencana sempurna hangus untuk ronde ini.
var _pernah_salah_urutan: bool = false
## Layar MISI SELESAI sudah tampil dan sedang menunggu pemain menekan tombol.
var _menunggu_lanjut: bool = false

const MISI_SELESAI_SCENE := preload("res://scenes/ui/mission_complete.tscn")


func _ready() -> void:
	GameState.begin_run(3, scene_file_path)
	_fish = [_fish_a, _fish_b]

	var water := Rect2(
		Vector2(0.0, water_margin_top),
		Vector2(world_size.x, world_size.y - water_margin_top - water_margin_bottom)
	)
	for fish in _fish:
		fish.swim_bounds = water

	if not _progress_gate_passed():
		_phase = Phase.TERKUNCI
		_freeze_all()
		_pause.enabled = false
		_hud.show_result("BAB INI MASIH TERKUNCI",
			"Selesaikan Sungai Ciliwung dulu  -  tekan Enter untuk pilih bab")
		return

	_setup_camera()
	_setup_obstacles()
	_set_active(0)

	_hud.set_progress(0, _total_obstacles)
	_hud.show_banner("Sungai sudah bersih, tapi airnya tetap tertahan.\nSatu ikan MENGGANJAL dari sisi seberang, satunya MENDORONG terus.", 5.5)
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 1.8)


## Jaring pengaman, bukan gerbang utama -- lihat penjelasan yang sama di
## map_manager.gd. Pintu sesungguhnya ada di layar pilih bab.
func _progress_gate_passed() -> bool:
	if not requires_map2 or bypass_progress_gate:
		return true
	return GameState.is_unlocked(3)


func _setup_camera() -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(world_size.x)
	_camera.limit_bottom = int(world_size.y)


func _setup_obstacles() -> void:
	for child in _obstacles_root.get_children():
		if not child.is_in_group("obstacle"):
			continue
		_obstacles.append(child)
		child.setup(_fish)
		# Sumbatan tidak tahu dirinya yang ke berapa, dan memang tidak perlu
		# tahu. Yang dioper cuma dirinya sendiri, dan wasit yang mencocokkan.
		child.cleared.connect(_on_obstacle_cleared.bind(child))
	# Diurutkan dari HILIR ke HULU sekali di awal. Dipakai terus setelah ini,
	# jadi urusan "mana yang lebih hilir" tidak pernah dihitung ulang di tengah
	# permainan -- dan tidak ada tempat kedua yang bisa salah mengurutkannya.
	_obstacles.sort_custom(func(a, b): return a.position.x < b.position.x)
	_total_obstacles = _obstacles.size()
	if _total_obstacles == 0:
		push_warning("map3_manager: tidak ada sumbatan di node Obstacles.")
	_segarkan_ramalan()


## Memberi tahu tiap sumbatan yang masih tertutup: kalau kamu dibuka SEKARANG,
## apakah airmu akan ditahan sesuatu di hilir?
##
## Jawabannya cuma benar untuk SATU sumbatan pada satu waktu -- yang paling
## hilir di antara yang tersisa. Sisanya selalu aman, karena dia sendiri yang
## menahan air mereka.
func _segarkan_ramalan() -> void:
	# Sumbatan yang sudah benar-benar dihapus Godot DIBUANG dari daftar di sini.
	#
	# Ini bukan kerapian, ini perbaikan crash. Sumbatan yang pecah baru
	# di-queue_free() sekitar sedetik setelah terbuka, jadi daftar ini sempat
	# memegang acuan ke objek mati. Mengoper acuan mati itu ke fungsi yang
	# parameternya bertipe Node membuat Godot menolaknya DI BATAS PEMANGGILAN --
	# sebelum baris is_instance_valid() di dalam fungsinya sempat jalan. Jadi
	# penjaga di dalam fungsi tidak akan pernah cukup; yang mati harus tidak
	# pernah dioper sejak awal.
	var hidup: Array[Node] = []
	for o in _obstacles:
		if is_instance_valid(o):
			hidup.append(o)
	_obstacles = hidup

	var paling_hilir: Node = null
	for o in _obstacles:
		if _masih_tertutup(o):
			paling_hilir = o
			break
	for o in _obstacles:
		if _masih_tertutup(o):
			o.set_akan_deras(o == paling_hilir)


func _masih_tertutup(o: Node) -> bool:
	return is_instance_valid(o) and not o.is_queued_for_deletion() and not o.akan_pecah()


func _process(delta: float) -> void:
	_perbarui_arus(delta)
	if _phase != Phase.BERMAIN:
		return
	_segment_time += delta
	# Bar aliran mengikuti sumbatan yang sedang didorong, bukan cuma yang sudah
	# selesai. Dengan begitu pemain melihat usahanya terbayar SELAMA menahan,
	# bukan baru setelah berhasil.
	_hud.set_progress_fine(float(_cleared) + _active_charge(), _total_obstacles)


# --- Arus deras -------------------------------------------------------------

func _perbarui_arus(delta: float) -> void:
	if _arus_sisa <= 0.0:
		return
	_arus_sisa = maxf(_arus_sisa - delta, 0.0)

	# Meredanya dibuat melengkung (kuadrat), bukan lurus. Arus yang mereda lurus
	# terasa seperti keran yang diputar pelan-pelan oleh seseorang; kolam yang
	# habis isinya memang deras di awal lalu cepat kehilangan tenaga.
	var sisa := _arus_sisa / maxf(lama_arus, 0.01)
	var kuat := kekuatan_arus * sisa * sisa

	for ikan in _fish:
		if not is_instance_valid(ikan):
			continue
		# Cuma ikan yang berada di HULU titik lepasnya yang tersedot. Air yang
		# sudah lewat lubang tidak menarik apa pun lagi ke belakang.
		if ikan.global_position.x <= _arus_dari_x:
			ikan.arus = Vector2.ZERO
			continue
		ikan.arus = Vector2.LEFT * kuat

	if _arus_sisa <= 0.0:
		for ikan in _fish:
			if is_instance_valid(ikan):
				ikan.arus = Vector2.ZERO
		if _phase == Phase.BERMAIN:
			_hud.show_banner("Arusnya reda. Kolamnya sudah habis.", 2.2)


## Melepas arus dari sebuah titik. rusak = masih ada pekerjaan yang bisa
## diganggu; kalau tidak, ini justru sungai yang akhirnya jalan.
func _lepas_arus(dari_x: float, merusak: bool) -> void:
	_arus_sisa = lama_arus
	_arus_dari_x = dari_x
	_camera.shake(26.0)
	AudioManager.play("boss_suck", -1.0, 0.62, 0.03)
	if not merusak:
		return

	_pernah_salah_urutan = true
	# Banner ini mengubah kegagalan jadi pelajaran. Pemain yang cuma melihat
	# ikannya tiba-tiba tersapu akan menyalahkan kontrolnya; pemain yang tahu
	# SEBABNYA akan mengulang dengan rencana lain -- dan itu bedanya puzzle
	# dengan jebakan.
	_hud.show_banner(
		"Sumbatan paling hilir dibuka duluan!\nSeluruh kolam yang tertahan menghambur.", 3.6)


## Progres sumbatan yang sedang dikerjakan, 0.0 sampai 1.0.
func _active_charge() -> float:
	var best := 0.0
	for obstacle in _obstacles:
		if is_instance_valid(obstacle) and not obstacle.is_queued_for_deletion():
			best = maxf(best, obstacle.ratio())
	return best


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.TERKUNCI:
		# Enter maupun Esc keluar ke layar pilih bab -- tidak ada tujuan lain
		# yang masuk akal dari layar yang isinya cuma "bab ini terkunci".
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			SceneRouter.go_to_chapter_select()
			get_viewport().set_input_as_handled()
		return
	# Layar MISI SELESAI menunggu satu tombol sebelum lanjut ke "SUNGAI LANCAR".
	# Tidak otomatis: pemain yang baru dapat tiga bintang berhak memandanginya
	# selama yang dia mau.
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

	# Menyentuh/mengeklik ikan juga memindahkan kendali. Di layar sentuh, Tab
	# tidak ada, dan menekan ikan yang ingin digerakkan adalah gerakan yang
	# paling langsung terpikirkan pemain.
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


func _freeze_all() -> void:
	for fish in _fish:
		fish.set_active(false)
		fish.set_physics_process(false)


# --- Sumbatan ---------------------------------------------------------------

## Bonus yang tersisa untuk sumbatan yang baru saja terbuka, 0 sampai maksimum.
func _efficiency_bonus() -> int:
	var left := clampf(1.0 - _segment_time / maxf(bonus_fade_seconds, 0.01), 0.0, 1.0)
	return int(round(float(max_efficiency_bonus) * left))


func _on_obstacle_cleared(sumbatan: Node) -> void:
	_cleared += 1
	var melepas_arus: bool = sumbatan.akan_deras
	var masih_ada_kerjaan := _cleared < _total_obstacles

	var bonus := _efficiency_bonus()
	GameState.add_score(score_per_obstacle + bonus)
	# Hitungan waktu dimulai lagi dari nol untuk sumbatan berikutnya, supaya
	# sumbatan pertama yang lama tidak ikut menghukum sumbatan kedua.
	_segment_time = 0.0
	_camera.shake(18.0)
	_hud.set_progress(_cleared, _total_obstacles)
	# Ramalan disegarkan SEBELUM banner apa pun tampil, supaya penanda di layar
	# sudah benar pada frame yang sama saat pemain melihat akibatnya.
	_segarkan_ramalan()

	if melepas_arus:
		_lepas_arus(sumbatan.global_position.x, masih_ada_kerjaan)

	if masih_ada_kerjaan:
		if not melepas_arus:
			# Angkanya disebut supaya pemain tahu bahwa cepat itu berarti sesuatu
			# -- tanpa ini, bonus efisiensi jadi aturan tersembunyi yang tidak
			# adil. Saat arus deras lepas, banner peringatan lebih penting
			# daripada angka, jadi yang ini mengalah.
			_hud.show_banner("Satu sumbatan lepas  (+%d).  Sisa %d lagi." %
				[score_per_obstacle + bonus, _total_obstacles - _cleared], 2.6)
		return

	_selesaikan()


func _selesaikan() -> void:
	_phase = Phase.SELESAI
	_pause.enabled = false

	var sempurna := not _pernah_salah_urutan
	if sempurna:
		GameState.add_score(bonus_rencana_sempurna)

	var kabar := "Airnya mengalir lagi!  Skor %d." % GameState.score
	if sempurna:
		kabar = "RENCANA SEMPURNA  (+%d)\nAirnya mengalir lagi tanpa sekali pun menghambur." \
			% bonus_rencana_sempurna
	_hud.show_banner(kabar, ending_delay)
	AudioManager.play("river_flows", 2.0, 1.0, 0.0)

	await get_tree().create_timer(ending_delay).timeout
	# is_instance_valid(self) diperiksa DULU: kalau node ini sudah dibuang
	# selama jeda, memanggil is_inside_tree() padanya sendiri sudah error.
	if not is_instance_valid(self) or not is_inside_tree():
		return

	GameState.last_perfect = sempurna
	# Rekor diperiksa sebelum babnya ditandai tamat -- lihat penjelasan yang
	# sama di map_manager.gd.
	var rekor_baru := GameState.record_score(3, GameState.score)
	GameState.mark_map_completed(3)

	var layar: CanvasLayer = MISI_SELESAI_SCENE.instantiate()
	add_child(layar)
	layar.tampilkan(3, GameState.score, rekor_baru, sempurna, "Enter  lihat sungainya")
	_menunggu_lanjut = true
