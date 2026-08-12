extends CharacterBody2D
## Ikan wader yang dikendalikan pemain (dipakai Map 1 dan Map 2).
##
## Tanggung jawabnya tiga:
##   1. Bergerak bebas dengan akselerasi + hambatan air.
##   2. Menyimpan ukuran (size_level) dan membesar ketika diberi "growth".
##   3. Menyimpan nyawa dan menangani kena serang.
##
## File ini TIDAK menyebut kata "sampah" atau "bos" sama sekali. Yang menabrak
## ikan-lah yang memanggil add_growth() atau take_damage(). Arah ketergantungan
## sengaja satu arah supaya ikan lokal (Map 2) dan sapu-sapu bisa ditambahkan
## tanpa mengubah file ini sedikit pun.

signal size_level_changed(new_level: int)
signal health_changed(current: int, maximum: int)
signal dashed
signal died

enum ControlScheme {
	KEYBOARD, ## WASD / tombol panah -- untuk build Windows.
	POINTER,  ## Berenang ke arah kursor atau sentuhan -- calon kontrol Android.
}

@export_group("Kontrol")
@export var control_scheme: ControlScheme = ControlScheme.KEYBOARD
## Radius mati di sekitar ikan. Kalau kursor ada di dalamnya, ikan berhenti.
@export var pointer_dead_zone: float = 28.0
## Kalau true, ikan hanya berenang selama tombol/jari ditahan (untuk Android).
@export var pointer_requires_hold: bool = false

@export_group("Gerak")
## Kecepatan maksimum saat size_level == 1, dalam piksel per detik.
@export var max_speed: float = 340.0
## Seberapa cepat ikan mencapai kecepatan maksimum (piksel per detik kuadrat).
@export var acceleration: float = 1500.0
## Perlambatan saat tidak ada input. Angka kecil = meluncur lama = terasa berair.
@export var water_drag: float = 750.0
## Pengali SELURUH profil gerak (kecepatan, akselerasi, rem) tiap naik level.
##
## Sengaja DI ATAS 1.0: ikan besar jadi sedikit lebih ngebut, bukan makin berat.
## Karena akselerasi dan rem ikut dikalikan, rasa kontrolnya tetap setajam saat
## kecil -- yang berubah cuma skalanya. Kamera juga menjauh sedikit saat ikan
## membesar (lihat game_camera.gd), jadi kalau angka ini dibuat 1.0 atau kurang,
## ikan besar akan terasa merayap di layar.
@export var speed_scale_per_level: float = 1.05
## Sprite baru dibalik kalau kecepatan horizontal melewati angka ini.
@export var flip_threshold: float = 8.0

@export_group("Dash")
## Pengali kecepatan selama dash. 3.2 berarti sekejap tiga kali lipat.
@export var dash_speed_multiplier: float = 3.2
## Lama melesat. Sangat pendek -- dash itu satu hentakan, bukan mode ngebut.
@export var dash_duration: float = 0.18
## Jeda sebelum boleh dash lagi.
@export var dash_cooldown: float = 1.1
## Kalau true, ikan kebal selama melesat sehingga dash bisa dipakai menembus
## sampah besar. Sengaja dimatikan secara bawaan: begitu dash bisa menembus apa
## saja, pagar sampah dan sedotan bos berhenti jadi ancaman. Nyalakan lewat
## Inspector kalau saat playtest ternyata terlalu sulit.
@export var dash_grants_invulnerability: bool = false

@export_group("Animasi badan")
## Kemiringan badan maksimum saat berenang naik/turun, dalam derajat.
@export var max_tilt_deg: float = 20.0
@export var tilt_response: float = 8.0
## Besar liukan badan saat berenang, dalam derajat kemiringan (skew).
@export var wiggle_deg: float = 9.0

@export_group("Ukuran")
@export var max_size_level: int = 5
## Poin pertumbuhan yang dibutuhkan untuk naik satu level.
##
## Dinaikkan dari 100 setelah playtest: dengan peta yang lebih rapat, ikan
## mencapai ukuran maksimum sebelum pemain sempat merasakan satu putaran penuh
## kejadian di sungai. Angka ini yang menentukan panjang babak berburu, jadi
## di sinilah tempo permainan disetel -- bukan di kecepatan renang.
@export var growth_per_level: float = 350.0
## Skala sprite di level 1 dan di level maksimum. Nilainya kecil karena
## teksturnya diambil dari folder PNG/Double (128 px) supaya tidak pecah.
@export var scale_at_level_1: float = 0.115
@export var scale_at_max_level: float = 0.27
## Radius tabrakan saat skala visual tepat 1.0 (~40% lebar tekstur).
@export var base_radius: float = 50.0

