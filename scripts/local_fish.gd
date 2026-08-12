extends Area2D
## Ikan lokal Sungai Ciliwung -- nilem, tawes, betok. Penghuni sah sungai ini.
##
## Aturannya satu kalimat: IKAN INI TIDAK BOLEH DIMAKAN.
##
## Tapi kalau pemain terlanjur menabraknya, node-nya TIDAK dihancurkan. Dia
## DIMUNTAHKAN: terlempar menjauh, berputar kaget, lalu berenang lagi seperti
## semula. Itu keputusan desain yang paling penting di file ini -- kesalahan di
## sini harus terasa seperti sesuatu yang MASIH BISA DIPERBAIKI, bukan hukuman
## yang final. Yang menumpuk diam-diam cuma hitungan di GameState, dan pemain
## membacanya bukan lewat angka melainkan lewat air yang perlahan keruh.
##
## Ikan ini juga sedikit menghindar saat pemain mendekat. Itu bukan hiasan:
## dengan adanya usaha menghindar, ikan yang tetap termakan berarti pemain
## memang ceroboh -- bukan korban kebetulan. Kesalahannya jadi milik pemain,
## dan hukuman tersembunyinya jadi adil.

enum State { BERENANG, TERMUNTAHKAN }

@export_group("Rupa")
## Tiga warna untuk mewakili nilem, tawes, dan betok. Cuma pewarnaan sementara:
## satu tekstur Kenney diberi tiga rona berbeda supaya sekawanan ikan lokal
## tidak terlihat seperti satu ikan yang digandakan. Diganti sprite asli nanti.
@export var species_tints: PackedColorArray = PackedColorArray([
	Color(0.78, 0.84, 0.92),
	Color(0.93, 0.87, 0.66),
	Color(0.72, 0.88, 0.78),
])
@export var size_variation: Vector2 = Vector2(0.9, 1.12)

@export_group("Gerak")
@export var swim_speed: float = 108.0
## Seberapa cepat arah renang berbelok ke tujuan baru.
@export var turn_speed: float = 3.2
## Jeda acak sebelum memilih tujuan baru.
@export var repick_time: Vector2 = Vector2(1.5, 3.2)
## Jarak tempuh sekali pilih tujuan.
@export var wander_radius: float = 320.0

@export_group("Menghindar")
## Dalam jarak ini, ikan mulai berenang menjauh dari pemain.
@export var flee_radius: float = 150.0
@export var flee_speed_bonus: float = 1.9

@export_group("Dimuntahkan")
## Kecepatan awal saat terlempar dari mulut pemain.
@export var spit_force: float = 430.0
## Lama dia terhuyung sebelum berenang normal lagi.
@export var spit_recovery: float = 1.1
## Selama ini dia tidak bisa terhitung termakan lagi. Tanpa jeda ini, satu
## tabrakan panjang bisa menambah hitungan berkali-kali dalam sekejap dan
## ekosistemnya kolaps karena satu kesalahan, bukan lima.
@export var immune_time: float = 1.6

## Diisi wildlife_director; ikan tidak boleh keluar dari kolom air.
var swim_bounds: Rect2 = Rect2()

var _state: int = State.BERENANG
var _state_left: float = 0.0
var _immune_left: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _repick_left: float = 0.0
var _wobble: float = 0.0
## Rona spesies ikan ini. Disimpan supaya kilatan merah saat dimuntahkan bisa
## dikembalikan ke warna ASLINYA, bukan ke putih -- kalau ke putih, tiap ikan
## yang pernah termakan berubah spesies.
var _base_tint: Color = Color.WHITE

## Ikan asli sungai Indonesia yang bisa muncul sebagai penghuni.
const SPESIES_LOKAL := ["seluang", "nilem", "kancra", "gabus", "baung"]

@onready var _sprite: SpriteIkan = $Sprite2D
@onready var _puff: CPUParticles2D = $Puff


func _ready() -> void:
	add_to_group("local_fish")
	_wobble = randf() * TAU
	if not species_tints.is_empty():
		_base_tint = species_tints[randi() % species_tints.size()]
	# Spesies diundi tiap kali seekor lahir. Sungai yang penghuninya seragam
	# terbaca sebagai satu jenis ikan yang digandakan, bukan sebagai ekosistem.
	_sprite.ganti_spesies(SPESIES_LOKAL[randi() % SPESIES_LOKAL.size()])
	_sprite.modulate = _base_tint
	_sprite.scale *= randf_range(size_variation.x, size_variation.y)
	_target = global_position
	_repick_left = randf_range(repick_time.x, repick_time.y)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_immune_left = maxf(_immune_left - delta, 0.0)

	match _state:
		State.BERENANG:
			_swim(delta)
		State.TERMUNTAHKAN:
			_tumble(delta)

	global_position += (_velocity + _wobble_offset()) * delta
	_keep_inside_bounds()
	_face_travel(delta)


# --- Berenang biasa ---------------------------------------------------------

