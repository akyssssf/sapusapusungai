extends Node2D
## Perakit dan wasit satu map. Dipakai Map 1 DAN Map 2.
##
## Semua "aturan main" satu map ditaruh di sini, bukan disebar ke tiap entitas.
## Alur satu map dibagi jadi beberapa babak, dan seluruh isi file ini pada
## dasarnya cuma mengurus perpindahan antar babak itu:
##
##   MEMBURU      Sungai terus diisi sampah. Pemain makan yang kecil, menghindar
##                dari yang besar, dan tumbuh dari level 1 sampai maksimum.
##   MEMBERSIHKAN Begitu ikan mencapai ukuran maksimum, pengisian DIHENTIKAN.
##                Semua sampah sekarang bisa dimakan. Di Map 2, hama sapu-sapu
##                juga harus habis sebelum babak ini dianggap selesai.
##   BOS          Hanya kalau boss_scene diisi. Map 2 belum punya bos.
##   MENANG/KALAH Layar hasil.
##   BANJIR       Khusus Map 2: ekosistem kolaps karena terlalu banyak ikan
##                lokal termakan. Pindah ke scene game over.
##
## Yang membedakan Map 1 dan Map 2 semuanya berupa properti @export, bukan kode
## bercabang. Kalau suatu saat perbedaannya sudah terlalu banyak untuk diatur
## lewat Inspector, barulah file ini pantas dipecah.

signal phase_changed(new_phase: int)

enum Phase { MEMBURU, MEMBERSIHKAN, BOS, MENANG, KALAH, BANJIR, TERKUNCI }

@export_group("Identitas map")
## 1 untuk Kali Brantas, 2 untuk Sungai Ciliwung. Dipakai menandai progres.
@export var map_index: int = 1
@export var intro_banner: String = "Kali Brantas -- bersihkan sampahnya!"
@export var clear_banner: String = "Ukuran maksimum! Habiskan sisa sampahnya."
@export var win_title: String = "KALI BRANTAS BERSIH"
@export var lose_title: String = "IKAN WADER KALAH"
## Kalau diisi, layar menang menawarkan lanjut ke map ini, bukan mengulang.
@export_file("*.tscn") var next_map_path: String = ""
@export var next_map_label: String = ""
## Musik map ini. Kosong berarti pakai ambience Kali Brantas.
@export var music: AudioStream

@export_group("Gerbang progres")
## Map 2 hanya boleh dibuka kalau Map 1 sudah diselesaikan.
@export var requires_map1: bool = false
## Melewati jaring pengaman di atas, supaya scene peta bisa dijalankan langsung
## dari editor. Aman dibiarkan menyala.
@export var bypass_progress_gate: bool = false

@export_group("Sungai")
## Ukuran peta dalam piksel. Viewport-nya 1280x720.
@export var world_size: Vector2 = Vector2(2048, 1152)
## Tinggi dasar sungai di bagian bawah peta. Ikan dan sampah tidak masuk ke
## sana, tapi kamera tetap boleh memperlihatkannya.
@export var riverbed_height: float = 160.0

@export_group("Penghuni")
## Node opsional berisi ikan lokal dan hama. Hanya Map 2 yang mengisinya.
@export var wildlife_path: NodePath
## Node opsional pengawas ekosistem. Hanya Map 2 yang mengisinya.
@export var ecosystem_path: NodePath

@export_group("Bos")
## Kosong berarti map ini tidak punya bos; sungai bersih langsung berarti menang.
@export var boss_scene: PackedScene
## Jeda setelah sungai bersih sebelum bos benar-benar masuk, supaya pemain
## sempat membaca peringatannya.
@export var boss_entry_delay: float = 1.8

@onready var _player: CharacterBody2D = $PlayerFish
@onready var _camera: Camera2D = $PlayerFish/Camera2D
@onready var _director: Node2D = $TrashDirector
@onready var _hud: CanvasLayer = $HUD
@onready var _pause: CanvasLayer = $PauseMenu

## Kolom air tempat ikan boleh berenang: seluruh peta dikurangi dasar sungai.
var _water: Rect2 = Rect2()
var _phase: int = Phase.MEMBURU
var _boss: Node2D = null
var _boss_countdown: float = 0.0
## Jeda singkat sebelum layar hasil menerima tombol. Tanpa ini, pemain yang
## sedang menekan Spasi untuk dash akan langsung melewati layar hasil tanpa
## sempat membaca skornya sendiri -- karena Spasi juga tombol "ui_accept".
var _restart_lock: float = 0.0
var _wildlife: Node2D = null
var _ecosystem: Node = null


