extends Node2D
## Pengatur arus sampah. Node ini juga jadi induk semua sampah yang hidup,
## jadi get_child_count() langsung berarti "berapa sampah di sungai sekarang".
##
## Tugasnya bukan sekadar "isi ulang sampai penuh". Kalau cuma itu, sungainya
## jadi kolam berisi titik-titik acak dan cepat membosankan. Yang dilakukan di
## sini ada empat lapis:
##
##   1. ISI DASAR   -- menjaga jumlah sampah tetap di sekitar target_count.
##   2. KOMPOSISI   -- makin besar ikannya, makin jarang sampah kecil muncul dan
##                     makin sering sampah besar. Berburu jadi makin sulit persis
##                     saat pemain merasa sudah jago.
##   3. KETUKAN     -- tiap beberapa detik terjadi satu "kejadian": gerombolan
##                     sampah kecil (hadiah), pagar sampah dengan satu celah
##                     (ujian gerak), atau arus deras (ujian reaksi).
##   4. TEKANAN     -- semua di atas makin cepat dan makin galak seiring waktu.
##                     Ini yang mencegah permainan terasa datar: pemain yang
##                     berlama-lama tidak dibiarkan santai, dia dikejar sungainya.
##
## Semua sampah hanyut ke kiri mengikuti arus, jadi sampah baru selalu masuk
## dari tepi kanan peta -- di luar pandangan kamera, supaya tidak terlihat
## muncul dari udara kosong.

signal surge_started(duration: float)
## side: -1 kalau bahaya datang dari tepi KIRI, +1 kalau dari tepi KANAN.
signal rush_warned(side: int, world_y: float, lead_time: float)

const TrashScript := preload("res://scripts/trash.gd")

## Jenis kejadian berkala.
enum Beat { GEROMBOLAN, BAMBU, PAGAR, DERAS }

@export var trash_scene: PackedScene
## Jumlah sampah yang diusahakan selalu ada.
@export var target_count: int = 30
## Jarak dari tepi atas/bawah air yang tidak dipakai untuk memunculkan sampah.
@export var vertical_margin: float = 55.0
## Seberapa jauh di kanan layar sampah baru dilahirkan.
@export var spawn_offset_x: float = 120.0
## Jeda acak antar pengisian satu butir.
@export var topup_delay_range: Vector2 = Vector2(0.22, 0.55)
## Jeda acak antar "kejadian", sebelum dipercepat oleh tekanan.
@export var beat_delay_range: Vector2 = Vector2(2.2, 3.4)
## Batas berapa banyak isi sungai yang boleh berupa sampah yang BELUM bisa
## dimakan ikan saat ini.
##
## Tanpa batas ini sungai perlahan tersumbat: sampah yang bisa dimakan hilang
## karena dimakan DAN karena hanyut, sedangkan yang belum bisa dimakan cuma
## hilang karena hanyut. Lama-lama layar penuh ranjau tanpa makanan, dan pemain
## terjebak di levelnya -- kelihatan seperti permainan yang macet, padahal cuma
## salah hitung pasokan.
@export var max_blocked_ratio: float = 0.35

@export_group("Tekanan")
## Berapa detik sampai tekanan mencapai puncaknya.
@export var ramp_seconds: float = 45.0
## Pengali jeda kejadian saat tekanan penuh. 0.55 = kejadian datang ~2x lebih rapat.
@export var beat_speedup_at_full: float = 0.65
## Pengali kecepatan arus saat tekanan penuh.
@export var current_speedup_at_full: float = 1.5
## Sudah tidak dipakai memilih kejadian (sekarang pakai kantong di _draw_beat),
## tapi disimpan karena menentukan kerapatan pagar: di atas 0.5 tekanan, celah
## pagar menyempit dari 5 slot jadi 6.
@export var wall_tighten_at: float = 0.5

