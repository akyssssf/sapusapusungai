extends Node2D
## INDUK SAPU-SAPU -- bos Kali Brantas.
##
## Rancangannya bertumpu pada satu ide: sapu-sapu itu berpelat keras, jadi
## menabraknya dari mana saja PERCUMA. Satu-satunya cara melukainya adalah
## menggigit INSANG, yang cuma terbuka sesaat setelah dia kehabisan tenaga.
##
## Setiap putaran berjalan begini:
##
##   INCAR   -- bos menghadap pemain dan memasang ABA-ABA serangan berikutnya.
##              Aman. Aba-abanya berbeda untuk tiap serangan, dan itu inti
##              pertarungannya: pemain membaca aba-aba, lalu memilih jawabannya.
##   SERANG  -- satu dari tiga, diacak dengan kantong tanpa pengulangan:
##                SEDOT   : menarik pemain ke mulut. Jawaban: berenang menjauh.
##                TERJANG : menyeruduk lurus menyusuri satu jalur. Jawaban:
##                          KELUAR dari jalurnya, bukan lari lurus ke depan.
##                HUJAN   : menyemprot sampah berputar beberapa gelombang.
##                          Jawaban: terus bergerak menyelip di antara celah.
##   LEMAH   -- insang menyala. INI JENDELANYA. Panjangnya BEDA-BEDA menurut
##              serangan tadi: habis menyeruduk dia paling lama terhuyung,
##              habis menyemprot paling cepat pulih.
##   PINDAH  -- berenang ke sisi arena yang berlawanan, lalu mengulang.
##
## Kenapa tiga serangan, bukan satu? Karena satu serangan yang diulang-ulang
## berhenti jadi keputusan setelah dua putaran; yang tersisa cuma pekerjaan.
## Dengan tiga pola yang jawabannya berbeda -- menjauh, keluar jalur, menyelip --
## pemain harus tetap membaca sampai pelat terakhir.

signal plates_changed(current: int, maximum: int)
signal defeated
## Dipancarkan saat bos bersiap menyeruduk. Sengaja memakai bentuk yang sama
## dengan peringatan batang bambu, supaya pemain tidak perlu belajar bahasa
## baru: garis merah selalu berarti "ada yang melesat lewat jalur ini".
signal charge_warned(side: int, world_y: float, lead_time: float)

enum Phase { MASUK, INCAR, SEDOT, TERJANG, HUJAN, LEMAH, MUNDUR, PINDAH, MATI }

@export var max_plates: int = 5
@export var spit_scene: PackedScene

@export_group("Waktu tiap fase")
@export var aim_time: float = 1.05
@export var suck_time: float = 2.2
@export var weak_time: float = 2.1
## Lama bos tersentak mundur sesudah insangnya digigit. Selama fase ini badannya
## TIDAK berbahaya -- lihat penjelasan di _enter_phase().
@export var recoil_time: float = 0.55
@export var move_time: float = 1.2
## Tiap pelat yang pecah memotong durasi semua fase sebanyak ini.
@export var haste_per_plate: float = 0.08

@export_group("Sedotan")
@export var suction_radius: float = 620.0
## Kecepatan tarik (piksel/detik) tepat di depan mulut. Sengaja DI BAWAH
## kecepatan renang pemain saat ukuran maksimum (~410 px/dtk).
@export var suction_pull_speed: float = 275.0

@export_group("Terjangan")
@export var charge_speed: float = 1000.0
## Batas waktu; normalnya terjangan berhenti karena sudah sampai tepi arena.
@export var charge_max_time: float = 2.2
## Seberapa cepat bos meluruskan badan ke jalur yang dikunci saat aba-aba.
@export var charge_align_speed: float = 7.0

@export_group("Hujan sampah")
@export var hujan_waves: int = 3
@export var hujan_per_wave: int = 5
@export var hujan_wave_gap: float = 0.4
@export var hujan_arc_deg: float = 200.0
@export var spit_speed: float = 620.0

@export_group("Gerak")
@export var swim_speed: float = 230.0
## Kecepatan khusus saat masuk arena; jaraknya panjang, jadi jauh lebih tinggi.
@export var entry_speed: float = 480.0
## Kecepatan mundur sesudah kena gigit.
@export var recoil_speed: float = 430.0