func _ready() -> void:
	GameState.begin_run(map_index, scene_file_path)

	_water = Rect2(Vector2.ZERO, Vector2(world_size.x, world_size.y - riverbed_height))
	_player.swim_bounds = _water
	_player.position = Vector2(_water.size.x * 0.4, _water.size.y * 0.5)
	_setup_camera()
	_hud.bind_player(_player)

	if not _progress_gate_passed():
		_enter_phase(Phase.TERKUNCI)
		return

	# Wasit hanya mendengarkan; ia tidak pernah menyuruh ikan melakukan apa pun.
	_player.size_level_changed.connect(_on_player_size_level_changed)
	_player.died.connect(_on_player_died)

	# Director cuma mengumumkan; yang memutuskan tampilannya adalah HUD.
	_director.rush_warned.connect(_hud.show_hazard_warning)
	_director.surge_started.connect(_on_surge_started)
	_director.setup(_water, _player)

	if not wildlife_path.is_empty():
		_wildlife = get_node(wildlife_path)
		_wildlife.setup(_water, _player)

	if not ecosystem_path.is_empty():
		_ecosystem = get_node(ecosystem_path)
		_ecosystem.collapsed.connect(_on_ecosystem_collapsed)

	_hud.show_banner(intro_banner, 3.2)
	AudioManager.play_music(music if music != null else AudioManager.MUSIC_RIVER, 1.8)


## Jaring pengaman, bukan gerbang utama.
##
## Sejak ada layar pilih bab, pintu yang sesungguhnya ada di sana -- kartu bab
## yang terkunci bahkan tidak bisa diklik. Pemeriksaan di sini cuma berlaku
## kalau scene peta dijalankan LANGSUNG dari editor, dan karena itu
## bypass_progress_gate boleh dibiarkan menyala tanpa membocorkan apa pun ke
## pemain.
func _progress_gate_passed() -> bool:
	if not requires_map1 or bypass_progress_gate:
		return true
	return GameState.is_unlocked(map_index)


func _setup_camera() -> void:
	# Batas kamera dipatok ke SELURUH peta (termasuk dasar sungai) supaya
	# pemandangan lumpur dan tanamannya tetap kelihatan, walaupun ikan sendiri
	# tidak boleh berenang sampai ke sana.
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(world_size.x)
	_camera.limit_bottom = int(world_size.y)


func _process(delta: float) -> void:
	if _restart_lock > 0.0:
		_restart_lock -= delta

	match _phase:
		Phase.MEMBERSIHKAN:
			if _is_river_clean():
				_enter_phase(Phase.BOS if boss_scene != null else Phase.MENANG)
		Phase.BOS:
			# Hitung mundur sebelum bos muncul; peringatannya sudah tampil.
			if _boss == null:
				_boss_countdown -= delta
				if _boss_countdown <= 0.0:
					_spawn_boss()


## Sungai dianggap bersih kalau sampahnya habis DAN hamanya habis.
##
## trash_count(), bukan get_child_count(): batang bambu yang kebetulan masih
## melintas bukan sampah, jadi tidak boleh menunda babak berikutnya.
func _is_river_clean() -> bool:
	if _director.trash_count() > 0:
		return false
	if _wildlife != null and _wildlife.pest_count() > 0:
		return false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if _restart_lock > 0.0:
		return

	# Esc di layar hasil.
	#
	# Menu jeda sudah dimatikan begitu ronde berakhir, jadi tanpa cabang ini Esc
	# tidak melakukan apa-apa sama sekali di layar menang/kalah -- padahal
	# petunjuk di layarnya sendiri menyebut Esc. Aman ditaruh di sini: PauseMenu
	# adalah anak dari node ini, dan _unhandled_input mengalir dari anak ke
	# induk, jadi selama permainan masih berjalan Esc sudah keburu ditelan menu
	# jeda dan tidak pernah sampai ke sini.
	if event.is_action_pressed("ui_cancel"):
		match _phase:
			Phase.TERKUNCI, Phase.MENANG, Phase.KALAH:
				SceneRouter.go_to_chapter_select()
				get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("ui_accept"):
		return

	match _phase:
		Phase.TERKUNCI:
			SceneRouter.go_to_chapter_select()
		Phase.MENANG:
			if next_map_path.is_empty():
				SceneRouter.go_to_chapter_select()
			else:
				SceneRouter.go_to(next_map_path)
		Phase.KALAH:
			SceneRouter.restart_chapter()


# --- Perpindahan babak ------------------------------------------------------