func _swim(delta: float) -> void:
	var player := _nearby_player()
	var desired: Vector2

	if player != null:
		# Menjauh dulu, urusan tujuan belakangan.
		desired = (global_position - player.global_position).normalized() * swim_speed * flee_speed_bonus
	else:
		_repick_left -= delta
		if _repick_left <= 0.0 or global_position.distance_to(_target) < 40.0:
			_repick_left = randf_range(repick_time.x, repick_time.y)
			_target = _pick_wander_target()
		desired = (_target - global_position).normalized() * swim_speed

	# Belok bertahap, bukan langsung. Ikan yang bisa membalik arah seketika
	# terlihat seperti kursor, bukan makhluk hidup.
	_velocity = _velocity.move_toward(desired, swim_speed * turn_speed * delta)
	_wobble += delta * 5.0


## Goyangan kecil tegak lurus arah renang.
##
## Sengaja DITAMBAHKAN saat integrasi posisi, bukan ditumpuk ke _velocity.
## Versi pertama menumpuknya ke _velocity tiap frame, dan hasilnya vektor
## kecepatan terus berputar sendiri: ikannya berputar-putar di tempat alih-alih
## berenang ke tujuan. Simpanan keadaan (_velocity) harus tetap bersih; hiasan
## gerak ditumpangkan di atasnya.
func _wobble_offset() -> Vector2:
	if _state != State.BERENANG or _velocity.length() < 1.0:
		return Vector2.ZERO
	return _velocity.orthogonal().normalized() * sin(_wobble) * 16.0


func _nearby_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return null
	if global_position.distance_to(player.global_position) > flee_radius:
		return null
	return player


func _pick_wander_target() -> Vector2:
	var angle := randf() * TAU
	var point := global_position + Vector2.RIGHT.rotated(angle) * randf_range(80.0, wander_radius)
	if swim_bounds.size.is_zero_approx():
		return point
	return Vector2(
		clampf(point.x, swim_bounds.position.x + 60.0, swim_bounds.end.x - 60.0),
		clampf(point.y, swim_bounds.position.y + 60.0, swim_bounds.end.y - 60.0)
	)


# --- Terhuyung sesudah dimuntahkan ------------------------------------------

func _tumble(delta: float) -> void:
	# Melambat sendiri, lalu sadar dan berenang lagi.
	_velocity = _velocity.move_toward(Vector2.ZERO, spit_force * 1.4 * delta)
	_sprite.rotation += delta * 14.0 * signf(_velocity.x if absf(_velocity.x) > 0.1 else 1.0)

	_state_left -= delta
	if _state_left <= 0.0:
		_state = State.BERENANG
		_sprite.rotation = 0.0
		_target = _pick_wander_target()
		_repick_left = randf_range(repick_time.x, repick_time.y)


# --- Tabrakan dengan pemain -------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _state == State.TERMUNTAHKAN or _immune_left > 0.0:
		return
	if not body.is_in_group("player"):
		return
	_be_spat_out(body)


func _be_spat_out(player: Node2D) -> void:
	# Perhatikan yang TIDAK terjadi di sini: tidak ada queue_free(), tidak ada
	# add_score(), tidak ada add_growth(). Pemain tidak mendapat apa pun dari
	# memakan ikan lokal -- itu murni kerugian yang belum kelihatan.
	GameState.report_local_fish_eaten()
	# Mulutnya tetap bergerak walau tidak dapat apa-apa. Justru itu yang bikin
	# perbuatannya terasa: pemain MELIHAT dirinya menelan penghuni sungai.
	player.makan()

	var away := global_position - player.global_position
	if away.is_zero_approx():
		away = Vector2.UP
	_velocity = away.normalized() * spit_force
	_state = State.TERMUNTAHKAN
	_state_left = spit_recovery
	_immune_left = immune_time

	_puff.emitting = true
	player.camera.shake(9.0)
	AudioManager.play("spit_out", 0.0, randf_range(0.92, 1.08))

	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(1.7, 1.3, 1.3), 0.06)
	tween.tween_property(_sprite, "modulate", _base_tint, 0.45)


# --- Batas renang -----------------------------------------------------------

func _keep_inside_bounds() -> void:
	if swim_bounds.size.is_zero_approx():
		return
	var margin := 34.0
	var target_x := clampf(global_position.x, swim_bounds.position.x + margin, swim_bounds.end.x - margin)
	var target_y := clampf(global_position.y, swim_bounds.position.y + margin, swim_bounds.end.y - margin)
	# Memantul, bukan berhenti: ikan yang menempel di dinding terlihat rusak.
	if not is_equal_approx(target_x, global_position.x):
		global_position.x = target_x
		_velocity.x = -_velocity.x * 0.6
		_target = _pick_wander_target()
	if not is_equal_approx(target_y, global_position.y):
		global_position.y = target_y
		_velocity.y = -_velocity.y * 0.6
		_target = _pick_wander_target()


func _face_travel(delta: float) -> void:
	if _state == State.TERMUNTAHKAN:
		return
	# Sprite ikan Kenney menghadap ke KANAN secara bawaan.
	if absf(_velocity.x) > 6.0:
		_sprite.hadap(_velocity.x < 0.0)
	var tilt := clampf(_velocity.y / maxf(swim_speed, 1.0), -1.0, 1.0) * deg_to_rad(16.0)
	if _sprite.flip_h:
		tilt = -tilt
	_sprite.rotation = lerp_angle(_sprite.rotation, tilt, clampf(7.0 * delta, 0.0, 1.0))