@export_group("Batang bambu hanyut")
@export var rush_scene: PackedScene
## Berapa detik aba-aba tampil sebelum batangnya benar-benar lahir.
## Ini angka keadilan, bukan angka rasa: batangnya jauh lebih cepat daripada
## ikan, jadi tanpa jeda ini satu-satunya cara selamat adalah hafal.
@export var rush_lead_time: Vector2 = Vector2(1.45, 1.0)
@export var rush_speed: Vector2 = Vector2(700.0, 980.0)
## Peluang batang datang berpasangan (dua jalur sekaligus) saat tekanan penuh.
@export var rush_double_chance_at_full: float = 0.45

@export_group("Arus deras")
@export var surge_duration: float = 2.8
## Semua sampah hanyut sekian kali lebih cepat selama arus deras.
@export var surge_multiplier: float = 3.4

var active: bool = true

var _water: Rect2 = Rect2()
var _player: Node = null
var _topup_cooldown: float = 0.0
var _beat_cooldown: float = 0.0
var _elapsed: float = 0.0
var _surge_left: float = 0.0
## Antrean batang bambu yang aba-abanya sudah tampil tapi belum lahir.
## Isinya kamus {sisa_waktu, sisi, y}.
var _pending_rush: Array = []
## Kantong jenis kejadian. Lihat _draw_beat().
var _beat_bag: Array = []


## Dipanggil map_manager. Sengaja bukan _ready(), karena director butuh tahu
## batas air dan siapa pemainnya -- dua hal yang dimiliki map, bukan dirinya.
func setup(water: Rect2, player: Node) -> void:
	_water = water
	_player = player
	_beat_cooldown = randf_range(beat_delay_range.x, beat_delay_range.y)
	_fill_initial()


## Banyaknya SAMPAH yang masih di sungai.
##
## Sengaja bukan get_child_count(): batang bambu hanyut juga jadi anak node ini,
## dan dia bukan sampah. Kalau ikut dihitung, dua hal rusak sekaligus -- sungai
## dianggap belum bersih padahal sampahnya sudah habis, dan pengisian ulang
## berhenti terlalu cepat karena kuotanya dimakan batang yang cuma lewat.
func trash_count() -> int:
	var n := 0
	for child in get_children():
		if child.is_in_group("trash"):
			n += 1
	return n


## 0.0 di awal permainan sampai 1.0 saat tekanan penuh. Satu angka ini yang
## mengatur kecepatan kejadian, derasnya arus, dan seringnya pagar sampah --
## jadi menyetel kesulitan cukup lewat ramp_seconds, bukan belasan angka.
func pressure() -> float:
	return clampf(_elapsed / maxf(ramp_seconds, 0.01), 0.0, 1.0)


func _process(delta: float) -> void:
	if not active:
		return

	_elapsed += delta
	_tick_surge(delta)
	_tick_pending_rush(delta)

	_topup_cooldown -= delta
	if _topup_cooldown <= 0.0:
		_topup_cooldown = randf_range(topup_delay_range.x, topup_delay_range.y)
		if trash_count() < target_count:
			_spawn(_random_tier(), _entry_point())

	_beat_cooldown -= delta
	if _beat_cooldown <= 0.0:
		var base := randf_range(beat_delay_range.x, beat_delay_range.y)
		_beat_cooldown = base * lerpf(1.0, beat_speedup_at_full, pressure())
		_spawn_beat()


## Mematikan director. Dipanggil map_manager begitu ikan mencapai ukuran
## maksimum: mulai saat itu sungai tidak diisi lagi, dan tugas pemain berubah
## jadi menghabiskan sisa sampah yang sudah ada.
func stop() -> void:
	active = false
	_end_surge()
	# Aba-aba yang sudah tampil tidak boleh berbuah batang sesudah sungai
	# dinyatakan bersih -- nanti pemain kena serang di babak yang mestinya aman.
	_pending_rush.clear()
	_beat_bag.clear()


# --- Pengisian awal ---------------------------------------------------------

func _fill_initial() -> void:
	for i in target_count:
		# Butir pertama dijamin kecil semua supaya pemain punya kesempatan
		# tumbuh sebelum ranjau pertama muncul.
		var tier: int = TrashScript.Tier.KECIL if i < 9 else _random_tier()
		_spawn(tier, _free_point_away_from_player())


