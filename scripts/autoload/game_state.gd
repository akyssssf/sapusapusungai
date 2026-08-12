extends Node
## Autoload: satu-satunya sumber kebenaran untuk data yang hidup lintas scene.
##
## Ada TIGA jenis data di sini, dan bedanya menentukan kapan masing-masing
## dihapus:
##
##   DATA SATU RONDE -- skor berjalan, hitungan ikan lokal termakan.
##                      Dihapus begin_run() tiap kali sebuah bab dimulai.
##   DATA CAPAIAN    -- bab yang sudah tamat, skor terbaik tiap bab.
##                      Disimpan ke disk, hanya hilang kalau pemain menghapusnya.
##   PENGATURAN      -- volume. Ikut disimpan ke disk.
##
## Entitas tidak pernah saling memanggil untuk urusan skor atau progres;
## semuanya lewat sini.

signal score_changed(new_score: int)

## Dipancarkan tiap kali ikan lokal termakan.
##
## Angkanya TIDAK PERNAH ditampilkan ke pemain. Satu-satunya yang mendengarkan
## sinyal ini adalah ecosystem_watch.gd, yang menerjemahkannya jadi perubahan
## warna air dan nada musik. Kalau ditampilkan sebagai "3/5", pemain akan
## memperlakukannya sebagai kuota yang boleh dihabiskan.
signal local_fish_eaten_changed(count: int)
signal progress_changed

enum Ending { TIDAK_ADA, BANJIR, NYAWA_HABIS }

## Daftar bab. Satu-satunya tempat judul, urutan, dan alamat scene tiap bab
## ditulis -- menu utama, layar pilih bab, dan tombol "lanjut" semuanya membaca
## dari sini. Menambah Bab 4 nanti cukup menambah satu baris.
const CHAPTERS := [
	{
		"index": 1,
		"title": "Kali Brantas",
		"subtitle": "Bab 1  -  Jawa Timur",
		"blurb": "Sungainya penuh sampah. Tumbuh besar, bersihkan semuanya,\nlalu hadapi induk sapu-sapu.",
		"path": "res://scenes/maps/map1_brantas.tscn",
	},
	{
		"index": 2,
		"title": "Sungai Ciliwung",
		"subtitle": "Bab 2  -  Jakarta",
		"blurb": "Sampahnya lebih padat, dan sekarang ada penghuni lain.\nIkan lokal tidak boleh termakan.",
		"path": "res://scenes/maps/map2_ciliwung.tscn",
	},
	{
		"index": 3,
		"title": "Kali Jeroan",
		"subtitle": "Bab 3  -  Madiun",
		"blurb": "Sungainya sudah bersih tapi airnya tetap tertahan.\nDua ikan, satu sumbatan bambu.",
		"path": "res://scenes/maps/map3_jeroan.tscn",
	},
]

## Mulai dari hitungan ke sekian, air mulai berubah. Sengaja lebih kecil dari
## ECOSYSTEM_LIMIT supaya pemain masih punya ruang untuk menyadari dan berhenti.
const ECOSYSTEM_WARNING_AT := 3
## Berapa kali ikan lokal boleh termakan sebelum ekosistemnya kolaps.
const ECOSYSTEM_LIMIT := 5

const SAVE_PATH := "user://sapusapusungai.cfg"

# --- Data satu ronde --------------------------------------------------------

var score: int = 0
## Berapa kali ikan lokal termakan pada ronde ini.
var local_fish_eaten: int = 0
var last_ending: int = Ending.TIDAK_ADA
## Bab yang sedang dimainkan, dipakai mencatat skor terbaik dan tombol ulangi.
var current_chapter: int = 0
var last_map_path: String = ""

# --- Data capaian (tersimpan) -----------------------------------------------

var completed := {1: false, 2: false, 3: false}
var best_scores := {1: 0, 2: 0, 3: 0}

# --- Pengaturan (tersimpan) -------------------------------------------------

## 0.0 sampai 1.0. AudioManager yang menerjemahkannya ke desibel.
var music_volume: float = 0.8
var sfx_volume: float = 0.9


func _ready() -> void:
	load_progress()


# --- Skor -------------------------------------------------------------------

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


## Dipanggil wasit tiap bab saat rondenya berakhir, menang maupun kalah.
## Kalah tetap dicatat: skornya sah, cuma babnya belum tamat.
func record_score(chapter: int, value: int) -> void:
	if not best_scores.has(chapter):
		return
	if value > int(best_scores[chapter]):
		best_scores[chapter] = value
		save_progress()
		progress_changed.emit()


