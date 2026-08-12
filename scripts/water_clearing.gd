extends Node
## Air yang MEMBERSIH saat sungainya selesai dibersihkan.
##
## Selama ini kemenangan cuma diumumkan lewat tulisan. Padahal seluruh isi bab
## ini adalah membuat sungai jadi bersih -- dan satu-satunya hal yang tidak
## pernah berubah justru airnya sendiri. Pemain diberi tahu bahwa dia berhasil,
## bukan diperlihatkan.
##
## Node ini mengubah air keruh jadi jernih di depan mata pemain. Empat lapis,
## semuanya berjalan bersamaan supaya terbaca sebagai SATU kejadian:
##
##   1. Warna air        keruh kehijauan -> biru jernih
##   2. Berkas cahaya    menembus lebih terang, seolah dasar sungai kelihatan
##   3. Gelembung        naik lebih rapat, tanda air yang hidup lagi
##   4. Kilau menyapu    satu sapuan terang dari kiri ke kanan
##
## Dipasang wasit peta lewat mulai(), bukan lewat sinyal, karena momennya harus
## PERSIS sama dengan pengumuman menang -- bukan sepersekian detik sesudahnya.

## Berapa lama air berubah jernih. Sengaja lama: perubahan yang terlalu cepat
## terbaca sebagai lampu yang dinyalakan, bukan sebagai air yang mengendap.
@export var lama: float = 2.6

## Warna air jernih di permukaan dan di dasar.
@export var jernih_atas: Color = Color(0.42, 0.72, 0.74)
@export var jernih_bawah: Color = Color(0.13, 0.36, 0.42)

var _air: Polygon2D = null
var _berkas: Node2D = null
var _gelembung: Node2D = null


## dunia: ukuran peta, dipakai membentangkan kilau menyapu.
func mulai(air: Polygon2D, berkas: Node2D, gelembung: Node2D, dunia: Vector2) -> void:
	_air = air
	_berkas = berkas
	_gelembung = gelembung

	if _air != null:
		_bening_kan_air()
	if _berkas != null:
		_terangkan_berkas()
	if _gelembung != null:
		_rapatkan_gelembung()
	_sapukan_kilau(dunia)


## Warna Polygon2D disimpan sebagai empat titik sudut (dua atas, dua bawah),
## jadi gradasinya diubah dengan menganimasikan keempatnya sekaligus. Tidak ada
## properti "warna gradasi" yang bisa di-tween langsung, jadi nilainya dihitung
## sendiri lewat tween_method.
func _bening_kan_air() -> void:
	var awal := _air.vertex_colors
	if awal.size() < 4:
		return
	var atas_awal := awal[0]
	var bawah_awal := awal[2]

	var jalan := create_tween()
	jalan.tween_method(
		func(t: float) -> void:
			var a := atas_awal.lerp(jernih_atas, t)
			var b := bawah_awal.lerp(jernih_bawah, t)
			_air.vertex_colors = PackedColorArray([a, a, b, b]),
		0.0, 1.0, lama
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _terangkan_berkas() -> void:
	create_tween().tween_property(_berkas, "modulate",
		Color(1.35, 1.3, 1.15, 1.0), lama).set_trans(Tween.TRANS_SINE)


func _rapatkan_gelembung() -> void:
	for anak in _gelembung.get_children():
		if anak is CPUParticles2D:
			var p := anak as CPUParticles2D
			# Jumlahnya dinaikkan, bukan diganti dengan pemancar baru: partikel
			# yang sudah melayang tetap di tempatnya, jadi perubahannya terbaca
			# sebagai sungai yang makin hidup, bukan sebagai efek yang di-reset.
			p.amount = int(p.amount * 2.2)
			p.restart()


## Satu sapuan terang melintasi peta, seperti cahaya yang akhirnya tembus.
## Inilah yang membuat perubahan warna terbaca sebagai KEJADIAN, bukan sebagai
## layar yang pelan-pelan berganti tema.
func _sapukan_kilau(dunia: Vector2) -> void:
	var induk := get_parent()
	if induk == null:
		return

	var kilau := Polygon2D.new()
	var lebar := 320.0
	kilau.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(lebar, 0),
		Vector2(lebar - 90.0, dunia.y), Vector2(-90.0, dunia.y),
	])
	kilau.color = Color(0.75, 0.95, 1.0, 0.0)
	kilau.position = Vector2(-lebar, 0)
	induk.add_child(kilau)

	var jalan := create_tween()
	jalan.tween_property(kilau, "color:a", 0.3, lama * 0.25)
	jalan.parallel().tween_property(kilau, "position:x", dunia.x + lebar, lama * 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jalan.tween_property(kilau, "color:a", 0.0, lama * 0.3)
	jalan.tween_callback(kilau.queue_free)