## Titik acak yang tidak menumpuk di atas pemain. Tanpa ini, sampah besar bisa
## lahir tepat di badan ikan pada detik pertama dan langsung memakan nyawa.
func _free_point_away_from_player() -> Vector2:
	var point := Vector2.ZERO
	for attempt in 8:
		point = Vector2(
			randf_range(_water.position.x + 50.0, _water.end.x - 50.0),
			randf_range(_water.position.y + vertical_margin, _water.end.y - vertical_margin)
		)
		if _player == null or point.distance_to(_player.position) >= 260.0:
			break
	return point


# --- Komposisi --------------------------------------------------------------

## Bobot peluang [kecil, sedang, besar] menurut level ikan sekarang.
func _tier_weights() -> Array:
	var level: int = _player.size_level if _player != null else 1
	# Porsinya dipatok ke berapa banyak yang BISA DIMAKAN pemain saat ini, bukan
	# sekadar dinaikkan seiring level. Keluhan yang mendasarinya: di ukuran 4
	# layar penuh sampah besar yang belum bisa disentuh, jadi sungai terasa
	# seperti ladang ranjau -- padahal cuma satu tingkat yang masih terlarang.
	if level <= 2:
		# Cuma sampah kecil yang bisa dimakan. Porsi yang lain ditekan, kalau
		# tidak pemain baru menghabiskan menit pertamanya cuma menghindar.
		return [74, 22, 4]
	if level <= 4:
		# Kecil dan sedang sudah bisa dimakan: dua dari tiga tingkat aman, dan
		# perbandingannya harus terasa begitu juga.
		return [44, 42, 14]
	# Semuanya bisa dimakan; sekarang porsinya boleh merata.
	return [34, 33, 33]


func _random_tier() -> int:
	# Kalau ranjau sudah terlalu menumpuk, paksa keluarkan makanan.
	if _blocked_ratio() > max_blocked_ratio:
		return _largest_edible_tier()

	var weights := _tier_weights()
	var total: int = weights[0] + weights[1] + weights[2]
	var roll := randi() % total
	for i in weights.size():
		if roll < weights[i]:
			return i
		roll -= weights[i]
	return TrashScript.Tier.KECIL


## Bagian isi sungai yang belum bisa dimakan ikan saat ini.
func _blocked_ratio() -> float:
	var total := 0
	var blocked := 0
	for child in get_children():
		if not child.is_in_group("trash"):
			continue
		total += 1
		if _player != null and _player.size_level < int(TrashScript.TIER_DATA[child.tier]["butuh_level"]):
			blocked += 1
	if total == 0:
		return 0.0
	return float(blocked) / float(total)


## Ukuran terbesar yang masih boleh dimakan ikan sekarang. Dipilih yang terbesar,
## bukan yang terkecil, supaya paksaan pasokan tetap memberi makanan bernilai.
func _largest_edible_tier() -> int:
	var level: int = _player.size_level if _player != null else 1
	for tier in [TrashScript.Tier.BESAR, TrashScript.Tier.SEDANG]:
		if level >= int(TrashScript.TIER_DATA[tier]["butuh_level"]):
			return tier
	return TrashScript.Tier.KECIL


# --- Kejadian berkala -------------------------------------------------------

func _spawn_beat() -> void:
	var level: int = _player.size_level if _player != null else 1
	var beat := _draw_beat()

	# Yang ditahan di awal permainan cuma PAGAR SAMPAH, bukan semua kejadian.
	#
	# Versi sebelumnya memblokir keempatnya sampai level 2, dan itu memakan
	# sepertiga awal permainan -- pemain baru merasakan variasi ketika hampir
	# selesai. Batang bambu dan arus deras sendiri tidak menghukum pemain kecil:
	# keduanya diberi aba-aba dan bisa dihindari. Pagar berbeda, dia menutup
	# jalan, dan itu tidak adil sebelum ikan punya ruang bermanuver.
	if level < 2 and beat == Beat.PAGAR:
		beat = Beat.GEROMBOLAN

	match beat:
		Beat.BAMBU:
			_warn_rush()
		Beat.DERAS:
			_start_surge()
		Beat.PAGAR:
			_spawn_hazard_wall(level)
		_:
			_spawn_shoal()


