extends Node2D
## Penghuni hidup Sungai Ciliwung: ikan lokal dan hama sapu-sapu.
##
## Sengaja dipisah dari trash_director.gd walaupun keduanya sama-sama "pengisi
## sungai", karena aturan pasokannya berlawanan:
##
##   SAMPAH      terus mengalir masuk sepanjang permainan. Jumlahnya dijaga.
##   IKAN LOKAL  populasi TETAP. Tidak pernah bertambah, tidak pernah hilang --
##               memang tidak boleh hilang, itu inti pelajarannya.
##   SAPU-SAPU   populasi TERBATAS dan HABIS. Begitu semuanya bersih, tugas
##               di sungai ini selesai. Kalau mereka lahir ulang, "membersihkan
##               sungai" jadi pekerjaan tanpa ujung dan pemain tidak pernah
##               merasa menang.
##
## Karena itu node ini cuma menebar sekali di awal, lalu diam. Tidak ada timer,
## tidak ada isi ulang.

@export var local_fish_scene: PackedScene
@export var sapu_sapu_scene: PackedScene

@export var local_fish_count: int = 7
@export var sapu_sapu_count: int = 6

## Jarak dari tepi air yang tidak dipakai untuk menebar.
@export var margin: float = 90.0
## Ikan dan hama tidak lahir terlalu dekat pemain, supaya detik pertama tidak
## langsung berisi tabrakan yang bukan salah siapa-siapa.
@export var min_distance_from_player: float = 300.0
## Sapu-sapu juga tidak boleh lahir menempel ikan lokal: pemain yang menyerang
## hama akan ikut menabrak ikan yang harusnya dilindungi.
@export var min_distance_between: float = 170.0

var _water: Rect2 = Rect2()
var _player: Node2D = null
var _taken: Array[Vector2] = []


## Dipanggil map_manager, sama polanya dengan trash_director.
func setup(water: Rect2, player: Node2D) -> void:
	_water = water
	_player = player
	_taken.clear()

	for i in local_fish_count:
		_spawn(local_fish_scene, "ikan lokal")
	for i in sapu_sapu_count:
		_spawn(sapu_sapu_scene, "sapu-sapu")


## Berapa hama yang masih hidup. Dipakai map_manager sebagai syarat menang.
func pest_count() -> int:
	var n := 0
	for child in get_children():
		if child.is_in_group("pest") and not child.is_queued_for_deletion():
			n += 1
	return n


func local_fish_count_alive() -> int:
	var n := 0
	for child in get_children():
		if child.is_in_group("local_fish"):
			n += 1
	return n


func _spawn(scene: PackedScene, label: String) -> void:
	if scene == null:
		push_warning("wildlife_director: scene %s belum diisi di Inspector." % label)
		return
	var creature: Node2D = scene.instantiate()
	# swim_bounds dan position diatur SEBELUM add_child(), karena _ready() milik
	# keduanya sudah memakai posisi awal sebagai titik acuan geraknya.
	creature.position = _pick_point()
	creature.swim_bounds = _water
	add_child(creature)


func _pick_point() -> Vector2:
	var point := Vector2.ZERO
	# Dicoba beberapa kali; kalau tetap kepepet, pakai percobaan terakhir --
	# lebih baik satu titik agak berdesakan daripada mengulang selamanya.
	for attempt in 14:
		point = Vector2(
			randf_range(_water.position.x + margin, _water.end.x - margin),
			randf_range(_water.position.y + margin, _water.end.y - margin)
		)
		if _player != null and point.distance_to(_player.position) < min_distance_from_player:
			continue
		var clear := true
		for other in _taken:
			if point.distance_to(other) < min_distance_between:
				clear = false
				break
		if clear:
			break
	_taken.append(point)
	return point
