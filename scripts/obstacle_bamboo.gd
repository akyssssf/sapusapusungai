extends StaticBody2D
## Sumbatan bambu -- "brambongan", yang disebut warga sebagai biang banjir.
##
## Inilah satu-satunya aturan Map 3, dan sengaja tidak ada aturan lain:
##
##     Sumbatan ini hanya bergerak kalau KEDUA ikan berada dalam radiusnya
##     PADA WAKTU YANG SAMA, dan bertahan di sana selama beberapa detik.
##
## Satu ikan, sekuat apa pun, tidak bisa apa-apa. Itu bukan sekadar syarat
## teknis -- itu isi pesannya. Sampah bisa dibersihkan sendirian (Map 1), tapi
## sumbatan sungai tidak.
##
## StaticBody2D, bukan Area2D: sumbatan ini benar-benar MENGHALANGI ikan.
## Kalau cuma area yang bisa ditembus, pemain tidak akan pernah merasa bahwa
## benda ini sedang menutup jalan air.
##
## Umpan baliknya berlapis, dan itu disengaja. Puzzle yang syaratnya tidak
## terlihat bukan puzzle, cuma tebak-tebakan:
##   - tidak ada ikan     : diam, cokelat kusam
##   - satu ikan          : berdenyut kuning + garis penghubung ke ikan itu.
##                          Artinya "kamu benar, tapi kurang satu"
##   - dua ikan           : menyala biru, cincin progres mulai terisi, detak
##                          terdengar makin cepat
##   - selesai            : terdorong keluar jalur air lalu pecah

signal cleared

@export_group("Syarat dorong")
## Jarak maksimal seekor ikan dari titik tengah sumbatan agar dianggap "dekat".
@export var push_radius: float = 190.0
## Berapa lama keduanya harus bertahan di dalam radius.
@export var hold_time: float = 1.6

@export_group("Toleransi")
## Kalau salah satu ikan keluar radius, progres tidak langsung hangus melainkan
## menyusut dengan kecepatan ini (dalam bagian per detik). Menghukum kesalahan
## sekejap dengan mengulang dari nol membuat puzzle terasa jahil, bukan sulit.
@export var decay_rate: float = 0.55

@export_group("Rasa")
## Jarak terjauh sumbatan terdorong sebelum pecah.
@export var shove_distance: float = 260.0
@export var shove_direction: Vector2 = Vector2(-0.35, 1.0)

## Warna cincin dan garis pada tiap keadaan.
@export var color_idle: Color = Color(0.42, 0.33, 0.19)
@export var color_partial: Color = Color(0.98, 0.76, 0.29)
@export var color_ready: Color = Color(0.35, 0.87, 0.98)

var _fish: Array[Node2D] = []
var _charge: float = 0.0
var _near_count: int = 0
var _done: bool = false
var _tick_cooldown: float = 0.0
var _pulse: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _outline: Line2D = $Visual/Outline
@onready var _ring: Line2D = $ProgressRing
@onready var _link_a: Line2D = $LinkA
@onready var _link_b: Line2D = $LinkB
@onready var _burst: CPUParticles2D = $Burst
@onready var _shape: CollisionShape2D = $CollisionShape2D


## Dipanggil map3_manager: sumbatan perlu tahu ikan mana saja yang dihitung.
func setup(fish: Array[Node2D]) -> void:
	_fish = fish


func _ready() -> void:
	add_to_group("obstacle")
	_ring.visible = false
	_link_a.visible = false
	_link_b.visible = false
	_outline.default_color = color_idle


func _physics_process(delta: float) -> void:
	if _done or _fish.size() < 2:
		return

	_near_count = 0
	for fish in _fish:
		if is_instance_valid(fish) and global_position.distance_to(fish.global_position) <= push_radius:
			_near_count += 1

	if _near_count >= 2:
		_charge = minf(_charge + delta, hold_time)
		_tick(delta)
		if _charge >= hold_time:
			_break_apart()
	else:
		# Menyusut, bukan hangus. Lihat penjelasan decay_rate di atas.
		_charge = maxf(_charge - decay_rate * hold_time * delta, 0.0)

	_refresh_visual(delta)


func ratio() -> float:
	return clampf(_charge / maxf(hold_time, 0.01), 0.0, 1.0)