var plates: int = 5

@onready var _visual: Node2D = $Visual
@onready var _gill_glow: Polygon2D = $Visual/GillGlow
@onready var _mouth_inner: Polygon2D = $Visual/MouthInner
@onready var _body_hitbox: Area2D = $BodyHitbox
@onready var _mouth_zone: Area2D = $MouthZone
@onready var _weak_point: Area2D = $WeakPoint
@onready var _suction_fx: CPUParticles2D = $SuctionFX

## Posisi mulut & insang saat bos menghadap KANAN. Saat menghadap kiri,
## keduanya dicerminkan lewat _set_facing(). Area2D sengaja tidak ikut
## di-scale negatif, karena skala negatif pada bentuk fisika bikin masalah.
const MOUTH_OFFSET := Vector2(158.0, 12.0)
const WEAK_OFFSET := Vector2(100.0, 2.0)

## Jarak minimal titik tengah bos dari tepi arena.
##
## Ini BUKAN angka estetika. Insang menjulur 100 px dan mulut 158 px dari titik
## tengah, sedangkan pemain sendiri tidak boleh keluar dari kolom air. Kalau bos
## boleh menempel ke tepi, insangnya berakhir di luar batas renang pemain dan
## bosnya jadi mustahil dilukai.
const ARENA_MARGIN_X := 240.0
const ARENA_MARGIN_TOP := 190.0
const ARENA_MARGIN_BOTTOM := 170.0

## Panjang jendela LEMAH sesudah tiap serangan, sebagai pengali weak_time.
##
## Ini yang membuat ketiga serangan terasa punya harga berbeda. Menghindari
## terjangan paling sulit, jadi hadiahnya paling besar; selamat dari hujan
## sampah relatif mudah, jadi jendelanya paling sempit.
const WEAK_WINDOW := {
	Phase.SEDOT: 1.0,
	Phase.TERJANG: 1.4,
	Phase.HUJAN: 0.8,
}

var _phase: int = Phase.MASUK
var _phase_left: float = 0.0
## 0 = belum ditentukan. JANGAN diisi 1 atau -1 di sini: _set_facing() keluar
## lebih awal kalau nilainya sudah sama, jadi nilai awal yang menebak-nebak akan
## membuat bos berenang mundur seumur hidup karena flip pertamanya dilewati.
var _facing: int = 0
var _player: Node2D = null
var _arena: Rect2 = Rect2()
var _move_target: Vector2 = Vector2.ZERO
var _hit_this_window: bool = false

## Serangan yang sedang diaba-abakan pada fase INCAR.
var _next_attack: int = Phase.SEDOT
var _last_attack: int = -1
## Kantong pengacak. Lihat _draw_attack().
var _attack_bag: Array = []
## Serangan yang barusan dijalankan, dipakai menentukan panjang jendela LEMAH.
var _attack_just_done: int = Phase.SEDOT

var _charge_dir: int = 1
var _charge_y: float = 0.0
var _hujan_left: int = 0
var _hujan_cooldown: float = 0.0
var _hujan_angle: float = 0.0


func _ready() -> void:
	add_to_group("boss")
	plates = max_plates
	_gill_glow.visible = false
	_weak_point.monitoring = false
	_mouth_zone.monitoring = false
	_body_hitbox.monitoring = false
	_suction_fx.emitting = false


## Dipanggil map_manager sesudah bos dimasukkan ke scene.
func setup(player: Node2D, arena: Rect2) -> void:
	_player = player
	_arena = arena
	plates_changed.emit(plates, max_plates)
	_enter_phase(Phase.MASUK)