@export_group("Nyawa")
@export var max_health: int = 3
## Lama kebal setelah kena serang, dalam detik. Selama ini ikan berkedip dan
## tidak bisa kena lagi -- tanpa jeda ini satu tabrakan bisa menghabiskan
## semua nyawa dalam sepersekian detik.
@export var invulnerable_time: float = 1.3
## Seberapa keras ikan terpental menjauh dari sumber serangan.
@export var knockback_force: float = 460.0

var size_level: int = 1
var growth: float = 0.0
var health: int = 3

## Kotak area renang. Diisi oleh map_manager saat map dimuat, BUKAN di sini,
## karena batas sungai itu milik map -- bukan milik ikan.
var swim_bounds: Rect2 = Rect2()

@onready var _sprite: SpriteIkan = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _dash_trail: CPUParticles2D = $DashTrail
@onready var camera: Camera2D = $Camera2D

var _scale_tween: Tween
var _has_custom_actions: bool = false
var _wiggle_time: float = 0.0
var _invulnerable_left: float = 0.0
var _control_locked: bool = false
var _dash_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	health = max_health
	# Dicek sekali di awal, bukan tiap frame: kalau Input Map di project.godot
	# belum terbaca, kontrol tetap jalan lewat aksi bawaan Godot (ui_left dsb).
	_has_custom_actions = InputMap.has_action("swim_left")
	_apply_size(false)
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	var direction := _read_input()

	_tick_dash(delta)
	if _dash_pressed():
		_try_dash(direction)

	if _dash_left > 0.0:
		# Selama melesat, kecepatan DIPAKSA, tidak dihitung lewat akselerasi.
		# Itu inti dash: hentakan yang tidak bisa direm setengah jalan, jadi
		# pemain harus memilih arahnya dengan yakin sebelum menekan tombol.
		velocity = _dash_direction * current_max_speed() * dash_speed_multiplier
	elif direction.is_zero_approx():
		# Tidak ada input: air memperlambat ikan sampai berhenti sendiri.
		velocity = velocity.move_toward(Vector2.ZERO, current_water_drag() * delta)
	else:
		# move_toward() menarik vektor kecepatan ke arah target sejauh
		# (akselerasi * delta) per frame. Efek sampingnya bagus: berbelok tajam
		# terasa "melawan air" karena kecepatan lama harus dibatalkan dulu.
		velocity = velocity.move_toward(direction * current_max_speed(), current_acceleration() * delta)

	move_and_slide()
	_keep_inside_bounds()
	_face_swim_direction()
	_tilt_body(delta)
	_wiggle_body(delta)
	_tick_invulnerability(delta)


# --- Input ------------------------------------------------------------------

func _read_input() -> Vector2:
	# Saat terpental kena serang, kontrol dikunci sebentar supaya pentalannya
	# benar-benar terasa dan bukan langsung dibatalkan oleh tombol pemain.
	if _control_locked:
		return Vector2.ZERO
	match control_scheme:
		ControlScheme.POINTER:
			return _pointer_direction()
		_:
			return _keyboard_direction()


func _keyboard_direction() -> Vector2:
	# get_vector() sudah menormalkan hasilnya, jadi gerak diagonal tidak jadi
	# 1.41x lebih cepat daripada gerak lurus -- bug klasik game 2D buatan tangan.
	if _has_custom_actions:
		return Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func _pointer_direction() -> Vector2:
	if pointer_requires_hold and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return Vector2.ZERO
	var to_pointer := get_global_mouse_position() - global_position
	if to_pointer.length() <= pointer_dead_zone:
		return Vector2.ZERO
	return to_pointer.normalized()


# --- Dash -------------------------------------------------------------------

func _dash_pressed() -> bool:
	# Sama seperti arah gerak: kalau aksi "dash" belum ada di Input Map,
	# jatuh ke aksi bawaan Godot supaya kontrolnya tidak mati total.
	if InputMap.has_action("dash"):
		return Input.is_action_just_pressed("dash")
	return Input.is_action_just_pressed("ui_select")


## direction = arah yang sedang ditekan pemain (boleh nol).
func _try_dash(direction: Vector2) -> void:
	if _dash_cooldown_left > 0.0 or _dash_left > 0.0 or _control_locked:
		return

	var dir := direction
	if dir.is_zero_approx():
		# Tidak sedang menekan arah apa pun: melesat ke arah hadap sekarang.
		# Tanpa cadangan ini, dash terasa "rusak" saat pemain hanya menekan
		# tombolnya tanpa arah.
		dir = Vector2.LEFT if _sprite.menghadap_kiri() else Vector2.RIGHT

	_dash_direction = dir.normalized()
	_dash_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	_dash_trail.emitting = true

	if dash_grants_invulnerability:
		_invulnerable_left = maxf(_invulnerable_left, dash_duration)

	camera.shake(7.0)
	# Ikan besar mendorong air lebih banyak, jadi desisnya lebih berat.
	AudioManager.play("dash", -1.0, 1.12 - 0.05 * (size_level - 1))
	dashed.emit()


