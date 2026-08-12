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

## Muka yang siap didorong. Kuning = kurang ikan, biru = tenaga sudah cukup.
const WARNA_MUKA_KURANG := Color(0.98, 0.76, 0.29)
const WARNA_MUKA_CUKUP := Color(0.35, 0.87, 0.98)

var _ukuran: float = 120.0
var _petak: float = 140.0
var _badan: Node2D
var _lencana: Label
var _muka: Line2D
var _panah: Line2D
## Bingkai samar di petak tujuan -- pengganti kisi yang dulu digambar penuh.
var _bayang: Line2D


func pasang(petak: float, itu_besar: bool) -> void:
	besar = itu_besar
	_petak = petak
	# Balok besar sengaja hampir memenuhi petaknya. Beratnya harus terbaca dari
	# siluetnya saja, sebelum pemain sempat mencoba mendorongnya sendirian.
	_ukuran = petak * (0.86 if besar else 0.72)

	collision_layer = 16
	collision_mask = 0

	var setengah := _ukuran * 0.5

	_badan = Node2D.new()
	add_child(_badan)
	_gambar_ikatan(setengah)

	var bentuk := RectangleShape2D.new()
	bentuk.size = Vector2(_ukuran, _ukuran)
	var tabrakan := CollisionShape2D.new()
	tabrakan.shape = bentuk
	add_child(tabrakan)

	# Muka yang menyala: satu garis tebal menempel di sisi yang bisa didorong.
	_muka = Line2D.new()
	_muka.width = 11.0
	_muka.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_muka.end_cap_mode = Line2D.LINE_CAP_ROUND
	_muka.visible = false
	add_child(_muka)

	_panah = Line2D.new()
	_panah.width = 6.0
	_panah.visible = false
	add_child(_panah)

	# Bingkai petak tujuan.
	#
	# Kisi penuh sudah dihapus karena membuat sungainya terlihat seperti kertas
	# milimeter. Tapi pemain tetap perlu tahu SEJAUH APA satu dorongan
	# memindahkan balok -- jadi petaknya ditunjukkan hanya saat dibutuhkan, di
	# tempat yang memang sedang dilihat pemain.
	var b := _petak * 0.42
	_bayang = Line2D.new()
	_bayang.points = PackedVector2Array([
		Vector2(-b, -b), Vector2(b, -b), Vector2(b, b), Vector2(-b, b), Vector2(-b, -b),
	])
	_bayang.width = 3.0
	_bayang.visible = false
	add_child(_bayang)

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


## Ikatan batang bambu, bukan kotak polos.
##
## Bentuk tabrakannya tetap kotak sepetak -- itu yang membuat dorongannya
## terbaca dan tidak licin. Tapi yang DILIHAT pemain tidak harus ikut kotak.
## Batang yang panjangnya beda-beda dan sedikit miring membuat baloknya terbaca
## sebagai tumpukan bambu yang terseret arus, bukan sebagai petak papan catur.
##
## Miringnya diambil dari ukuran dan nomor batang, bukan dari randf(), supaya
## semua balok tampak konsisten tiap kali papan dimuat ulang.
func _gambar_ikatan(setengah: float) -> void:
	var jumlah := 6 if besar else 5
	var warna_batang := [
		Color(0.46, 0.37, 0.2), Color(0.55, 0.45, 0.25), Color(0.38, 0.31, 0.17),
	]
	if besar:
		warna_batang = [
			Color(0.34, 0.28, 0.17), Color(0.42, 0.35, 0.21), Color(0.28, 0.23, 0.14),
		]

	for i in jumlah:
		var t := (float(i) + 0.5) / float(jumlah)
		var y := lerpf(-setengah * 0.86, setengah * 0.86, t)
		# Batang paling tengah dibuat paling panjang, yang di tepi lebih pendek --
		# siluetnya jadi membulat seperti ikatan yang diikat di tengah.
		var panjang := setengah * lerpf(0.72, 1.0, sin(t * PI))
		var miring := deg_to_rad(lerpf(-9.0, 9.0, fmod(float(i) * 0.37, 1.0)))
		var arah := Vector2.RIGHT.rotated(miring)
		var tebal := setengah * (0.2 if besar else 0.18)

		var batang := Line2D.new()
		batang.points = PackedVector2Array([
			Vector2(0.0, y) - arah * panjang, Vector2(0.0, y) + arah * panjang,
		])
		batang.width = tebal * 2.0
		batang.begin_cap_mode = Line2D.LINE_CAP_ROUND
		batang.end_cap_mode = Line2D.LINE_CAP_ROUND
		batang.default_color = warna_batang[i % warna_batang.size()]
		_badan.add_child(batang)

		# Satu garis tipis di punggung batang: buku-buku bambu.
		var buku := Line2D.new()
		buku.points = PackedVector2Array([
			Vector2(0.0, y - tebal * 0.35) - arah * panjang * 0.8,
			Vector2(0.0, y - tebal * 0.35) + arah * panjang * 0.8,
		])
		buku.width = 2.0
		buku.default_color = Color(1, 1, 1, 0.1)
		_badan.add_child(buku)

	# Dua tali pengikat melintang. Inilah yang membuat tumpukan batang terbaca
	# sebagai SATU benda yang bisa didorong, bukan sebagai beberapa batang lepas.
	for sisi in [-1.0, 1.0]:
		var tali := Line2D.new()
		tali.points = PackedVector2Array([
			Vector2(setengah * 0.42 * sisi, -setengah * 0.98),
			Vector2(setengah * 0.42 * sisi, setengah * 0.98),
		])
		tali.width = setengah * 0.13
		tali.default_color = Color(0.24, 0.2, 0.12)
		_badan.add_child(tali)


## Dipanggil wasit tiap frame. arah = arah dorong yang sedang mungkin
## (Vector2.ZERO berarti tidak ada), cukup = tenaganya sudah memadai.
func sorot_muka(arah: Vector2i, cukup: bool) -> void:
	if arah == Vector2i.ZERO or sibuk:
		_muka.visible = false
		_panah.visible = false
		_bayang.visible = false
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

	_bayang.position = d * _petak
	_bayang.default_color = _muka.default_color
	_bayang.default_color.a = 0.3
	_bayang.visible = true


## Meluncur ke petak berikutnya. Wasit sudah memastikan tujuannya kosong.
func geser_ke(tujuan: Vector2, lama: float) -> void:
	sibuk = true
	_muka.visible = false
	_panah.visible = false
	_bayang.visible = false
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
