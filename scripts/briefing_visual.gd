class_name BriefingVisual
extends RefCounted
## Perakit gambar untuk papan instruksi.
##
## Sebelum ini papan instruksinya seluruhnya teks -- tiga kolom kalimat yang
## harus dibaca sebelum pemain boleh menyentuh apa pun. Masalahnya bukan panjang
## kalimatnya, melainkan JENISNYA: aturan yang isinya perbandingan ukuran dan
## letak tombol adalah aturan spasial, dan aturan spasial yang dijelaskan dengan
## kalimat memaksa pemain menerjemahkannya balik jadi gambar di kepalanya.
##
## Ketiga perakit di bawah ini menggantikan bagian yang paling tidak cocok
## dijadikan kalimat:
##
##   tuts()          gambar tombol, bukan tulisan "tekan W A S D"
##   tangga_ukuran() perbandingan ikan lawan sampah, langsung terlihat
##   denah_papan()   denah lorong Bab 3 dan ke mana balok harus didorong
##
## Semuanya digambar dari kode, bukan berkas gambar, supaya angkanya selalu
## ikut kalau keseimbangan permainannya diubah. Tangga ukuran di bawah membaca
## radius yang sama persis dengan yang dipakai sampah sungguhan -- jadi papan
## instruksi tidak akan pernah berbohong soal ukuran, sekalipun angkanya diubah
## besok.

const TrashScript := preload("res://scripts/trash.gd")
const CONTOH_SAMPAH := [
	preload("res://assets/environment/plastic_bottle.png"),
	preload("res://assets/environment/kresek_bag.png"),
	preload("res://assets/environment/trash_pile.png"),
]
const TEKSTUR_IKAN := preload("res://assets/aset gemastik/wader_bintik/swim_right/swim_right_01.png")

## Tangga ukuran digambar lebih besar daripada ukuran aslinya di dalam
## permainan. Perbandingannya tetap persis, cuma seluruhnya dibesarkan --
## papan instruksi dibaca sekali dari jarak duduk, bukan dipelototi.
const SKALA := 1.55

const WARNA_BISA := Color(0.45, 0.92, 0.62)
const WARNA_BELUM := Color(1, 1, 1, 0.22)


## Sebuah tombol keyboard yang digambar sebagai tuts, bukan ditulis.
static func tuts(huruf: String, lebar: float = 44.0) -> Control:
	var kotak := PanelContainer.new()
	kotak.custom_minimum_size = Vector2(lebar, 44.0)
	kotak.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.14, 0.19, 0.22)
	gaya.set_border_width_all(2)
	# Sisi bawah dibuat lebih tebal supaya tutsnya terlihat punya tinggi.
	gaya.border_width_bottom = 5
	gaya.border_color = Color(0.55, 0.66, 0.72)
	gaya.set_corner_radius_all(7)
	kotak.add_theme_stylebox_override("panel", gaya)

	var label := Label.new()
	label.text = huruf
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	kotak.add_child(label)
	return kotak


## Sederet tuts beserta artinya, misal [W][A][S][D]  berenang.
static func baris_tuts(tombol: Array, arti: String) -> Control:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	for t in tombol:
		var nama := String(t)
		baris.add_child(tuts(nama, 44.0 if nama.length() <= 1 else 26.0 + 15.0 * float(nama.length())))

	var jarak := Control.new()
	jarak.custom_minimum_size.x = 12.0
	baris.add_child(jarak)

	var label := Label.new()
	label.text = arti
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.86, 0.93, 0.96))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(label)
	return baris


## Perbandingan ikan lawan ketiga tingkat sampah, digambar sebenar-benarnya.
##
## Inilah pengganti kalimat "makan sampah yang lebih kecil darimu". Satu baris
## gambar menjawabnya lebih cepat daripada kalimat mana pun, dan yang lebih
## penting: pemain melihat SEBERAPA BESAR bedanya, bukan cuma tahu ada bedanya.
static func tangga_ukuran() -> Control:
	var wadah := VBoxContainer.new()
	wadah.add_theme_constant_override("separation", 8)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	baris.alignment = BoxContainer.ALIGNMENT_CENTER

	# Ikan level 1 sebagai pembanding. Garis tengahnya 45 px, sama seperti di
	# dalam permainan.
	baris.add_child(_petak(TEKSTUR_IKAN, 45.0 * SKALA, "ikan kamu", Color(1, 0.93, 0.7), true))

	var vs := Label.new()
	vs.text = "vs"
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 16)
	vs.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	baris.add_child(vs)

	for i in CONTOH_SAMPAH.size():
		var data: Dictionary = TrashScript.TIER_DATA[i]
		var garis_tengah: float = float(data["radius"]) * 2.0 * SKALA
		var perlu: int = int(data["butuh_level"])
		var bisa := perlu <= 1
		baris.add_child(_petak(CONTOH_SAMPAH[i], garis_tengah,
			"bisa" if bisa else "ukuran %d" % perlu,
			WARNA_BISA if bisa else Color(1, 1, 1, 0.5), bisa))

	wadah.add_child(baris)

	var catatan := Label.new()
	catatan.text = "Lebih kecil dari mulutmu = bisa ditelan. Lebih besar = kehilangan nyawa."
	catatan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catatan.add_theme_font_size_override("font_size", 15)
	catatan.add_theme_color_override("font_color", Color(0.8, 0.88, 0.92))
	catatan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wadah.add_child(catatan)
	return wadah


