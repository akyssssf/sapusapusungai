extends StaticBody2D
## Sumbatan bambu -- "brambongan", yang disebut warga sebagai biang banjir.
##
## Sumbatan ini BENAR-BENAR DIDORONG, bukan ditunggui.
##
## Versi sebelumnya cuma menghitung: kalau dua ikan berada dalam radius selama
## sekian detik, sumbatan terbuka. Hasilnya persis seperti yang dikeluhkan --
## pemain memarkir dua ikan lalu menonton. Tidak ada yang bergerak, tidak ada
## yang terasa berat, dan tangannya tidak melakukan apa pun selama hitungan
## berjalan.
##
## Sekarang aturannya begini, dan bedanya ada di tangan pemain:
##
##   IKAN YANG DIKENDALIKAN  harus terus BERENANG MENEKAN ke arah dorong.
##                           Melepas tombol = berhenti mendorong.
##   IKAN YANG DITINGGAL     otomatis MENAHAN (mengganjal), tapi hanya kalau
##                           posisinya benar -- di sisi yang berlawanan dengan
##                           arah dorong. Salah sisi, dia tidak membantu.
##
## Satu ikan tidak akan pernah cukup: ganjalan saja (0,8) maupun dorongan saja
## (maksimal 1,0) sama-sama di bawah ambang 1,6. Butuh keduanya sekaligus.
##
## Dan yang paling penting: sumbatannya BERGESER selama didorong, dan MELOROT
## BALIK begitu dilepas. Pemain melihat hasil kerjanya bergerak tiap detik,
## bukan menatap cincin yang mengisi sendiri.
##
## Badannya menghalangi AIR, bukan ikan. Sebelumnya benar-benar padat terhadap
## ikan, dan itu salah dua kali: menekan lingkaran sebesar 86 px membuat ikan
## MELUNCUR menyusuri lengkungannya lalu terlepas sendiri (rasa licin),
## sementara pemain yang terus menahan tombol malah menggasak dinding tanpa maju
## (rasa nyangkut). Padahal ikan wader seukuran itu memang muat menyelinap di
## sela-sela batang bambu -- yang tidak muat lewat justru airnya. Jadi badannya
## sekarang ada di lapisan fisika sendiri ("sumbatan") yang tidak dipedulikan
## ikan. Tebing sungai tetap padat seperti biasa.

signal cleared

## Aturan kedua Map 3 -- urutan. Air yang dilepas dari HULU ditahan sumbatan
## berikutnya di hilir; air yang dilepas dari HILIR tidak ditahan apa pun dan
## seluruh kolam menghambur. Wasit yang menghitungnya; sumbatan cuma memasang
## penandanya supaya pemain bisa membaca akibatnya sebelum bertindak.

@export_group("Dorongan")
## Ke mana sumbatan ini harus digeser supaya lepas dari jalur air.
@export var arah_dorong: Vector2 = Vector2(-0.3, 1.0)
## Sejauh apa harus digeser sampai benar-benar lepas.
@export var jarak_lepas: float = 210.0
## Seberapa dekat ikan harus berada supaya tenaganya terhitung.
@export var radius_dorong: float = 175.0

@export_group("Berat")
## Tenaga total yang harus dilampaui sebelum sumbatan mau bergerak sama sekali.
## Sengaja di atas tenaga satu ikan mana pun -- di sinilah "butuh berdua" itu
## dipaksakan oleh fisikanya, bukan oleh pemeriksaan jumlah.
##
## Angkanya diturunkan dari 1,6 setelah dilaporkan terasa berat. Dengan 1,6,
## dorongan yang melenceng 60 derajat menghasilkan tepat 1,6 -- yaitu NOL
## kemajuan. Pemain yang merasa sudah mendorong tapi tidak melihat apa pun
## bergerak akan menyimpulkan mekaniknya rusak, bukan bahwa sudutnya kurang
## tepat. Sekarang dorongan miring tetap maju, cuma pelan.
@export var ambang_gerak: float = 1.5
## Sumbangan ikan yang sedang menahan (mengganjal) di sisi yang benar.
@export var tenaga_ganjal: float = 1.0
## Sumbangan maksimum ikan yang sedang berenang menekan.
@export var tenaga_dorong: float = 1.2
## Kecepatan geser saat didorong sekuat-kuatnya, piksel per detik.
@export var kecepatan_geser: float = 120.0
## Kecepatan melorot balik saat tenaganya kurang. Jauh lebih lambat daripada
## mendorong: kesalahan sesaat tidak boleh menghapus kerja setengah menit.
@export var kecepatan_lorot: float = 20.0

