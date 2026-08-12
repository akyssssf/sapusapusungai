extends CanvasLayer
## Autoload: satu-satunya pintu untuk berpindah scene.
##
## Sebelum ada file ini, tiap layar memanggil change_scene_to_file() sendiri
## dengan alamat yang ditulis mati di tempatnya masing-masing. Akibatnya dua
## hal: alamat scene tersebar di tujuh berkas, dan perpindahannya menyentak --
## satu frame masih di sungai, frame berikutnya sudah di menu.
##
## Sekarang semuanya lewat sini, dan tiap perpindahan dibungkus redup-terang.
## Jeda 0,3 detik itu bukan hiasan: otak butuh sekejap untuk melepas layar lama
## sebelum membaca layar baru, dan tanpa jeda itu perpindahan terasa seperti
## kesalahan render.
##
## CanvasLayer dengan layer sangat tinggi supaya tirainya selalu di atas apa pun,
## termasuk HUD dan menu jeda.

const MENU_PATH := "res://scenes/ui/main_menu.tscn"
const CHAPTER_SELECT_PATH := "res://scenes/ui/chapter_select.tscn"
const CUTSCENE_PATH := "res://scenes/ui/cutscene.tscn"
const BRIEFING_PATH := "res://scenes/ui/briefing.tscn"

@export var fade_time: float = 0.3

## Diisi tepat sebelum cutscene dibuka; cutscene membacanya saat _ready().
## Lewat autoload, bukan lewat parameter, karena change_scene_to_file() tidak
## punya cara mengoper argumen ke scene berikutnya.
var cutscene_id: String = ""
var cutscene_next: String = ""
var briefing_chapter: int = 0

var _veil: ColorRect
var _busy: bool = false
## Bab yang sedang dituju lewat rantai "cerita -> papan instruksi -> peta".
var _rantai_bab: int = 0


func _ready() -> void:
	layer = 128
	# Tirai harus tetap bekerja saat permainan dijeda -- tombol "keluar ke menu"
	# di menu jeda dipencet justru ketika get_tree().paused bernilai true.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_veil = ColorRect.new()
	_veil.color = Color(0.02, 0.05, 0.07, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)


## Pindah ke scene lain dengan redup-terang.
func go_to(path: String) -> void:
	if _busy or path.is_empty():
		return
	_busy = true

	# Permainan selalu dilepas dari jeda sebelum pindah. Kalau lupa, scene
	# berikutnya lahir dalam keadaan beku dan terlihat seperti game hang.
	get_tree().paused = false

	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_veil, "color:a", 1.0, fade_time)
	await tween.finished

	get_tree().change_scene_to_file(path)
	# Satu frame jeda supaya scene barunya sempat siap sebelum tirai dibuka.
	await get_tree().process_frame

	var back := create_tween()
	back.tween_property(_veil, "color:a", 0.0, fade_time)
	await back.finished

	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func go_to_menu() -> void:
	go_to(MENU_PATH)


func go_to_chapter_select() -> void:
	go_to(CHAPTER_SELECT_PATH)


## Masuk ke sebuah bab lewat rantai: cerita -> papan instruksi -> peta.
##
## Rantainya sengaja TIDAK dirakit di sini sebagai daftar alamat scene, melainkan
## dihitung ulang tiap langkah oleh lanjutkan_rantai(). Bedanya penting: cutscene
## menandai dirinya "sudah ditonton" saat selesai, jadi begitu rantai dihitung
## ulang, langkah itu hilang dengan sendirinya. Kalau rantainya dirakit di depan
## sebagai daftar, tiap langkah harus tahu siapa penerusnya -- dan menambah
## langkah baru berarti menyunting semua yang sudah ada.
func go_to_chapter(index: int) -> void:
	_rantai_bab = index
	lanjutkan_rantai()


## Dipanggil cutscene dan papan instruksi saat selesai.
func lanjutkan_rantai() -> void:
	if _rantai_bab <= 0:
		go_to_menu()
		return

	var index := _rantai_bab
	var id := Story.intro_untuk_bab(index)
	if not id.is_empty() and not GameState.has_seen_story(id):
		cutscene_id = id
		cutscene_next = ""
		go_to(CUTSCENE_PATH)
		return

	if not GameState.has_seen_story(Story.kunci_briefing(index)):
		briefing_chapter = index
		go_to(BRIEFING_PATH)
		return

	_rantai_bab = 0
	go_to(GameState.chapter_path(index))


## Cutscene yang berdiri sendiri, di luar rantai bab -- dipakai penutup cerita
## setelah Bab 3. Selesai menonton, pemain kembali ke menu.
func play_cutscene(id: String, next_path: String = "") -> void:
	_rantai_bab = 0
	cutscene_id = id
	cutscene_next = next_path
	go_to(CUTSCENE_PATH)


## Mengulang bab yang sedang dimainkan. Memakai alamat yang dicatat GameState,
## bukan reload_current_scene(), supaya tetap benar walaupun dipanggil dari
## layar hasil yang scene-nya sudah bukan peta itu lagi.
func restart_chapter() -> void:
	if GameState.last_map_path.is_empty():
		go_to_menu()
		return
	go_to(GameState.last_map_path)