static func _petak(tekstur: Texture2D, garis_tengah: float, keterangan: String,
		warna: Color, terang: bool) -> Control:
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 4)

	# Tinggi kotak disamakan untuk semua supaya gambarnya berbaris rata BAWAH,
	# dan bedanya terbaca sebagai tangga yang menaik.
	var bingkai := Control.new()
	bingkai.custom_minimum_size = Vector2(maxf(garis_tengah, 56.0), 142.0)

	var gambar := TextureRect.new()
	gambar.texture = tekstur
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.size = Vector2(garis_tengah, garis_tengah)
	gambar.position = Vector2(
		(bingkai.custom_minimum_size.x - garis_tengah) * 0.5, 142.0 - garis_tengah)
	gambar.modulate = Color.WHITE if terang else Color(0.62, 0.68, 0.72, 0.75)
	bingkai.add_child(gambar)
	kolom.add_child(bingkai)

	var label := Label.new()
	label.text = keterangan
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", warna)
	kolom.add_child(label)
	return kolom


## Denah kecil papan Bab 3: lorong air, tepian, dan ke mana balok didorong.
static func denah_papan() -> Control:
	var wadah := VBoxContainer.new()
	wadah.add_theme_constant_override("separation", 8)

	var kanvas := Control.new()
	kanvas.custom_minimum_size = Vector2(360.0, 150.0)
	var petak := 34.0

	# Tiga baris: tepian, lorong, tepian.
	for baris in 3:
		for kolom in 9:
			var sel := ColorRect.new()
			sel.size = Vector2(petak - 2.0, petak - 2.0)
			sel.position = Vector2(20.0 + float(kolom) * petak, 22.0 + float(baris) * petak)
			if baris == 1:
				sel.color = Color(0.06, 0.15, 0.2)          # lorong air, gelap
			elif kolom in [2, 5]:
				sel.color = Color(0.2, 0.18, 0.13)          # batu
			else:
				sel.color = Color(0.13, 0.22, 0.21)         # tepian, lebih terang
			kanvas.add_child(sel)

	# Dua balok di lorong, satu di antaranya berlabel butuh dua ikan.
	for data in [[3, false], [6, true]]:
		var balok := ColorRect.new()
		balok.size = Vector2(petak - 8.0, petak - 8.0)
		balok.position = Vector2(23.0 + float(data[0]) * petak, 25.0 + petak)
		balok.color = Color(0.55, 0.45, 0.25) if not data[1] else Color(0.4, 0.33, 0.2)
		kanvas.add_child(balok)

		# Panah ke atas: ke sanalah balok harus didorong, keluar dari lorong.
		var panah := Label.new()
		panah.text = "^"
		panah.position = Vector2(26.0 + float(data[0]) * petak, 2.0)
		panah.add_theme_font_size_override("font_size", 20)
		panah.add_theme_color_override("font_color", WARNA_BISA)
		kanvas.add_child(panah)

	var masuk := Label.new()
	masuk.text = "air"
	masuk.position = Vector2(330.0, 22.0 + petak * 0.2)
	masuk.add_theme_font_size_override("font_size", 13)
	masuk.add_theme_color_override("font_color", Color(0.55, 0.85, 0.98))
	kanvas.add_child(masuk)

	wadah.add_child(kanvas)

	var catatan := Label.new()
	catatan.text = "Petak gelap = lorong air. Petak terang = tepian, kamu bisa berenang di sana tapi air tidak lewat. Dorong balok KELUAR dari lorong."
	catatan.add_theme_font_size_override("font_size", 15)
	catatan.add_theme_color_override("font_color", Color(0.8, 0.88, 0.92))
	catatan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wadah.add_child(catatan)
	return wadah