func _tick_dash(delta: float) -> void:
	if _dash_left > 0.0:
		_dash_left -= delta
		if _dash_left <= 0.0:
			_dash_trail.emitting = false
			# Kecepatan dipangkas ke kecepatan renang biasa saat dash selesai,
			# bukan dibiarkan. Kalau dibiarkan, ikan meluncur jauh melewati
			# sasaran dan dash jadi susah dipakai untuk manuver presisi.
			velocity = velocity.limit_length(current_max_speed())
	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)


func is_dashing() -> bool:
	return _dash_left > 0.0


## 0.0 (baru dipakai) sampai 1.0 (siap lagi). Dibaca HUD.
func dash_ratio() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cooldown_left / dash_cooldown, 0.0, 1.0)


# --- Profil gerak menurut ukuran --------------------------------------------

## Satu pengali dipakai untuk kecepatan, akselerasi, DAN rem sekaligus. Kalau
## hanya kecepatan yang dinaikkan, ikan besar akan terasa melayang dan susah
## dihentikan; kalau ketiganya naik bersama, rasanya tetap sama tajamnya.
func size_speed_multiplier() -> float:
	return pow(speed_scale_per_level, size_level - 1)


func current_max_speed() -> float:
	return max_speed * size_speed_multiplier()


func current_acceleration() -> float:
	return acceleration * size_speed_multiplier()


func current_water_drag() -> float:
	return water_drag * size_speed_multiplier()


# --- Batas renang -----------------------------------------------------------

func _keep_inside_bounds() -> void:
	# Sungai dibatasi dengan clamp posisi, bukan dinding StaticBody2D. Untuk
	# prototipe ini lebih mudah dipahami dan tidak ada risiko ikan nyangkut.
	if swim_bounds.size.is_zero_approx():
		return

	var r: float = _collision.shape.radius
	var target_x := clampf(global_position.x, swim_bounds.position.x + r, swim_bounds.end.x - r)
	var target_y := clampf(global_position.y, swim_bounds.position.y + r, swim_bounds.end.y - r)

	# Kecepatan pada sumbu yang tertahan dinolkan. Tanpa ini, menahan tombol ke
	# arah dinding akan menumpuk kecepatan diam-diam, lalu ikan melesat begitu
	# tombolnya dilepas.
	if not is_equal_approx(target_x, global_position.x):
		global_position.x = target_x
		velocity.x = 0.0
	if not is_equal_approx(target_y, global_position.y):
		global_position.y = target_y
		velocity.y = 0.0


# --- Animasi badan ----------------------------------------------------------

func _face_swim_direction() -> void:
	# Sprite ikan Kenney menghadap ke KANAN secara bawaan.
	if absf(velocity.x) > flip_threshold:
		_sprite.hadap(velocity.x < 0.0)


func _tilt_body(delta: float) -> void:
	# Moncong ikan ikut mendongak/menunduk sesuai kecepatan vertikal.
	var vertical_ratio := clampf(velocity.y / maxf(current_max_speed(), 1.0), -1.0, 1.0)
	var target_tilt := vertical_ratio * deg_to_rad(max_tilt_deg)
	if _sprite.menghadap_kiri():
		target_tilt = -target_tilt
	_sprite.rotation = lerp_angle(_sprite.rotation, target_tilt, clampf(tilt_response * delta, 0.0, 1.0))


func _wiggle_body(delta: float) -> void:
	# skew memiringkan sprite tanpa memutarnya, jadi badan terlihat meliuk
	# seperti ikan berenang. Frekuensi dan besarnya ikut kecepatan: diam =
	# bergoyang pelan, ngebut = mengibas cepat.
	var speed_ratio := clampf(velocity.length() / maxf(current_max_speed(), 1.0), 0.0, 1.0)
	_wiggle_time += delta * (5.0 + 11.0 * speed_ratio)
	_sprite.skew = sin(_wiggle_time) * deg_to_rad(wiggle_deg) * (0.3 + 0.7 * speed_ratio)
	_sprite.laju(speed_ratio)


# --- Pertumbuhan ------------------------------------------------------------