@export_group("Rasa")
@export var color_idle: Color = Color(0.42, 0.33, 0.19)
@export var color_partial: Color = Color(0.98, 0.76, 0.29)
@export var color_ready: Color = Color(0.35, 0.87, 0.98)

@export_group("Penanda ramalan")
@export var warna_aman: Color = Color(0.55, 0.85, 0.72)
@export var warna_deras: Color = Color(1.0, 0.55, 0.36)

## Diisi wasit: true berarti tidak ada lagi sumbatan di hilir yang menahan air.
var akan_deras: bool = false

var _fish: Array[Node2D] = []
## Seberapa jauh sudah tergeser, dalam piksel.
var _geser: float = 0.0
var _tenaga: float = 0.0
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

var _label: Label = null
var _panah: Line2D = null
## Jejak samar di posisi tujuan -- pemain harus tahu ke mana benda ini dibawa.
var _bayangan: Line2D = null
var _percik: CPUParticles2D = null


## Dipanggil map3_manager: sumbatan perlu tahu ikan mana saja yang dihitung.
func setup(fish: Array[Node2D]) -> void:
	_fish = fish


func _ready() -> void:
	add_to_group("obstacle")
	_ring.visible = false
	_link_a.visible = false
	_link_b.visible = false
	_outline.default_color = color_idle
	_bangun_bayangan()
	_bangun_percik()
	_bangun_penanda()


# --- Dorongan ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _done or _fish.size() < 2:
		return

	_tenaga = _hitung_tenaga()

	if _tenaga > ambang_gerak:
		# Sisa tenaga di atas ambang menentukan kecepatannya. Tepat di ambang
		# artinya nyaris tidak bergerak -- dan itu terasa benar: benda berat yang
		# baru saja mulai menyerah memang merambat dulu sebelum meluncur.
		var sisa := (_tenaga - ambang_gerak) / maxf(_tenaga_maksimum() - ambang_gerak, 0.01)
		_geser = minf(_geser + kecepatan_geser * clampf(sisa, 0.0, 1.0) * delta, jarak_lepas)
		_detak(delta)
		if _geser >= jarak_lepas:
			_break_apart()
			return
	else:
		_geser = maxf(_geser - kecepatan_lorot * delta, 0.0)

	_gerakkan_visual()
	_refresh_visual(delta)


## Tenaga total dari kedua ikan.
##
## Aturannya berbeda untuk ikan yang dipegang pemain dan yang ditinggal, dan
## perbedaan itulah yang membuat bab ini bukan lagi soal memarkir:
##
##   dipegang  -- dihitung dari KECEPATAN RENANGNYA searah dorongan. Diam sama
##                dengan nol. Pemain harus menahan tombol.
##   ditinggal -- dihitung dari POSISINYA saja. Dia mengganjal, dan ganjalan
##                tidak butuh gerakan. Tapi harus di sisi yang benar.
func _hitung_tenaga() -> float:
	var arah := arah_dorong.normalized()
	var total := 0.0
	for ikan in _fish:
		if not is_instance_valid(ikan):
			continue
		if global_position.distance_to(ikan.global_position) > radius_dorong:
			continue
		if not _di_sisi_yang_benar(ikan, arah):
			continue

		if ikan.is_active:
			var laju: Vector2 = ikan.velocity
			if laju.length() < 12.0:
				continue
			total += tenaga_dorong * clampf(laju.normalized().dot(arah), 0.0, 1.0)
		else:
			total += tenaga_ganjal
	return total


## Ikan hanya bisa mendorong dari sisi yang BERLAWANAN dengan arah dorong --
## sama seperti orang tidak bisa mendorong lemari dengan berdiri di depannya.
## Tanpa aturan ini, menempel di mana saja sudah cukup, dan penempatan ikan
## berhenti jadi keputusan.
func _di_sisi_yang_benar(ikan: Node2D, arah: Vector2) -> bool:
	var ke_ikan := (ikan.global_position - global_position).normalized()
	return ke_ikan.dot(arah) < -0.15


