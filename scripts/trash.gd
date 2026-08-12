extends Area2D
## Satu butir sampah yang hanyut di sungai.
##
## Ada tiga ukuran. Aturannya meniru Feeding Frenzy:
##   - Sampah yang UKURANNYA <= ukuran ikan  -> bisa dimakan, dapat skor.
##   - Sampah yang LEBIH BESAR dari ikan     -> menabraknya mengurangi nyawa.
## Itulah sumber ketegangannya: sungai penuh makanan sekaligus penuh ranjau,
## dan ranjau hari ini adalah makanan sepuluh detik lagi.
##
## Kenapa SAMPAH yang mendeteksi pemain, bukan sebaliknya? Karena tiap benda
## nanti punya reaksi berbeda (ikan lokal dimuntahkan, sapu-sapu butuh beberapa
## gigitan). Menaruh reaksi di masing-masing benda jauh lebih rapi daripada satu
## blok if raksasa di dalam player_fish.gd.

enum Tier { KECIL, SEDANG, BESAR }

## Tabel angka per ukuran. Ditaruh sebagai satu const supaya menyetel
## keseimbangan permainan cukup mengubah satu blok, bukan berburu angka ajaib
## yang tersebar di banyak fungsi.
##   butuh_level : ikan minimal harus selevel ini untuk memakannya
##   skor        : poin saat dimakan
##   tumbuh      : poin pertumbuhan saat dimakan
##   radius      : radius tabrakan
const TIER_DATA := [
	{"butuh_level": 1, "skor": 10, "tumbuh": 20.0, "radius": 15.0},
	{"butuh_level": 3, "skor": 30, "tumbuh": 45.0, "radius": 26.0},
	{"butuh_level": 5, "skor": 70, "tumbuh": 90.0, "radius": 40.0},
]

@export var tier: Tier = Tier.KECIL

@export_group("Hanyut")
## Arus Brantas mengalir ke kiri. Angka acak per butir supaya arusnya tidak
## terlihat seperti satu ban berjalan yang kaku.
@export var drift_speed_range: Vector2 = Vector2(22.0, 52.0)
## Simpangan naik-turun dalam piksel.
@export var bob_amplitude_range: Vector2 = Vector2(4.0, 11.0)
@export var bob_speed_range: Vector2 = Vector2(0.9, 2.1)
@export var spin_speed_deg_range: Vector2 = Vector2(-22.0, 22.0)
## Sampah dibuang setelah lewat sejauh ini di kiri peta (di luar pandangan).
@export var despawn_margin: float = 140.0

## Pengali kecepatan hanyut. Dinaikkan director saat "arus deras" melanda,
## lalu dikembalikan ke 1.0. Sengaja variabel biasa, bukan @export: yang
## mengaturnya director, bukan orang lewat Inspector.
var speed_multiplier: float = 1.0

var _drift_speed: float = 0.0
var _bob_amplitude: float = 0.0
var _bob_speed: float = 0.0
var _spin_speed: float = 0.0
var _bob_phase: float = 0.0
var _base_y: float = 0.0
var _eaten: bool = false
var _player: Node = null

## Gambar sampah sungguhan, dikelompokkan per tingkat ukuran.
##
## Tingkatnya menentukan seberapa besar bahayanya, jadi gambarnya juga harus
## ikut naik: kantong kresek untuk yang bisa ditelan ikan kecil, papan dan
## tumpukan sampah untuk yang harus dihindari sampai ikannya cukup besar.
## Pemain menilai bahaya dari SILUET jauh sebelum sempat membaca cincinnya.
const GAMBAR_PER_TINGKAT := [
	[
		preload("res://assets/environment/plastic_bottle.png"),
		preload("res://assets/environment/plastic_bag.png"),
	],
	[
		preload("res://assets/environment/kresek_bag.png"),
		preload("res://assets/environment/wooden_plank.png"),
	],
	[
		preload("res://assets/environment/trash_pile.png"),
		preload("res://assets/environment/driftwood_log.png"),
		preload("res://assets/environment/banana_tree.png"),
	],
]

@onready var _visual: Node2D = $Visual
@onready var _gambar: Sprite2D = $Visual/Gambar
@onready var _danger_ring: Node2D = $Visual/DangerRing
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	add_to_group("trash")
	_apply_tier()
	_randomise_motion()

	body_entered.connect(_on_body_entered)

	# Tanda bahaya cukup diperbarui saat ukuran ikan berubah, bukan tiap frame.
	_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		_player.size_level_changed.connect(_on_player_size_changed)
	_refresh_danger_ring()