func _physics_process(delta: float) -> void:
	if _phase == Phase.MATI or _player == null:
		return

	_phase_left -= delta
	_check_contacts()

	match _phase:
		Phase.MASUK:
			_swim_towards(_move_target, delta, entry_speed)
			# Pindah fase saat SUDAH TIBA, bukan saat hitungan waktu habis.
			# Versi berbasis waktu membuat bos berhenti di mana pun dia berada
			# ketika waktunya habis -- dan karena dia berangkat dari luar layar,
			# tempat berhentinya ada di luar arena, sehingga insangnya tidak
			# akan pernah bisa dijangkau pemain.
			if global_position.distance_to(_move_target) < 28.0 or _phase_left <= 0.0:
				_enter_phase(Phase.INCAR)
		Phase.INCAR:
			_tick_telegraph()
			if _phase_left <= 0.0:
				_enter_phase(_next_attack)
		Phase.SEDOT:
			_apply_suction(delta)
			if _phase_left <= 0.0:
				_finish_attack(Phase.SEDOT)
		Phase.TERJANG:
			if _tick_charge(delta):
				_finish_attack(Phase.TERJANG)
		Phase.HUJAN:
			_tick_hujan(delta)
			if _phase_left <= 0.0:
				_finish_attack(Phase.HUJAN)
		Phase.LEMAH:
			# Megap-megap: mulut membuka-menutup pelan, insang berdenyut.
			# Denyut ini bukan hiasan -- inilah satu-satunya isyarat "serang
			# sekarang", jadi harus mencolok dan tidak bisa disalahartikan.
			_mouth_inner.scale = Vector2.ONE * (0.75 + 0.25 * sin(_phase_left * 9.0))
			_gill_glow.modulate.a = 0.7 + 0.3 * sin(_phase_left * 11.0)
			if _phase_left <= 0.0:
				_enter_phase(Phase.PINDAH)
		Phase.MUNDUR:
			# Mundur tanpa memutar badan: bos tetap menghadap pemain sambil
			# tersentak ke belakang, jadi terlihat kesakitan, bukan kabur.
			_swim_towards(_move_target, delta, recoil_speed, false)
			if _phase_left <= 0.0:
				_enter_phase(Phase.PINDAH)
		Phase.PINDAH:
			_swim_towards(_move_target, delta)
			if _phase_left <= 0.0:
				_enter_phase(Phase.INCAR)


# --- Mesin fase -------------------------------------------------------------

## Pengali durasi. Makin sedikit pelat tersisa, makin pendek semua fasenya.
func _haste() -> float:
	return maxf(1.0 - haste_per_plate * float(max_plates - plates), 0.45)


## Sesudah serangan apa pun, selalu masuk ke jendela LEMAH -- panjangnya
## menyesuaikan serangan yang barusan dilakukan.
func _finish_attack(which: int) -> void:
	_attack_just_done = which
	_enter_phase(Phase.LEMAH)


func _enter_phase(next_phase: int) -> void:
	_phase = next_phase
	_visual.position = Vector2.ZERO
	_visual.modulate = Color.WHITE
	_visual.scale = Vector2(float(_facing if _facing != 0 else 1), 1.0)

	# Semua yang khusus satu fase dimatikan dulu di sini, supaya tiap cabang di
	# bawah cuma perlu menyalakan miliknya sendiri. Pola ini mencegah bug
	# "insang lupa dimatikan" yang klasik pada mesin fase buatan tangan.
	#
	# monitoring diubah lewat set_deferred() karena _enter_phase() kadang
	# dipanggil dari dalam pemeriksaan sentuhan, dan Godot melarang mengubah
	# state Area2D di tengah langkah fisika yang sedang berjalan.
	_gill_glow.visible = false
	_weak_point.set_deferred("monitoring", false)
	_mouth_zone.set_deferred("monitoring", false)
	_suction_fx.emitting = false
	_mouth_inner.scale = Vector2.ONE

	# Badan berpelat hanya berbahaya saat bos bertenaga. Ini BUKAN kemurahan
	# hati: insang yang jadi sasaran berada di DALAM jangkauan hitbox badan,
	# jadi kalau badan tetap menyakitkan saat LEMAH, menyerang titik lemahnya
	# justru selalu merugikan dan bosnya jadi mustahil dikalahkan dengan adil.
	#
	# MUNDUR juga ikut aman: begitu insang digigit, fase langsung berganti
	# sementara pemain masih menempel di badan bos.
	var body_dangerous: bool = next_phase == Phase.INCAR \
		or next_phase == Phase.SEDOT \
		or next_phase == Phase.TERJANG \
		or next_phase == Phase.HUJAN \
		or next_phase == Phase.PINDAH
	_body_hitbox.set_deferred("monitoring", body_dangerous)

	match next_phase:
		Phase.MASUK:
			# Pengaman saja; fase ini normalnya berakhir karena sudah TIBA.
			_phase_left = 6.0
			_move_target = _clamped_position(_arena.get_center() + Vector2(180.0, -40.0))
		Phase.INCAR:
			_phase_left = aim_time * _haste()
			_begin_telegraph()
		Phase.SEDOT:
			_phase_left = suck_time * _haste()
			_mouth_zone.set_deferred("monitoring", true)
			_suction_fx.emitting = true
			_mouth_inner.scale = Vector2.ONE * 1.35
			AudioManager.play("boss_suck", -1.0, 1.0, 0.02)
		Phase.TERJANG:
			_phase_left = charge_max_time
			_mouth_zone.set_deferred("monitoring", true)
			AudioManager.play("rush", 1.0, 0.75, 0.03)
		Phase.HUJAN:
			_hujan_left = hujan_waves
			_hujan_cooldown = 0.0
			_hujan_angle = (_player.global_position - global_position).angle()
			_phase_left = (hujan_waves + 0.6) * hujan_wave_gap
		Phase.LEMAH:
			var window: float = WEAK_WINDOW.get(_attack_just_done, 1.0)
			_phase_left = weak_time * window * _haste()
			_gill_glow.visible = true
			_weak_point.set_deferred("monitoring", true)
			_hit_this_window = false
		Phase.MUNDUR:
			_phase_left = recoil_time
			var away := global_position - _player.global_position
			if away.is_zero_approx():
				away = Vector2.RIGHT
			_move_target = _clamped_position(global_position + away.normalized() * 260.0)
		Phase.PINDAH:
			_phase_left = move_time * _haste()
			_move_target = _pick_move_target()
		Phase.MATI:
			_phase_left = 0.0


