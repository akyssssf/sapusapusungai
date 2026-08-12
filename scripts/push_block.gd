extends StaticBody2D
## Balok bambu yang didorong ikan, satu petak sekali dorong.
##
## Balok ini SENGAJA bodoh: dia tidak tahu ada petak, tidak tahu ada air, dan
## tidak pernah memutuskan sendiri boleh pindah atau tidak. Semua itu urusan
## wasit, karena hanya wasit yang tahu isi seluruh papan. Balok yang memutuskan
## sendiri harus menyimpan salinan keadaan papan, dan dua salinan keadaan yang
## sama selalu berakhir berbeda.
##
## Yang diurus balok cuma tiga: bagaimana rupanya, bagaimana dia meluncur ke
## petak berikutnya, dan MUKA MANA yang sedang bisa didorong.
##
## Muka yang menyala itu jawaban langsung atas keluhan "ga tau titiknya di
## mana". Begitu ikan berada di tempat yang benar untuk mendorong, sisi balok
## yang bersangkutan menyala terang dan muncul panah ke arah dorongnya. Pemain
## tidak perlu menebak apa pun.

## Dinyalakan wasit lewat pasang(). Balok besar butuh dua ikan.
var besar: bool = false
## Sedang meluncur ke petak berikutnya; selama ini dia tidak menerima dorongan.
var sibuk: bool = false

const WARNA_KECIL := Color(0.55, 0.43, 0.24)
const WARNA_KECIL_TEPI := Color(0.72, 0.58, 0.33)
const WARNA_BESAR := Color(0.38, 0.31, 0.2)
const WARNA_BESAR_TEPI := Color(0.62, 0.52, 0.3)
## Muka yang siap didorong. Kuning = kurang ikan, biru = tenaga sudah cukup.
const WARNA_MUKA_KURANG := Color(0.98, 0.76, 0.29)
const WARNA_MUKA_CUKUP := Color(0.35, 0.87, 0.98)

var _ukuran: float = 120.0
var _badan: Polygon2D
var _tepi: Line2D
var _lencana: Label
var _muka: Line2D
var _panah: Line2D
var _serat: Node2D


func pasang(petak: float, itu_besar: bool) -> void:
	besar = itu_besar
	# Balok besar sengaja hampir memenuhi petaknya. Beratnya harus terbaca dari
	# siluetnya saja, sebelum pemain sempat mencoba mendorongnya sendirian.
	_ukuran = petak * (0.86 if besar else 0.72)

	collision_layer = 16
	collision_mask = 0

	var setengah := _ukuran * 0.5
	var kotak := PackedVector2Array([
		Vector2(-setengah, -setengah), Vector2(setengah, -setengah),
		Vector2(setengah, setengah), Vector2(-setengah, setengah),
	])

	_badan = Polygon2D.new()
	_badan.polygon = kotak
	_badan.color = WARNA_BESAR if besar else WARNA_KECIL
	add_child(_badan)

	_serat = Node2D.new()
	add_child(_serat)
	_gambar_serat(setengah)

	_tepi = Line2D.new()
	_tepi.points = kotak + PackedVector2Array([kotak[0]])
	_tepi.width = 5.0 if besar else 4.0
	_tepi.default_color = WARNA_BESAR_TEPI if besar else WARNA_KECIL_TEPI
	add_child(_tepi)

	var bentuk := RectangleShape2D.new()
	bentuk.size = Vector2(_ukuran, _ukuran)
	var tabrakan := CollisionShape2D.new()
	tabrakan.shape = bentuk
	add_child(tabrakan)

	# Muka yang menyala: satu garis tebal menempel di sisi yang bisa didorong.
	_muka = Line2D.new()
	_muka.width = 11.0
	_muka.visible = false
	add_child(_muka)

	_panah = Line2D.new()
	_panah.width = 6.0
	_panah.visible = false
	add_child(_panah)

	if besar:
		# Balok besar diberi label "2 IKAN" secara harfiah. Isyarat visual saja
		# (lebih besar, lebih gelap) ternyata tidak cukup -- pemain menyimpulkan
		# "baloknya macet", bukan "baloknya butuh bantuan".
		_lencana = Label.new()
		_lencana.text = "2 IKAN"
		_lencana.size = Vector2(200.0, 28.0)
		_lencana.position = Vector2(-100.0, -14.0)
		_lencana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lencana.add_theme_font_size_override("font_size", 21)
		_lencana.add_theme_color_override("font_color", Color(1, 0.88, 0.62))
		_lencana.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.95))
		_lencana.add_theme_constant_override("outline_size", 8)
		add_child(_lencana)


## Beberapa garis miring supaya baloknya terbaca sebagai IKATAN BAMBU, bukan
## sebagai kotak polos. Digambar acak-tetap dari ukurannya, bukan dari randf(),
## supaya semua balok tetap konsisten tiap kali peta dimuat ulang.
func _gambar_serat(setengah: float) -> void:
	for i in 4:
		var t := (float(i) + 0.5) / 4.0
		var garis := Line2D.new()
		var y := lerpf(-setengah, setengah, t)
		garis.points = PackedVector2Array([
			Vector2(-setengah * 0.92, y - setengah * 0.1),
			Vector2(setengah * 0.92, y + setengah * 0.1),
		])
		garis.width = 3.0
		garis.default_color = Color(0, 0, 0, 0.16)
		_serat.add_child(garis)


## Dipanggil wasit tiap frame. arah = arah dorong yang sedang mungkin
## (Vector2.ZERO berarti tidak ada), cukup = tenaganya sudah memadai.
func sorot_muka(arah: Vector2i, cukup: bool) -> void:
	if arah == Vector2i.ZERO or sibuk:
		_muka.visible = false
		_panah.visible = false
		return

	var d := Vector2(arah)
	var setengah := _ukuran * 0.5
	# Muka yang disorot adalah sisi yang BERLAWANAN arah dorong -- sisi tempat
	# ikan menempel. Itu yang perlu dilihat pemain, bukan sisi depannya.
	var tengah := -d * setengah
	var lebar := Vector2(-d.y, d.x) * setengah * 0.86

	_muka.points = PackedVector2Array([tengah - lebar, tengah + lebar])
	_muka.default_color = WARNA_MUKA_CUKUP if cukup else WARNA_MUKA_KURANG
	_muka.visible = true

	var ujung := d * setengah * 1.5
	var pangkal := d * setengah * 0.55
	var sayap := Vector2(-d.y, d.x) * setengah * 0.3
	_panah.points = PackedVector2Array([
		pangkal, ujung, ujung - d * setengah * 0.4 + sayap,
		ujung, ujung - d * setengah * 0.4 - sayap,
	])
	_panah.default_color = _muka.default_color
	_panah.visible = true


## Meluncur ke petak berikutnya. Wasit sudah memastikan tujuannya kosong.
func geser_ke(tujuan: Vector2, lama: float) -> void:
	sibuk = true
	_muka.visible = false
	_panah.visible = false
	AudioManager.play("bamboo_break", -6.0, 0.7, 0.05)

	var jalan := create_tween()
	jalan.tween_property(self, "position", tujuan, lama) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Sedikit gepeng ke arah geser lalu kembali. Balok yang meluncur mulus tanpa
	# perubahan bentuk terbaca sebagai gambar yang dipindah; yang sedikit
	# tersentak terbaca sebagai benda berat yang baru saja menyerah.
	jalan.parallel().tween_property(_badan, "scale", Vector2(1.08, 0.92), lama * 0.4)
	jalan.chain().tween_property(_badan, "scale", Vector2.ONE, lama * 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jalan.tween_callback(func() -> void: sibuk = false)