func _apply_tier() -> void:
	var data: Dictionary = TIER_DATA[tier]
	_collision.shape = CircleShape2D.new()
	_collision.shape.radius = data["radius"]

	# Hanya bentuk yang sesuai ukurannya yang ditampilkan; dua sisanya cuma
	# ikut menumpang di scene supaya tidak perlu tiga file .tscn terpisah.
	var pilihan: Array = GAMBAR_PER_TINGKAT[tier]
	_gambar.texture = pilihan[randi() % pilihan.size()]
	# Skala dihitung dari radius tabrakannya, bukan angka tetap. Dengan begitu
	# yang dilihat pemain selalu sebesar yang benar-benar bisa menabraknya --
	# sampah yang tampak lebih kecil daripada hitboxnya terasa curang.
	var lebar: float = float(_gambar.texture.get_width())
	if lebar > 0.0:
		_gambar.scale = Vector2.ONE * (float(data["radius"]) * 2.35 / lebar)

	_danger_ring.scale = Vector2.ONE * (data["radius"] / 30.0)
	_burst.amount = 8 + tier * 6
	_burst.scale_amount_min = 1.5 + tier
	_burst.scale_amount_max = 3.0 + tier * 2


func _randomise_motion() -> void:
	# Tanpa pengacakan ini semua sampah bergoyang serempak seperti barisan
	# upacara, dan langsung ketahuan hasil salin-tempel.
	_base_y = position.y
	_bob_phase = randf() * TAU
	_drift_speed = randf_range(drift_speed_range.x, drift_speed_range.y)
	_bob_amplitude = randf_range(bob_amplitude_range.x, bob_amplitude_range.y)
	_bob_speed = randf_range(bob_speed_range.x, bob_speed_range.y)
	_spin_speed = deg_to_rad(randf_range(spin_speed_deg_range.x, spin_speed_deg_range.y))
	_visual.rotation = randf() * TAU
	_visual.scale = Vector2.ONE * randf_range(0.9, 1.12)


func _process(delta: float) -> void:
	# Hanyut mengikuti arus, sambil naik-turun di sekitar jalur hanyutnya.
	position.x -= _drift_speed * speed_multiplier * delta
	_bob_phase += delta * _bob_speed
	position.y = _base_y + sin(_bob_phase) * _bob_amplitude
	_visual.rotation += _spin_speed * delta

	if _danger_ring.visible:
		# Denyut pelan supaya mata pemain tertarik ke sampah berbahaya.
		_danger_ring.modulate.a = 0.62 + 0.28 * sin(_bob_phase * 3.0)

	if position.x < -despawn_margin:
		queue_free()


# --- Tabrakan ---------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _eaten or not body.is_in_group("player"):
		return

	if body.size_level >= int(TIER_DATA[tier]["butuh_level"]):
		_be_eaten(body)
	else:
		_hurt(body)


func _be_eaten(player: Node2D) -> void:
	_eaten = true
	# monitoring dimatikan lewat set_deferred(), bukan langsung: mengubah state
	# Area2D di tengah callback fisika dilarang Godot. Flag _eaten di atas yang
	# menahan sinyal ganda pada frame yang sama ini.
	set_deferred("monitoring", false)
	set_process(false)

	var data: Dictionary = TIER_DATA[tier]
	GameState.add_score(int(data["skor"]))
	player.add_growth(float(data["tumbuh"]))
	player.camera.shake(3.0 + tier * 3.0)
	# Sampah kecil berbunyi tinggi dan renyah, sampah besar berat dan dalam.
	# Satu berkas dipakai untuk dua ukuran pertama, cuma nadanya digeser.
	if tier == Tier.BESAR:
		AudioManager.play("eat_big", 0.0, 0.92)
	else:
		AudioManager.play("eat_small", 0.0, 1.15 if tier == Tier.KECIL else 0.85)

	_burst.emitting = true

	var tween := create_tween().set_parallel()
	tween.tween_property(_visual, "scale", Vector2.ZERO, 0.14).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.14)
	# Tunggu percikannya habis dulu baru node dibuang, kalau tidak partikelnya
	# ikut hilang di tengah jalan.
	tween.chain().tween_interval(_burst.lifetime)
	tween.chain().tween_callback(queue_free)


func _hurt(player: Node2D) -> void:
	# Tidak ada pemeriksaan kebal di sini: take_damage() sendiri sudah menolak
	# kalau pemain masih kebal. Pentalan di bawah TETAP dijalankan, dan itu
	# disengaja -- kalau sampahnya tidak ikut terdorong, pemain yang berhenti di
	# dalam sampah besar selama masa kebal akan menempel di sana tanpa pernah
	# memicu body_entered lagi, alias jadi kebal permanen terhadap sampah itu.
	player.take_damage(1, global_position)

	# Posisinya digeser langsung, bukan
	# di-tween: _process() menulis position.y tiap frame, jadi tween pada
	# properti yang sama akan saling menimpa.
	var away := (global_position - player.global_position).normalized()
	if away.is_zero_approx():
		away = Vector2.RIGHT
	position.x += away.x * 90.0
	_base_y += away.y * 90.0
	position.y = _base_y

	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(1.6, 0.7, 0.7), 0.05)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.3)


# --- Tanda bahaya -----------------------------------------------------------

func _on_player_size_changed(_new_level: int) -> void:
	_refresh_danger_ring()


func _refresh_danger_ring() -> void:
	if _player == null:
		_danger_ring.visible = false
		return
	# Cincin merah hanya muncul selama sampah ini masih terlalu besar. Begitu
	# ikan cukup besar, cincinnya hilang -- itu sinyal "sekarang boleh dimakan".
	_danger_ring.visible = _player.size_level < int(TIER_DATA[tier]["butuh_level"])