# --- Pemilihan & aba-aba serangan -------------------------------------------

## Kantong acak, bukan lemparan dadu tiap kali.
##
## Kalau tiap putaran memilih acak bebas, sangat mungkin serangan yang sama
## keluar empat kali berturut-turut -- dan pemain akan menyimpulkan bosnya cuma
## punya satu jurus. Dengan kantong, ketiga serangan dijamin muncul sekali
## sebelum ada yang boleh terulang.
func _draw_attack() -> int:
	if _attack_bag.is_empty():
		_attack_bag = [Phase.SEDOT, Phase.TERJANG, Phase.HUJAN]
		_attack_bag.shuffle()
		# Cegah kantong baru dibuka dengan serangan yang sama seperti penutup
		# kantong sebelumnya; itu satu-satunya celah pengulangan yang tersisa.
		if _attack_bag[0] == _last_attack and _attack_bag.size() > 1:
			_attack_bag.append(_attack_bag.pop_front())
	_last_attack = _attack_bag.pop_front()
	return _last_attack


func _begin_telegraph() -> void:
	_face_player()
	_next_attack = _draw_attack()

	if _next_attack != Phase.TERJANG:
		return

	# Terjangan mengunci jalurnya SEKARANG, bukan saat mulai melesat. Kalau
	# arahnya dihitung belakangan, bos akan seperti mengejar pemain dan
	# menghindar jadi mustahil. Dikunci lebih dulu = keputusan milik pemain.
	_charge_dir = 1 if _player.global_position.x > global_position.x else -1
	_charge_y = clampf(_player.global_position.y,
		_arena.position.y + ARENA_MARGIN_TOP, _arena.end.y - ARENA_MARGIN_BOTTOM)
	_set_facing(_charge_dir)
	# Aba-aba dipasang di tepi yang bos datangi, memakai penanda yang sama
	# persis dengan batang bambu.
	charge_warned.emit(-_charge_dir, _charge_y, _phase_left)
	AudioManager.play("warning", 0.0, 0.82, 0.0)


## Getaran dan warna badan selama INCAR, berbeda untuk tiap serangan supaya
## pemain bisa mengenalinya sebelum serangannya keluar.
func _tick_telegraph() -> void:
	var progress := 1.0 - _phase_left / maxf(aim_time * _haste(), 0.01)
	match _next_attack:
		Phase.SEDOT:
			# Bergetar di tempat sambil mulut mulai menganga.
			_visual.position.x = randf_range(-3.0, 3.0)
			_mouth_inner.scale = Vector2.ONE * (1.0 + 0.35 * progress)
		Phase.TERJANG:
			# Menarik badan ke belakang seperti ancang-ancang, memerah.
			_visual.position.x = -_charge_dir * 18.0 * progress
			_visual.modulate = Color(1.5, 0.72, 0.62)
			global_position.y = lerpf(global_position.y, _charge_y, 0.08)
		Phase.HUJAN:
			# Menggembung: badan membesar-mengempis cepat.
			var puff := 1.0 + 0.09 * sin(_phase_left * 22.0)
			_visual.scale = Vector2(float(_facing) * puff, puff)
			_visual.modulate = Color(1.35, 1.25, 0.7)