func _tenaga_maksimum() -> float:
	return tenaga_dorong + tenaga_ganjal


func ratio() -> float:
	return clampf(_geser / maxf(jarak_lepas, 0.01), 0.0, 1.0)


## Sudah terdorong lepas. Dipakai wasit untuk tahu siapa yang masih menahan air.
##
## Diperlukan terpisah dari is_queued_for_deletion() karena sumbatan hidup
## sekitar satu detik lagi setelah terbuka -- selama tween pecahnya berjalan.
func akan_pecah() -> bool:
	return _done


func _gerakkan_visual() -> void:
	var arah := arah_dorong.normalized()
	_visual.position = arah * _geser
	# Ikut berputar sedikit selama tergeser. Benda yang bergeser lurus tanpa
	# berputar terbaca sebagai gambar yang digeser; yang ikut miring terbaca
	# sebagai benda yang benar-benar terdesak.
	_visual.rotation = deg_to_rad(16.0) * ratio()
	_shape.position = arah * _geser


# --- Umpan balik ------------------------------------------------------------

## Detak yang makin rapat saat makin dekat lepas. Penting untuk pemain yang
## sedang menatap ikannya, bukan menatap sumbatannya.
func _detak(delta: float) -> void:
	_tick_cooldown -= delta
	if _tick_cooldown > 0.0:
		return
	var r := ratio()
	_tick_cooldown = lerpf(0.3, 0.1, r)
	AudioManager.play("link_tick", -5.0, 0.8 + 0.6 * r, 0.02)


func _refresh_visual(delta: float) -> void:
	_pulse += delta

	var bergerak := _tenaga > ambang_gerak
	var colour := color_idle
	if bergerak:
		colour = color_ready
	elif _tenaga > 0.01:
		# Berdenyut supaya jelas ini keadaan "ada tenaga tapi belum cukup",
		# bukan keadaan diam.
		colour = color_partial
		colour.a = 0.55 + 0.45 * absf(sin(_pulse * 5.0))

	_outline.default_color = colour
	_outline.width = 5.0 + (3.0 if bergerak else 0.0)

	if _percik != null:
		_percik.emitting = bergerak
		_percik.position = arah_dorong.normalized() * _geser

	# Cincin progres digambar ulang tiap frame sebagai busur sepanjang rasio.
	var r := ratio()
	_ring.visible = r > 0.01
	if _ring.visible:
		_ring.default_color = color_ready if bergerak else color_partial
		_ring.points = _arc_points(radius_dorong * 0.4, r)
		_ring.position = arah_dorong.normalized() * _geser

	_refresh_link(_link_a, 0)
	_refresh_link(_link_b, 1)


## Garis penghubung ke tiap ikan yang tenaganya terhitung. Warnanya membedakan
## ikan yang sedang MENDORONG dari yang cuma MENGGANJAL, supaya pemain tahu
## bagian mana yang masih kurang.
func _refresh_link(line: Line2D, index: int) -> void:
	if index >= _fish.size() or not is_instance_valid(_fish[index]):
		line.visible = false
		return
	var ikan: Node2D = _fish[index]
	var arah := arah_dorong.normalized()
	var terpakai: bool = (
		global_position.distance_to(ikan.global_position) <= radius_dorong
		and _di_sisi_yang_benar(ikan, arah)
	)
	line.visible = terpakai
	if not terpakai:
		return
	line.points = PackedVector2Array([Vector2.ZERO, to_local(ikan.global_position)])
	line.default_color = color_ready if _tenaga > ambang_gerak else color_partial
	line.default_color.a = 0.5