func total_best_score() -> int:
	var total := 0
	for value in best_scores.values():
		total += int(value)
	return total


# --- Ekosistem Bab 2 --------------------------------------------------------

func report_local_fish_eaten() -> void:
	local_fish_eaten += 1
	local_fish_eaten_changed.emit(local_fish_eaten)


## 0.0 sampai 1.0 -- seberapa dekat ekosistem ke titik kolaps.
##
## Titik acuannya sengaja (WARNING_AT - 1), bukan WARNING_AT. Kalau memakai
## WARNING_AT, hasilnya nol persis DI hitungan ke-3 -- artinya perubahan baru
## kelihatan di hitungan ke-4, satu langkah terlambat dari yang dimaksud.
func ecosystem_pressure() -> float:
	var floor_count := float(ECOSYSTEM_WARNING_AT - 1)
	var span := float(ECOSYSTEM_LIMIT) - floor_count
	if span <= 0.0:
		return 1.0 if local_fish_eaten >= ECOSYSTEM_LIMIT else 0.0
	return clampf((float(local_fish_eaten) - floor_count) / span, 0.0, 1.0)


func is_ecosystem_collapsed() -> bool:
	return local_fish_eaten >= ECOSYSTEM_LIMIT


# --- Progres bab ------------------------------------------------------------

func mark_map_completed(index: int) -> void:
	if not completed.has(index) or completed[index]:
		return
	completed[index] = true
	save_progress()
	progress_changed.emit()


func is_completed(index: int) -> bool:
	return bool(completed.get(index, false))


## Bab 1 selalu terbuka. Bab berikutnya terbuka kalau bab sebelumnya tamat.
func is_unlocked(index: int) -> bool:
	if index <= 1:
		return true
	return is_completed(index - 1)


## Bab pertama yang belum tamat -- dipakai tombol "Lanjutkan" di menu utama.
## Kalau semuanya sudah tamat, kembalikan bab terakhir supaya tombolnya tetap
## berguna untuk mengejar skor.
func next_chapter() -> int:
	for chapter in CHAPTERS:
		if not is_completed(int(chapter["index"])):
			return int(chapter["index"])
	return int(CHAPTERS[-1]["index"])


func has_any_progress() -> bool:
	for value in completed.values():
		if value:
			return true
	return false


func chapter_data(index: int) -> Dictionary:
	for chapter in CHAPTERS:
		if int(chapter["index"]) == index:
			return chapter
	return {}


func chapter_path(index: int) -> String:
	return String(chapter_data(index).get("path", ""))


# --- Awal & akhir satu ronde ------------------------------------------------

## Dipanggil wasit tiap bab saat scene-nya dibuka.
func begin_run(chapter: int, map_path: String) -> void:
	current_chapter = chapter
	last_map_path = map_path
	score = 0
	local_fish_eaten = 0
	last_ending = Ending.TIDAK_ADA
	score_changed.emit(score)
	local_fish_eaten_changed.emit(local_fish_eaten)


# --- Simpan & muat ----------------------------------------------------------

## Disimpan ke user:// -- di Windows itu %APPDATA%, di Android folder privat
## aplikasi. Sengaja ConfigFile, bukan JSON biner: berkasnya bisa dibuka pakai
## Notepad saat menguji, dan itu menghemat banyak waktu debugging progres.
func save_progress() -> void:
	var config := ConfigFile.new()
	for index in completed.keys():
		config.set_value("progres", "bab%d_tamat" % index, completed[index])
		config.set_value("progres", "bab%d_skor" % index, best_scores[index])
	config.set_value("pengaturan", "volume_musik", music_volume)
	config.set_value("pengaturan", "volume_efek", sfx_volume)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_warning("GameState: gagal menyimpan progres (kode %d)." % err)


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		# Belum ada berkas simpanan: pemain baru. Bukan error.
		return
	for index in completed.keys():
		completed[index] = bool(config.get_value("progres", "bab%d_tamat" % index, false))
		best_scores[index] = int(config.get_value("progres", "bab%d_skor" % index, 0))
	music_volume = float(config.get_value("pengaturan", "volume_musik", music_volume))
	sfx_volume = float(config.get_value("pengaturan", "volume_efek", sfx_volume))


func reset_progress() -> void:
	for index in completed.keys():
		completed[index] = false
		best_scores[index] = 0
	save_progress()
	progress_changed.emit()