# --- Terjangan --------------------------------------------------------------

## Mengembalikan true kalau terjangannya sudah selesai.
func _tick_charge(delta: float) -> bool:
	var target_x: float = _arena.end.x - ARENA_MARGIN_X if _charge_dir > 0 \
		else _arena.position.x + ARENA_MARGIN_X

	global_position.x = move_toward(global_position.x, target_x, charge_speed * delta)
	global_position.y = lerpf(global_position.y, _charge_y, clampf(charge_align_speed * delta, 0.0, 1.0))

	if absf(global_position.x - target_x) > 2.0 and _phase_left > 0.0:
		return false

	# Menghantam tepi sungai: berhenti mendadak, lumpur beterbangan.
	_player.camera.shake(20.0)
	AudioManager.play("boss_hit", -3.0, 0.55, 0.0)
	return true


# --- Hujan sampah -----------------------------------------------------------

func _tick_hujan(delta: float) -> void:
	if _hujan_left <= 0:
		return
	_hujan_cooldown -= delta
	if _hujan_cooldown > 0.0:
		return
	_hujan_cooldown = hujan_wave_gap
	_hujan_left -= 1
	_fire_wave()


## Satu gelombang: kipas lebar berpusat pada arah pemain saat serangan dimulai,
## lalu diputar sedikit tiap gelombang. Putaran itu yang menciptakan celah
## bergerak -- pemain tidak bisa berdiri di satu titik aman sampai selesai.
func _fire_wave() -> void:
	if spit_scene == null:
		return

	var arc := deg_to_rad(hujan_arc_deg)
	var step := arc / float(maxi(hujan_per_wave - 1, 1))
	var offset := (float(hujan_waves - _hujan_left) - 1.0) * step * 0.45
	var origin := _mouth_zone.global_position

	for i in hujan_per_wave:
		var angle := _hujan_angle - arc * 0.5 + step * i + offset
		var spit: Node2D = spit_scene.instantiate()
		spit.position = origin
		spit.velocity = Vector2.RIGHT.rotated(angle) * spit_speed
		get_parent().add_child(spit)

	AudioManager.play("boss_spit", 0.0, 0.9)


# --- Gerak ------------------------------------------------------------------

func _pick_move_target() -> Vector2:
	# Bos selalu pindah ke sisi arena yang BERLAWANAN dengan pemain, jadi
	# pemain harus mengejar dan tidak bisa berdiam di satu pojok aman.
	var far_x: float = _arena.position.x + ARENA_MARGIN_X
	if _player.global_position.x < _arena.get_center().x:
		far_x = _arena.end.x - ARENA_MARGIN_X
	return _clamped_position(Vector2(far_x, randf_range(_arena.position.y, _arena.end.y)))


func _swim_towards(target: Vector2, delta: float, speed: float = -1.0, face_travel: bool = true) -> void:
	var use_speed := speed if speed > 0.0 else swim_speed
	if face_travel and absf(target.x - global_position.x) > 24.0:
		_set_facing(1 if target.x > global_position.x else -1)
	global_position = global_position.move_toward(target, use_speed * delta)

	# Selama MASUK bos memang masih di luar arena, jadi jangan dipaksa masuk --
	# nanti dia seperti meloncat ke dalam layar.
	if _phase != Phase.MASUK:
		global_position = _clamped_position(global_position)


## Posisi terdekat yang masih menyisakan ruang untuk insang dan mulut.
func _clamped_position(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, _arena.position.x + ARENA_MARGIN_X, _arena.end.x - ARENA_MARGIN_X),
		clampf(point.y, _arena.position.y + ARENA_MARGIN_TOP, _arena.end.y - ARENA_MARGIN_BOTTOM)
	)


