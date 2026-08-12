extends Area2D
## Ikan sapu-sapu (Pterygoplichthys) -- hama pendatang yang harus dibersihkan.
##
## Dua sifat biologisnya diterjemahkan langsung jadi aturan main:
##
##   BERPELAT KERAS -> satu gigitan tidak cukup. Butuh beberapa kali kontak,
##                     dan setiap kontak MEMENTALKAN pemain. Jadi "beberapa
##                     kali" itu bukan sekadar angka yang turun di balik layar;
##                     pemain benar-benar harus berbalik dan mendekat lagi.
##   LAMBAN         -> sapu-sapu bukan perenang lincah. Dia menempel di satu
##                     titik dan bergeser pelan, berbeda jelas dari ikan lokal
##                     yang lincah dan menghindar. Perbedaan gerak ini yang
##                     membuat pemain bisa membedakan keduanya dari jauh,
##                     sebelum sempat salah makan.
##
## Ukuran ikan pemain juga dipakai sebagai gerbang: wader kecil tidak akan
## sanggup melukai pelat sapu-sapu, dia cuma terpental. Itu mendorong pemain
## menyelesaikan urusan sampah dulu sebelum berburu hama.

signal cleared

@export_group("Ketahanan")
@export var max_health: int = 3
## Ukuran minimal ikan pemain untuk bisa melukainya.
@export var required_size_level: int = 2
## Jeda antar gigitan yang dihitung. Tanpa ini, satu tumpang tindih panjang
## menghabiskan seluruh nyawanya dalam beberapa frame.
@export var hit_cooldown: float = 0.45
## Seberapa keras pemain terpental tiap kali menggigit.
@export var knockback_force: float = 380.0

@export_group("Nilai")
@export var score_value: int = 120

@export_group("Gerak")
## Kecepatan menggeser ke titik singgah berikutnya. Sengaja sangat pelan.
@export var drift_speed: float = 26.0
## Jarak titik singgah berikutnya dari titik sekarang.
@export var roam_radius: float = 130.0
## Jeda sebelum pindah titik singgah.
@export var move_interval: Vector2 = Vector2(3.0, 6.5)
## Goyangan kecil di tempat, supaya tidak terlihat seperti gambar tempel.
@export var idle_sway: Vector2 = Vector2(9.0, 5.0)

var health: int = 3

## Diisi wildlife_director.
var swim_bounds: Rect2 = Rect2()

var _anchor: Vector2 = Vector2.ZERO
var _next_anchor: Vector2 = Vector2.ZERO
var _move_left: float = 0.0
var _sway_time: float = 0.0
var _hit_cooldown_left: float = 0.0
var _player: Node2D = null
var _dying: bool = false

@onready var _visual: Node2D = $Visual
@onready var _burst: CPUParticles2D = $Burst
@onready var _health_pips: Node2D = $Visual/HealthPips


func _ready() -> void:
	add_to_group("sapu_sapu")
	add_to_group("pest")
	health = max_health
	_anchor = global_position
	_next_anchor = global_position
	_move_left = randf_range(move_interval.x, move_interval.y)
	_sway_time = randf() * TAU
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_refresh_pips()


func _physics_process(delta: float) -> void:
	if _dying:
		return

	_hit_cooldown_left = maxf(_hit_cooldown_left - delta, 0.0)
	_drift(delta)
	_check_bite()


# --- Gerak lamban -----------------------------------------------------------

func _drift(delta: float) -> void:
	_move_left -= delta
	if _move_left <= 0.0:
		_move_left = randf_range(move_interval.x, move_interval.y)
		_next_anchor = _pick_anchor()

	_anchor = _anchor.move_toward(_next_anchor, drift_speed * delta)

	# Posisi akhir = titik singgah + goyangan lissajous kecil. Dua frekuensi
	# yang tidak kelipatan satu sama lain membuat polanya tidak pernah persis
	# berulang, jadi matanya tidak menangkap "loop".
	_sway_time += delta
	global_position = _anchor + Vector2(
		sin(_sway_time * 0.9) * idle_sway.x,
		sin(_sway_time * 1.37 + 1.1) * idle_sway.y
	)

	if _player != null and absf(_player.global_position.x - global_position.x) > 20.0:
		_visual.scale.x = 1.0 if _player.global_position.x > global_position.x else -1.0


func _pick_anchor() -> Vector2:
	var angle := randf() * TAU
	var point := _anchor + Vector2.RIGHT.rotated(angle) * randf_range(40.0, roam_radius)
	if swim_bounds.size.is_zero_approx():
		return point
	return Vector2(
		clampf(point.x, swim_bounds.position.x + 80.0, swim_bounds.end.x - 80.0),
		clampf(point.y, swim_bounds.position.y + 70.0, swim_bounds.end.y - 70.0)
	)


# --- Digigit ----------------------------------------------------------------

## Diperiksa dengan melihat tumpang tindih tiap frame, bukan lewat sinyal
## body_entered. Alasannya sama dengan bos: pemain sering sudah berada di dalam
## area ini ketika jeda gigitan habis, dan sinyal "baru masuk" tidak akan
## menyala lagi untuk keadaan itu -- gigitannya hilang tanpa jejak.
func _check_bite() -> void:
	if _hit_cooldown_left > 0.0 or _player == null:
		return
	var touching := false
	for body in get_overlapping_bodies():
		if body == _player:
			touching = true
			break
	if not touching:
		return

	_hit_cooldown_left = hit_cooldown

	if _player.size_level < required_size_level:
		_bounce_player(0.55)
		# Bunyi logam tanpa kerusakan: pemain langsung paham "belum cukup besar".
		AudioManager.play("boss_hit", -6.0, 1.5)
		var tween := create_tween()
		tween.tween_property(_visual, "modulate", Color(0.7, 0.8, 0.9), 0.05)
		tween.tween_property(_visual, "modulate", Color.WHITE, 0.2)
		return

	health -= 1
	_refresh_pips()
	_bounce_player(1.0)
	AudioManager.play("boss_hit", -3.0, 1.15 + 0.1 * float(max_health - health))
	_player.camera.shake(9.0)

	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(2.0, 1.5, 1.4), 0.05)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.24)

	if health <= 0:
		_be_cleared()


## Pemain terpental menjauh setiap gigitan. Inilah yang membuat "butuh beberapa
## kali kontak" terasa sebagai perjuangan, bukan sekadar angka yang menurun.
func _bounce_player(strength: float) -> void:
	var away := _player.global_position - global_position
	if away.is_zero_approx():
		away = Vector2.UP
	_player.velocity = away.normalized() * knockback_force * strength


func _be_cleared() -> void:
	_dying = true
	set_deferred("monitoring", false)
	GameState.add_score(score_value)
	AudioManager.play("eat_big", 1.0, 0.8)
	_player.camera.shake(15.0)
	_burst.emitting = true
	cleared.emit()

	var tween := create_tween().set_parallel()
	tween.tween_property(_visual, "scale", Vector2(_visual.scale.x * 0.1, 0.1), 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.2)
	# Tunggu percikannya habis dulu baru node dibuang.
	tween.chain().tween_interval(_burst.lifetime)
	tween.chain().tween_callback(queue_free)


## Titik-titik pelat di punggung menunjukkan sisa ketahanan tanpa perlu bar.
## Untuk musuh sekecil ini, bar melayang malah lebih berisik daripada berguna.
func _refresh_pips() -> void:
	for i in _health_pips.get_child_count():
		_health_pips.get_child(i).visible = i < health