# --- Umpan balik ------------------------------------------------------------

## Detak yang makin rapat saat cincin makin penuh. Ini penting untuk pemain
## yang sedang menatap ikannya, bukan menatap sumbatannya: telinga tetap tahu
## berapa lama lagi harus bertahan.
func _tick(delta: float) -> void:
	_tick_cooldown -= delta
	if _tick_cooldown > 0.0:
		return
	var r := ratio()
	_tick_cooldown = lerpf(0.26, 0.09, r)
	AudioManager.play("link_tick", -4.0, 0.85 + 0.55 * r, 0.0)


func _refresh_visual(delta: float) -> void:
	_pulse += delta

	var colour := color_idle
	if _near_count >= 2:
		colour = color_ready
	elif _near_count == 1:
		# Berdenyut supaya jelas ini keadaan "belum lengkap", bukan keadaan diam.
		colour = color_partial
		colour.a = 0.55 + 0.45 * absf(sin(_pulse * 5.0))

	_outline.default_color = colour
	_outline.width = 5.0 + (3.0 if _near_count >= 2 else 0.0)

	# Cincin progres digambar ulang tiap frame sebagai busur sepanjang rasio.
	# Sebuah angka mentah tidak akan terbaca di tengah permainan; busur yang
	# menutup adalah bentuk paling cepat dibaca mata untuk "sedikit lagi".
	var r := ratio()
	_ring.visible = r > 0.01
	if _ring.visible:
		_ring.default_color = color_ready
		_ring.points = _arc_points(push_radius * 0.42, r)

	# Garis penghubung ke tiap ikan yang sudah dekat: menunjukkan siapa yang
	# sudah dihitung, sehingga pemain tahu ikan MANA yang masih kurang.
	_refresh_link(_link_a, 0)
	_refresh_link(_link_b, 1)


func _refresh_link(line: Line2D, index: int) -> void:
	if index >= _fish.size() or not is_instance_valid(_fish[index]):
		line.visible = false
		return
	var fish: Node2D = _fish[index]
	var near: bool = global_position.distance_to(fish.global_position) <= push_radius
	line.visible = near
	if near:
		line.points = PackedVector2Array([Vector2.ZERO, to_local(fish.global_position)])
		line.default_color = (color_ready if _near_count >= 2 else color_partial)
		line.default_color.a = 0.45


func _arc_points(radius: float, portion: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := maxi(int(48.0 * portion), 2)
	for i in segments + 1:
		# Dimulai dari atas (-PI/2) dan berputar searah jarum jam, sama seperti
		# arah orang membaca hitungan mundur.
		var angle := -PI * 0.5 + TAU * portion * (float(i) / float(segments))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


# --- Terdorong lepas --------------------------------------------------------

func _break_apart() -> void:
	_done = true
	set_physics_process(false)
	# Progres dinolkan setelah dibanknya, bukan dibiarkan penuh.
	#
	# Wasit menjumlahkan "sumbatan yang sudah selesai" DITAMBAH "progres sumbatan
	# yang sedang dikerjakan". Sumbatan ini baru saja pindah dari kolom kedua ke
	# kolom pertama; kalau ratio()-nya tetap 1.0 selama tween pecahnya berjalan,
	# dia terhitung dua kali dan bar aliran melompat ke 2/3 padahal baru 1 yang
	# lepas. Dengan satu sumbatan hal ini tidak pernah terlihat, karena babaknya
	# langsung berakhir.
	_charge = 0.0
	# Tabrakan dimatikan lewat set_deferred: mengubahnya di tengah langkah
	# fisika yang sedang berjalan dilarang Godot.
	_shape.set_deferred("disabled", true)
	_ring.visible = false
	_link_a.visible = false
	_link_b.visible = false
	_burst.emitting = true
	AudioManager.play("bamboo_break", 2.0, 1.0, 0.03)

	cleared.emit()

	# Terdorong dulu, baru pecah. Urutan ini yang membuatnya terbaca sebagai
	# "didorong oleh dua ikan", bukan "meledak sendiri".
	var tween := create_tween()
	tween.tween_property(_visual, "position",
		_visual.position + shove_direction.normalized() * shove_distance, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_visual, "rotation", deg_to_rad(38.0), 0.7)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