func _enter_phase(next_phase: int) -> void:
	if _phase == next_phase:
		return
	_phase = next_phase
	phase_changed.emit(_phase)

	match next_phase:
		Phase.TERKUNCI:
			_restart_lock = 0.8
			_player.freeze()
			_pause.enabled = false
			_hud.show_result("BAB INI MASIH TERKUNCI",
				"Selesaikan bab sebelumnya dulu  -  tekan Enter untuk pilih bab")
		Phase.MEMBERSIHKAN:
			# Inilah momen ala Feeding Frenzy: keran ditutup, dan semua yang
			# tadinya ranjau berubah jadi santapan.
			_director.stop()
			_hud.show_banner(clear_banner, 3.4)
		Phase.BOS:
			_boss_countdown = boss_entry_delay
			_hud.show_banner("Sungai bersih... tapi ada yang mendekat.", boss_entry_delay)
			# Musik ditukar SEBELUM bosnya kelihatan. Telinga selalu lebih cepat
			# dari mata: pemain sudah tegang duluan sebelum tahu kenapa.
			AudioManager.play_music(AudioManager.MUSIC_BOSS, 1.0)
		Phase.MENANG:
			_restart_lock = 1.0
			_player.freeze()
			_pause.enabled = false
			# Urutannya penting: rekor diperiksa SEBELUM babnya ditandai tamat,
			# karena record_score() yang menyimpan angka barulah yang tahu angka
			# lamanya. Dibalik, lencana "REKOR BARU" tidak akan pernah muncul.
			var rekor_baru := GameState.record_score(map_index, GameState.score)
			GameState.mark_map_completed(map_index)
			AudioManager.play("win", 2.0, 1.0, 0.0)
			AudioManager.play_music(music if music != null else AudioManager.MUSIC_RIVER, 2.0)
			_hud.hide_boss_bar()
			_tampilkan_misi_selesai(rekor_baru)
		Phase.KALAH:
			_restart_lock = 1.0
			_player.freeze()
			_pause.enabled = false
			GameState.record_score(map_index, GameState.score)
			GameState.last_ending = GameState.Ending.NYAWA_HABIS
			AudioManager.play("lose", 2.0, 1.0, 0.0)
			AudioManager.stop_music(1.4)
			_hud.hide_boss_bar()
			_hud.show_result(lose_title, "Skor %d  -  Enter ulangi bab  -  Esc pilih bab" % GameState.score)
		Phase.BANJIR:
			_player.freeze()
			_pause.enabled = false
			GameState.record_score(map_index, GameState.score)
			GameState.last_ending = GameState.Ending.BANJIR
			_hud.hide_boss_bar()
			_camera.shake(30.0)
			# Layar banjir punya scene sendiri. Jeda sebentar dulu supaya pemain
			# sempat melihat air yang sudah pekat -- itu jawaban atas pertanyaan
			# "kenapa dari tadi makin gelap".
			await get_tree().create_timer(1.6).timeout
			if is_inside_tree():
				SceneRouter.go_to("res://scenes/ui/game_over.tscn")


const MISI_SELESAI_SCENE := preload("res://scenes/ui/mission_complete.tscn")


## Layar MISI SELESAI dipasang sebagai tempelan di atas peta, bukan lewat pindah
## scene. Sungai yang baru saja dibersihkan tetap kelihatan di belakangnya --
## itu bukti hasil kerja pemain, dan menggantinya dengan latar polos berarti
## membuang hadiah yang paling dia hasilkan sendiri.
func _tampilkan_misi_selesai(rekor_baru: bool) -> void:
	var layar: CanvasLayer = MISI_SELESAI_SCENE.instantiate()
	add_child(layar)
	layar.tampilkan(map_index, GameState.score, rekor_baru, GameState.last_perfect, _win_hint())


func _win_hint() -> String:
	if next_map_path.is_empty():
		return "Enter  pilih bab"
	return "Enter  lanjut ke %s          Esc  pilih bab" % next_map_label


func _on_surge_started(duration: float) -> void:
	_hud.show_banner("ARUS DERAS!", duration)
	_camera.shake(12.0)
	# Suara sedotan bos dipakai ulang dengan nada diturunkan -- jadinya deru
	# air bah. Tidak perlu berkas baru untuk sesuatu yang cuma beda nada.
	AudioManager.play("boss_suck", -2.0, 0.68, 0.03)


func _on_player_size_level_changed(new_level: int) -> void:
	if new_level >= _player.max_size_level:
		_enter_phase(Phase.MEMBERSIHKAN)


func _on_player_died() -> void:
	_enter_phase(Phase.KALAH)


func _on_ecosystem_collapsed() -> void:
	# Ekosistem kolaps mengalahkan babak apa pun yang sedang berjalan, termasuk
	# saat sungai sebenarnya sudah bersih. Justru itu intinya.
	_enter_phase(Phase.BANJIR)


# --- Bos --------------------------------------------------------------------

func _spawn_boss() -> void:
	_boss = boss_scene.instantiate()
	# Bos masuk dari luar tepi kanan lalu berenang ke tengah arena.
	_boss.position = Vector2(_water.end.x + 320.0, _water.get_center().y)
	_boss.plates_changed.connect(_hud.show_boss_bar)
	# Aba-aba terjangan bos memakai penanda yang sama persis dengan batang
	# bambu. Satu bahasa visual untuk satu arti: garis merah = jalur maut.
	_boss.charge_warned.connect(_hud.show_hazard_warning)
	_boss.defeated.connect(_on_boss_defeated)
	add_child(_boss)
	# Bos disisipkan TEPAT SEBELUM ikan pemain dalam urutan anak. Di 2D, urutan
	# anak = urutan gambar, jadi tanpa ini badan bos yang besar akan menutupi
	# ikan pemain setiap kali keduanya bertumpuk.
	move_child(_boss, _player.get_index())
	_boss.setup(_player, _water)

	_hud.show_banner("INDUK SAPU-SAPU! Gigit insangnya saat menyala.", 3.6)
	_camera.shake(24.0)
	AudioManager.play("boss_appear", 3.0, 1.0, 0.0)


func _on_boss_defeated() -> void:
	_enter_phase(Phase.MENANG)