## Kantong acak, bukan lemparan dadu tiap kali.
##
## Ini perbaikan langsung dari playtest: dengan peluang bebas, sangat mungkin
## satu sesi cuma kebagian satu arus deras dan satu batang bambu, lalu sisanya
## gerombolan terus. Pemain menyimpulkan variasinya tidak ada. Dengan kantong,
## tiap jenis kejadian DIJAMIN muncul dalam satu putaran singkat.
##
## Isi kantongnya bergeser mengikuti tekanan: awal permainan lebih banyak
## hadiah, akhir permainan lebih banyak ujian.
func _draw_beat() -> int:
	if _beat_bag.is_empty():
		# Kantong dasar: SATU dari tiap jenis. Ini yang menjamin pemain merasakan
		# keempat rasa dalam waktu singkat -- tanpa ini, satu sesi bisa habis
		# tanpa pernah kena arus deras sekali pun.
		_beat_bag = [Beat.GEROMBOLAN, Beat.BAMBU, Beat.PAGAR, Beat.DERAS]
		# Sesudah tekanan lewat separuh, ditambah satu ronde ujian tanpa hadiah.
		if pressure() >= 0.5:
			_beat_bag.append(Beat.BAMBU)
			_beat_bag.append(Beat.PAGAR)
			_beat_bag.append(Beat.DERAS)
		_beat_bag.shuffle()
	return _beat_bag.pop_front()


## Gerombolan sampah kecil: momen "panen". Datang rapat supaya pemain bisa
## makan beruntun -- inilah hadiah yang bikin pemain betah.
func _spawn_shoal() -> void:
	var count := randi_range(7, 11)
	var centre := _entry_point()
	for i in count:
		var offset := Vector2(randf_range(-60.0, 120.0), randf_range(-80.0, 80.0))
		_spawn(TrashScript.Tier.KECIL, _clamp_to_water(centre + offset))


## Pagar sampah: satu kolom sampah besar melintang dengan SATU celah. Pemain
## harus menemukan celahnya dan menembus tepat waktu. Ini ujian gerak, bukan
## ujian refleks -- pagar hanyut pelan, jadi selalu ada jalan keluar.
func _spawn_hazard_wall(level: int) -> void:
	var tier: int = TrashScript.Tier.BESAR if level >= 3 else TrashScript.Tier.SEDANG
	# Pagar makin rapat saat tekanan tinggi: celahnya menyempit dari dua jarak
	# slot jadi satu setengah.
	var slots := 5 if pressure() < wall_tighten_at else 6
	var gap := randi() % slots
	var top := _water.position.y + vertical_margin
	var bottom := _water.end.y - vertical_margin
	var x := _water.end.x + spawn_offset_x

	for i in slots:
		if i == gap:
			continue
		var y := lerpf(top, bottom, float(i) / float(slots - 1))
		# Seluruh pagar hanyut dengan kecepatan sama supaya celahnya tetap
		# sejajar dan pemain bisa membaca polanya.
		_spawn(tier, Vector2(x, y + randf_range(-14.0, 14.0)), 52.0)


# --- Batang bambu hanyut ----------------------------------------------------

## Memasang aba-aba dulu, batangnya menyusul beberapa saat kemudian.
##
## Urutan ini yang membuatnya adil. Batang bambu melesat ~2x lebih cepat
## daripada ikan dan tidak bisa dimakan seukuran apa pun, jadi kalau langsung
## muncul, pemain cuma bisa selamat karena hafal atau beruntung. Dengan aba-aba,
## keputusannya jadi milik pemain: dia melihat tandanya, lalu memilih menyingkir.
func _warn_rush() -> void:
	if rush_scene == null:
		return

	var lead := lerpf(rush_lead_time.x, rush_lead_time.y, pressure())
	_queue_rush(lead)

	# Saat tekanan sudah tinggi, kadang datang dua sekaligus dari sisi berbeda
	# -- pemain tidak bisa lagi asal kabur ke satu tepi.
	if randf() < rush_double_chance_at_full * pressure():
		_queue_rush(lead + randf_range(0.35, 0.7))


