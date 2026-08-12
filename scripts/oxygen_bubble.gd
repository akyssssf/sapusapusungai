extends Area2D
## Gelembung oksigen: satu-satunya cara memulihkan nyawa di Bab 1 dan 2.
##
## KENAPA INI ADA, dan kenapa berbentuk gelembung.
##
## Sebelum ini nyawa cuma bisa berkurang. Satu bab bisa berjalan beberapa menit,
## jadi satu kesalahan di menit pertama tetap menghantui sampai bosnya -- dan
## pemain yang kehilangan dua nyawa lebih awal praktis sudah tahu dia akan
## mengulang. Itu bukan ketegangan, itu menunggu.
##
## Bentuknya gelembung oksigen, bukan hati atau kotak P3K, karena barang yang
## memulihkan ikan harus masuk akal di dalam air. Air yang sehat memang
## beroksigen; sungai yang tercekik sampah justru kehabisan oksigen, dan itu
## salah satu sebab ikan mati di sungai sungguhan. Jadi benda ini bukan tempelan
## -- dia ikut mengatakan sesuatu tentang temanya.
##
## SATU BENDA, DUA GUNA. Kalau nyawa pemain penuh, gelembungnya tidak boleh
## terasa sia-sia: dia berubah jadi dorongan tenaga sesaat. Barang bagus yang
## kadang tidak berguna membuat pemain ragu memungutnya, dan keraguan itu jauh
## lebih merugikan daripada nilai barangnya sendiri.

signal dipungut

@export_group("Gerak")
## Hanyut ke kiri mengikuti arus, sambil naik pelan seperti gelembung sungguhan.
@export var hanyut: float = 26.0
@export var naik: float = 34.0
@export var goyang_lebar: float = 16.0
@export var goyang_laju: float = 1.8

@export_group("Umur")
## Gelembung pecah sendiri kalau tidak dipungut. Tanpa batas umur, sungai
## pelan-pelan penuh gelembung yang tidak diambil siapa pun.
@export var umur: float = 14.0
## Mulai berkedip beberapa detik sebelum pecah, supaya hilangnya tidak mendadak.
@export var kedip_dari: float = 3.5

@export_group("Efek")
## Lama dorongan tenaga saat nyawa pemain sudah penuh.
@export var lama_dorongan: float = 6.0

var _umur_sisa: float = 0.0
var _fase: float = 0.0
var _dasar_y: float = 0.0
var _dipungut: bool = false

@onready var _gambar: Sprite2D = $Gambar
@onready var _kilau: Line2D = $Kilau
@onready var _percik: CPUParticles2D = $Percik


func _ready() -> void:
	add_to_group("gelembung")
	_umur_sisa = umur
	_dasar_y = position.y
	_fase = randf() * TAU
	body_entered.connect(_pada_sentuhan)

	# Masuk dengan membesar dari nol. Benda yang tiba-tiba ada di layar terbaca
	# sebagai kesalahan render; yang tumbuh terbaca sebagai sesuatu yang muncul.
	_gambar.scale = Vector2.ZERO
	var masuk := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	masuk.tween_property(_gambar, "scale", Vector2.ONE, 0.35)


func _process(delta: float) -> void:
	if _dipungut:
		return

	_fase += delta * goyang_laju
	position.x -= hanyut * delta
	_dasar_y -= naik * delta
	position.y = _dasar_y + sin(_fase) * goyang_lebar

	# Cincin kilau berputar pelan supaya gelembungnya terbaca sebagai benda yang
	# boleh disentuh, bukan sebagai bagian latar.
	_kilau.rotation += delta * 1.2

	_umur_sisa -= delta
	if _umur_sisa <= kedip_dari:
		var kedip := 0.45 + 0.55 * absf(sin(_umur_sisa * 9.0))
		modulate.a = kedip
	if _umur_sisa <= 0.0 or position.y < -80.0:
		_pecah(false)


func _pada_sentuhan(body: Node2D) -> void:
	if _dipungut or not body.is_in_group("player"):
		return
	_dipungut = true

	# Nyawa dulu; dorongan tenaga cuma hadiah hiburan saat nyawanya penuh.
	if body.health < body.max_health:
		body.pulihkan(1)
		AudioManager.play("level_up", 1.0, 1.25, 0.0)
	else:
		body.beri_dorongan(lama_dorongan)
		AudioManager.play("dash", 0.0, 1.35, 0.0)

	dipungut.emit()
	_pecah(true)


func _pecah(dipungut_pemain: bool) -> void:
	_dipungut = true
	set_deferred("monitoring", false)
	_percik.emitting = true
	_kilau.visible = false

	var tween := create_tween()
	if dipungut_pemain:
		tween.tween_property(_gambar, "scale", Vector2(1.7, 1.7), 0.18)
		tween.parallel().tween_property(_gambar, "modulate:a", 0.0, 0.18)
	else:
		tween.tween_property(_gambar, "scale", Vector2.ZERO, 0.22)
	tween.tween_interval(0.7)
	tween.tween_callback(queue_free)