## Dipanggil dari luar setiap kali ikan berhasil makan sesuatu.
## Memainkan animasi menggigit sekali.
##
## Dipanggil SEMUA yang bisa dimakan atau digigit, bukan dipicu dari dalam
## add_growth() saja. Alasannya: tidak semua gigitan menumbuhkan ikan. Menggigit
## sapu-sapu tidak menambah pertumbuhan, dan memakan ikan lokal justru sengaja
## tidak memberi apa-apa -- tapi keduanya tetap gigitan, dan mulut yang tidak
## bergerak saat menggigit terlihat seperti animasi yang rusak.
func makan() -> void:
	_sprite.makan()


func add_growth(amount: float) -> void:
	makan()
	if size_level >= max_size_level:
		return

	growth += amount

	var leveled_up := false
	# while, bukan if: satu suapan besar boleh menaikkan lebih dari satu level.
	while growth >= growth_per_level and size_level < max_size_level:
		growth -= growth_per_level
		size_level += 1
		leveled_up = true

	if size_level >= max_size_level:
		growth = 0.0

	_apply_size(true)
	if leveled_up:
		AudioManager.play("level_up", -2.0)
		size_level_changed.emit(size_level)


## 0.0 sampai 1.0 -- progres menuju level berikutnya. Dibaca HUD.
func growth_ratio() -> float:
	if size_level >= max_size_level:
		return 1.0
	return growth / growth_per_level


## 0.0 sampai 1.0 -- posisi ikan di seluruh rentang ukuran. Dipakai kamera.
func size_progress() -> float:
	var steps := float(max_size_level - 1)
	if steps <= 0.0:
		return 1.0
	return clampf((float(size_level - 1) + growth_ratio()) / steps, 0.0, 1.0)


func _apply_size(animated: bool) -> void:
	var s := lerpf(scale_at_level_1, scale_at_max_level, size_progress())

	# Radius tabrakan diubah langsung tanpa animasi: hitbox tidak boleh telat
	# menyusul visual, nanti pemain merasa "kena padahal belum kena".
	_collision.shape.radius = base_radius * s

	# Node Camera2D di player_fish.tscn memakai game_camera.gd, jadi dia punya
	# set_size_progress() dan shake() -- keduanya dipanggil langsung tanpa
	# pemeriksaan, karena scene-nya yang menjamin.
	camera.set_size_progress(size_progress())

	if not animated:
		_sprite.scale = Vector2(s, s)
		return

	# Tween lama dimatikan dulu supaya dua suapan beruntun tidak menganimasikan
	# properti yang sama secara bersamaan.
	if _scale_tween != null and _scale_tween.is_running():
		_scale_tween.kill()
	_scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(_sprite, "scale", Vector2(s, s), 0.18)


# --- Nyawa ------------------------------------------------------------------

func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Dipanggil dari luar (sampah kebesaran, bos, semburan bos).
## from_position dipakai untuk menentukan arah pentalan.
func take_damage(amount: int, from_position: Vector2) -> void:
	if is_invulnerable() or health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)

	# Pentalan menjauh dari sumber. Kalau posisinya persis menumpuk, dipental
	# ke atas saja daripada membagi vektor nol.
	var away := global_position - from_position
	if away.is_zero_approx():
		away = Vector2.UP
	velocity = away.normalized() * knockback_force

	_invulnerable_left = invulnerable_time
	_lock_control(0.25)
	_play_hurt_effect()
	AudioManager.play("hurt", 0.0, 1.0)

	camera.shake(16.0)

	if health <= 0:
		died.emit()


## Memberi masa kebal singkat TANPA mengurangi nyawa. Dipakai bos sesudah
## insangnya digigit, supaya serangan yang berhasil tidak langsung dibalas.
func grant_mercy(duration: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, duration)


func _tick_invulnerability(delta: float) -> void:
	if _invulnerable_left <= 0.0:
		return
	_invulnerable_left -= delta
	if _invulnerable_left <= 0.0:
		_sprite.modulate = Color.WHITE
		return
	# Berkedip: 12 kali per detik. fmod() memotong waktu jadi siklus pendek,
	# lalu separuh awal siklus dibuat transparan.
	var blink := fmod(_invulnerable_left, 1.0 / 6.0) < (1.0 / 12.0)
	_sprite.modulate.a = 0.35 if blink else 1.0


func _play_hurt_effect() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.06)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.25)


func _lock_control(duration: float) -> void:
	_control_locked = true
	await get_tree().create_timer(duration).timeout
	# Node bisa saja sudah dibuang saat timer selesai (misal scene di-reload).
	if is_instance_valid(self):
		_control_locked = false


## Dipanggil map_manager saat permainan berakhir supaya ikan berhenti sendiri.
func freeze() -> void:
	_control_locked = true
	set_physics_process(false)
	velocity = Vector2.ZERO