func _arc_points(radius: float, portion: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := maxi(int(48.0 * portion), 2)
	for i in segments + 1:
		# Dimulai dari atas (-PI/2) dan berputar searah jarum jam, sama seperti
		# arah orang membaca hitungan mundur.
		var angle := -PI * 0.5 + TAU * portion * (float(i) / float(segments))
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


# --- Bagian yang dirakit di kode --------------------------------------------

## Bayangan tujuan: salinan samar bentuk sumbatan di tempat dia harus berakhir.
## Tanpa ini pemain tahu harus mendorong, tapi tidak tahu sampai kapan -- dan
## usaha yang tidak punya garis akhir terasa seperti usaha yang sia-sia.
func _bangun_bayangan() -> void:
	_bayangan = Line2D.new()
	_bayangan.points = _outline.points
	_bayangan.width = 3.0
	_bayangan.default_color = Color(1, 1, 1, 0.16)
	_bayangan.position = arah_dorong.normalized() * jarak_lepas
	add_child(_bayangan)
	move_child(_bayangan, 0)


## Percikan di titik dorong. Satu-satunya isyarat yang bilang "SEKARANG kamu
## sedang berhasil" tanpa pemain harus melihat angka mana pun.
func _bangun_percik() -> void:
	_percik = CPUParticles2D.new()
	_percik.amount = 22
	_percik.lifetime = 0.6
	_percik.emitting = false
	_percik.spread = 55.0
	_percik.gravity = Vector2.ZERO
	_percik.direction = -arah_dorong.normalized()
	_percik.initial_velocity_min = 60.0
	_percik.initial_velocity_max = 190.0
	_percik.scale_amount_min = 1.5
	_percik.scale_amount_max = 3.5
	_percik.color = Color(0.8, 0.93, 0.97, 0.55)
	add_child(_percik)


func _bangun_penanda() -> void:
	_label = Label.new()
	_label.size = Vector2(300.0, 34.0)
	_label.position = Vector2(-150.0, -196.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.07, 0.95))
	_label.add_theme_constant_override("outline_size", 9)
	add_child(_label)

	# Panah menunjuk ke HILIR (kiri), arah air akan lari kalau sumbatan ini
	# dibuka. Hanya muncul pada keadaan DERAS: penanda yang selalu tampil di
	# semua sumbatan tidak membedakan apa pun, dan yang tidak membedakan
	# apa-apa akan berhenti dibaca.
	_panah = Line2D.new()
	_panah.width = 6.0
	_panah.points = PackedVector2Array([
		Vector2(60.0, -160.0), Vector2(-60.0, -160.0),
		Vector2(-34.0, -178.0), Vector2(-60.0, -160.0), Vector2(-34.0, -142.0),
	])
	_panah.visible = false
	add_child(_panah)
	_segarkan_penanda()


## Dipanggil wasit tiap kali peta berubah keadaan.
func set_akan_deras(nilai: bool) -> void:
	if akan_deras == nilai:
		return
	akan_deras = nilai
	_segarkan_penanda()


func _segarkan_penanda() -> void:
	if _label == null:
		return
	if _done:
		_label.visible = false
		_panah.visible = false
		return
	_label.visible = true
	if akan_deras:
		_label.text = "AWAS  -  DERAS"
		_label.add_theme_color_override("font_color", warna_deras)
		_panah.default_color = warna_deras
		_panah.visible = true
	else:
		_label.text = "AMAN"
		_label.add_theme_color_override("font_color", warna_aman)
		_panah.visible = false


# --- Terdorong lepas --------------------------------------------------------

func _break_apart() -> void:
	_done = true
	set_physics_process(false)
	# Tabrakan dimatikan lewat set_deferred: mengubahnya di tengah langkah
	# fisika yang sedang berjalan dilarang Godot.
	_shape.set_deferred("disabled", true)
	_ring.visible = false
	_link_a.visible = false
	_link_b.visible = false
	_bayangan.visible = false
	if _percik != null:
		_percik.emitting = false
	_segarkan_penanda()
	_burst.emitting = true
	AudioManager.play("bamboo_break", 2.0, 1.0, 0.03)

	cleared.emit()

	# Meluncur terakhir lalu pecah. Sudah didorong sejauh jarak_lepas oleh
	# pemain; sisanya dilepas arus, dan itu yang membuatnya terbaca sebagai
	# "akhirnya hanyut" bukan "meledak sendiri".
	var arah := arah_dorong.normalized()
	var tween := create_tween()
	tween.tween_property(_visual, "position", arah * (jarak_lepas + 190.0), 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_visual, "rotation", deg_to_rad(52.0), 0.6)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)