func _queue_rush(lead: float) -> void:
	var side := 1 if randf() < 0.5 else -1
	var y := randf_range(_water.position.y + 90.0, _water.end.y - 90.0)
	_pending_rush.append({"left": lead, "side": side, "y": y})
	rush_warned.emit(side, y, lead)


func _tick_pending_rush(delta: float) -> void:
	# Ditelusuri dari belakang supaya menghapus di tengah tidak melompati elemen.
	for i in range(_pending_rush.size() - 1, -1, -1):
		var entry: Dictionary = _pending_rush[i]
		entry["left"] -= delta
		if entry["left"] > 0.0:
			continue
		_spawn_rush(int(entry["side"]), float(entry["y"]))
		_pending_rush.remove_at(i)


func _spawn_rush(side: int, y: float) -> void:
	var rush: Node2D = rush_scene.instantiate()
	# side = +1 berarti aba-abanya di tepi KANAN, jadi batangnya masuk dari
	# kanan dan melesat ke KIRI.
	rush.direction = -side
	rush.speed = lerpf(rush_speed.x, rush_speed.y, pressure())
	rush.world_width = _water.end.x
	rush.position = Vector2(_water.end.x + 200.0 if side > 0 else -200.0, y)
	add_child(rush)
	AudioManager.play("rush", -1.0, randf_range(0.94, 1.06))


# --- Arus deras -------------------------------------------------------------

## Seluruh isi sungai mendadak melesat ke kiri selama beberapa detik.
##
## Ini kejadian yang paling mengubah keadaan: yang tadinya makanan diam jadi
## sasaran bergerak, dan sampah besar yang tadinya bisa dihindari santai
## mendadak menyerbu. Tidak ada sampah baru yang dibuat selain satu gerombolan
## pengiring -- ketegangannya datang dari benda yang SUDAH ada, dan itu yang
## membuatnya murah tapi terasa besar.
func _start_surge() -> void:
	_surge_left = surge_duration
	_set_all_speed(surge_multiplier)
	_spawn_shoal()
	surge_started.emit(surge_duration)


func _tick_surge(delta: float) -> void:
	if _surge_left <= 0.0:
		return
	_surge_left -= delta
	if _surge_left <= 0.0:
		_end_surge()


func _end_surge() -> void:
	_surge_left = 0.0
	_set_all_speed(1.0)


func _set_all_speed(multiplier: float) -> void:
	for child in get_children():
		# Hanya sampah yang punya speed_multiplier. Batang bambu punya
		# kecepatannya sendiri dan tidak ikut terseret arus deras -- dia memang
		# sudah melesat.
		if child.is_in_group("trash"):
			child.speed_multiplier = multiplier


# --- Pembuatan node ---------------------------------------------------------

func _entry_point() -> Vector2:
	return Vector2(
		_water.end.x + spawn_offset_x,
		randf_range(_water.position.y + vertical_margin, _water.end.y - vertical_margin)
	)


func _clamp_to_water(point: Vector2) -> Vector2:
	return Vector2(
		point.x,
		clampf(point.y, _water.position.y + vertical_margin, _water.end.y - vertical_margin)
	)


## fixed_drift di atas 0 mengunci kecepatan hanyut, dipakai pagar sampah.
func _spawn(tier: int, point: Vector2, fixed_drift: float = -1.0) -> Node2D:
	var trash: Node2D = trash_scene.instantiate()
	# Semuanya diatur SEBELUM add_child(), karena _ready() milik sampah sudah
	# memakai nilai-nilai ini (memilih bentuk visual, mengacak gerak, dan
	# menyimpan jalur hanyutnya).
	trash.tier = tier
	trash.level_pemain = _player.size_level if _player != null else 1
	trash.position = point
	var flow := lerpf(1.0, current_speedup_at_full, pressure())
	if fixed_drift > 0.0:
		trash.drift_speed_range = Vector2(fixed_drift, fixed_drift) * flow
	else:
		trash.drift_speed_range *= flow
	# Sampah yang lahir di tengah arus deras harus ikut melesat juga, kalau
	# tidak dia terlihat seperti berdiri diam di tengah banjir.
	if _surge_left > 0.0:
		trash.speed_multiplier = surge_multiplier
	add_child(trash)
	return trash