func _face_player() -> void:
	_set_facing(1 if _player.global_position.x > global_position.x else -1)


func _set_facing(dir: int) -> void:
	if dir == _facing:
		return
	_facing = dir
	_visual.scale.x = float(dir)
	_mouth_zone.position = Vector2(MOUTH_OFFSET.x * dir, MOUTH_OFFSET.y)
	_weak_point.position = Vector2(WEAK_OFFSET.x * dir, WEAK_OFFSET.y)
	_suction_fx.position = _mouth_zone.position


# --- Sedotan ----------------------------------------------------------------

func _apply_suction(delta: float) -> void:
	var mouth := _mouth_zone.global_position
	var to_mouth := mouth - _player.global_position
	var distance := to_mouth.length()
	if distance > suction_radius or distance < 1.0:
		return

	# Tarikan paling kuat tepat di depan mulut dan meluruh sampai nol di tepi
	# radius. Kuadratnya membuat zona luar terasa ringan dan zona dalam terasa
	# panik -- itu yang bikin pemain rela mendekat lalu buru-buru kabur.
	var closeness := 1.0 - distance / suction_radius
	var pull := suction_pull_speed * closeness * closeness

	# Pemain digeser POSISINYA, bukan ditambah kecepatannya. Kalau lewat
	# velocity, baris move_toward() di player_fish.gd akan langsung menghapus
	# tarikan itu pada frame yang sama dan sedotan jadi tidak terasa apa-apa.
	_player.global_position += to_mouth.normalized() * pull * delta


# --- Sentuhan ---------------------------------------------------------------

## Semua sentuhan diperiksa dengan MELIHAT TUMPANG TINDIH tiap frame, bukan
## lewat sinyal body_entered.
##
## body_entered hanya menyala pada detik MASUK. Karena hitbox bos dinyalakan dan
## dimatikan setiap pergantian fase, pemain sering sudah berada di dalam area
## itu tepat ketika hitboxnya menyala -- terutama sesudah tersedot ke arah
## mulut. Dengan sinyal, gigitan seperti itu hilang tanpa jejak.
func _check_contacts() -> void:
	if _player == null:
		return

	# Insang diperiksa lebih dulu supaya serangan yang berhasil selalu menang
	# atas sentuhan badan pada frame yang sama.
	if _phase == Phase.LEMAH and not _hit_this_window \
			and _weak_point.monitoring and _touching(_weak_point):
		_hit_this_window = true
		_take_plate_damage(_player)
		return

	if _mouth_zone.monitoring and _touching(_mouth_zone):
		_player.take_damage(1, _mouth_zone.global_position)
	elif _body_hitbox.monitoring and _touching(_body_hitbox):
		_player.take_damage(1, global_position)


func _touching(area: Area2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body == _player:
			return true
	return false


func _take_plate_damage(player: Node2D) -> void:
	plates = maxi(plates - 1, 0)
	plates_changed.emit(plates, max_plates)

	player.camera.shake(22.0)
	# Nada dinaikkan tiap pelat pecah -- telinga pemain ikut menghitung mundur
	# tanpa perlu melihat bar nyawa bos.
	AudioManager.play("boss_hit", 1.0, 0.9 + 0.09 * float(max_plates - plates))

	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(2.0, 1.6, 1.6), 0.06)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.28)

	if plates <= 0:
		_die()
		return

	# Pemain ikut terdorong menjauh dan diberi kebal singkat. Dua-duanya perlu:
	# dorongan memisahkan badan mereka, dan kebal menutup celah satu-dua frame
	# sebelum hitbox badan bos menyala lagi.
	var away := player.global_position - global_position
	if away.is_zero_approx():
		away = Vector2.UP
	player.velocity = away.normalized() * 340.0
	player.grant_mercy(recoil_time + 0.25)

	_enter_phase(Phase.MUNDUR)


func _die() -> void:
	_enter_phase(Phase.MATI)
	AudioManager.play("boss_defeated", 1.0, 1.0, 0.0)
	_body_hitbox.set_deferred("monitoring", false)
	set_physics_process(false)

	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(_visual, "rotation", deg_to_rad(140.0), 1.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_visual, "modulate", Color(0.45, 0.5, 0.55, 0.0), 1.1)
	tween.chain().tween_callback(func(): defeated.emit())
