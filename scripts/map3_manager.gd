extends Node2D
## Wasit Map 3 -- Kali Jeroan Madiun.
##
## Sengaja TIDAK memakai map_manager.gd. Map 1 dan 2 punya babak berburu,
## ukuran ikan, nyawa, dan bos; Map 3 tidak punya satu pun dari itu. Memaksakan
## keduanya berbagi satu file akan menghasilkan wasit yang setengah isinya
## dimatikan lewat properti -- dan file seperti itu selalu berakhir jadi sarang
## bug, karena tidak ada yang ingat cabang mana yang masih hidup.
##
## Tugas file ini cuma empat:
##   1. Memeriksa gerbang progres (Map 2 harus selesai).
##   2. Menyiapkan dua ikan dan menentukan siapa yang sedang dikendalikan.
##   3. Menghitung berapa sumbatan yang sudah terbuka.
##   4. Memanggil layar ending saat semuanya terbuka.

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
	_hud.show_banner("Sungai sudah bersih, tapi airnya tetap tertahan.\nDorong sumbatan bambu -- BERDUA.", 5.0)
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
		child.cleared.connect(_on_obstacle_cleared)
	_total_obstacles = _obstacles.size()
	if _total_obstacles == 0:
		push_warning("map3_manager: tidak ada sumbatan di node Obstacles.")


func _process(delta: float) -> void:
	if _phase != Phase.BERMAIN:
		return
	_segment_time += delta
	# Bar aliran mengikuti sumbatan yang sedang didorong, bukan cuma yang sudah
	# selesai. Dengan begitu pemain melihat usahanya terbayar SELAMA menahan,
	# bukan baru setelah berhasil.
	_hud.set_progress_fine(float(_cleared) + _active_charge(), _total_obstacles)


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


func _on_obstacle_cleared() -> void:
	_cleared += 1
	var bonus := _efficiency_bonus()
	GameState.add_score(score_per_obstacle + bonus)
	# Hitungan waktu dimulai lagi dari nol untuk sumbatan berikutnya, supaya
	# sumbatan pertama yang lama tidak ikut menghukum sumbatan kedua.
	_segment_time = 0.0
	_camera.shake(18.0)
	_hud.set_progress(_cleared, _total_obstacles)

	if _cleared < _total_obstacles:
		# Angkanya disebut supaya pemain tahu bahwa cepat itu berarti sesuatu --
		# tanpa ini, bonus efisiensi jadi aturan tersembunyi yang tidak adil.
		_hud.show_banner("Satu sumbatan lepas  (+%d).  Sisa %d lagi." %
			[score_per_obstacle + bonus, _total_obstacles - _cleared], 2.6)
		return

	_phase = Phase.SELESAI
	_pause.enabled = false
	_hud.show_banner("Airnya mengalir lagi!  Skor %d." % GameState.score, ending_delay)
	AudioManager.play("river_flows", 2.0, 1.0, 0.0)
	await get_tree().create_timer(ending_delay).timeout
	if is_inside_tree():
		GameState.record_score(3, GameState.score)
		GameState.mark_map_completed(3)
		SceneRouter.go_to(ending_scene)
