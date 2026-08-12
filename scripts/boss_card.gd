extends CanvasLayer
## Kartu bos: cara melawan Induk Sapu-Sapu, ditampilkan tepat sebelum dia masuk.
##
## Sebelum ini seluruh pertarungan bos cuma diumumkan satu banner selama 3,6
## detik: "INDUK SAPU-SAPU! Gigit insangnya saat menyala." Itu terlalu sedikit
## untuk pertarungan yang punya tiga pola serangan dengan tiga jawaban berbeda,
## dan terlalu cepat untuk dibaca pemain yang baru saja menghabiskan sungai.
##
## Akibatnya bisa ditebak: pemain menabrak bos dari segala arah, kehilangan
## ketiga nyawanya, dan menyimpulkan bosnya tidak adil -- padahal aturannya
## memang tidak pernah sempat diberitahukan.
##
## Kartu ini MENJEDA permainan. Itu disengaja. Bos butuh 1,8 detik untuk
## berenang masuk, dan di detik-detik itu tidak ada yang bisa dilakukan pemain
## selain menunggu; mengisinya dengan aturan pertarungan jauh lebih baik
## daripada membiarkannya kosong lalu menghukum pemain karena tidak tahu.

## Menutup sendiri kalau pemain tidak menekan apa pun. Pemain yang sudah hafal
## tidak perlu menekan apa-apa; yang belum, punya waktu membaca.
@export var tutup_otomatis: float = 9.0
## Jeda sebelum tombol diterima, supaya tombol yang masih tertekan dari
## permainan barusan tidak langsung menutup kartunya.
@export var kunci_input: float = 0.4

var _sisa: float = 0.0
var _lock: float = 0.0
var _sudah_tutup: bool = false

@onready var _kotak: Control = %Kotak
@onready var _isi: VBoxContainer = %Isi
@onready var _hitung: Label = %Hitung


func _ready() -> void:
	layer = 24
	# Harus tetap diproses saat pohon dijeda; kartu inilah yang menjedanya.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sisa = tutup_otomatis
	_lock = kunci_input
	_susun()

	get_tree().paused = true
	_kotak.scale = Vector2(0.94, 0.94)
	_kotak.modulate.a = 0.0
	var masuk := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	masuk.tween_property(_kotak, "scale", Vector2.ONE, 0.35)
	masuk.parallel().tween_property(_kotak, "modulate:a", 1.0, 0.25)
	AudioManager.play("boss_appear", 1.0, 1.0, 0.0)


func _susun() -> void:
	# Siluet dibungkus CenterContainer: di dalam VBoxContainer, Control yang
	# menggambar di koordinat tetap akan menempel ke kiri kalau tidak dipusatkan.
	var tengah := CenterContainer.new()
	tengah.add_child(BriefingVisual.siluet_bos(320.0))
	_isi.add_child(tengah)
	_isi.add_child(_pisah(6.0))

	var aturan := Label.new()
	aturan.text = "Menabraknya dari mana pun PERCUMA -- pelatnya keras.\nInsangnya cuma terbuka sesaat sesudah dia kehabisan tenaga."
	aturan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aturan.add_theme_font_size_override("font_size", 17)
	aturan.add_theme_color_override("font_color", Color(0.88, 0.94, 0.97))
	_isi.add_child(aturan)
	_isi.add_child(_pisah(10.0))

	var judul := Label.new()
	judul.text = "TIGA SERANGANNYA, DAN JAWABANNYA"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 15)
	judul.add_theme_color_override("font_color", Color(1, 0.82, 0.45))
	_isi.add_child(judul)

	var baris := HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 20)
	for data in [
		["sedot", "MENYEDOT", "berenang menjauh"],
		["terjang", "MENYERUDUK", "KELUAR dari jalur merah,\nbukan lari lurus ke depan"],
		["hujan", "MENYEMBUR", "terus bergerak,\nmenyelip di antara celah"],
	]:
		baris.add_child(_kolom_serangan(String(data[0]), String(data[1]), String(data[2])))
	_isi.add_child(baris)


func _kolom_serangan(jenis: String, nama: String, jawaban: String) -> Control:
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = nama
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1, 0.62, 0.55))
	kolom.add_child(label)

	kolom.add_child(BriefingVisual.diagram_serangan(jenis))

	var arti := Label.new()
	arti.text = jawaban
	arti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arti.custom_minimum_size.x = 180.0
	arti.add_theme_font_size_override("font_size", 14)
	arti.add_theme_color_override("font_color", Color(0.62, 0.93, 0.75))
	arti.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kolom.add_child(arti)
	return kolom


func _pisah(tinggi: float) -> Control:
	var kosong := Control.new()
	kosong.custom_minimum_size.y = tinggi
	return kosong


func _process(delta: float) -> void:
	_lock = maxf(_lock - delta, 0.0)
	_sisa = maxf(_sisa - delta, 0.0)
	_hitung.text = "Enter / klik  mulai bertarung          (mulai sendiri dalam %d)" % int(ceil(_sisa))
	if _sisa <= 0.0:
		_tutup()


func _unhandled_input(event: InputEvent) -> void:
	if _lock > 0.0 or _sudah_tutup:
		return
	var tekan := event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
	if event is InputEventMouseButton and event.pressed:
		tekan = true
	if not tekan:
		return
	get_viewport().set_input_as_handled()
	_tutup()


func _tutup() -> void:
	if _sudah_tutup:
		return
	_sudah_tutup = true
	# Jeda dilepas SEBELUM kartunya hilang, supaya bos sudah mulai berenang masuk
	# saat kartunya memudar -- pertarungannya terasa langsung dimulai.
	get_tree().paused = false
	var keluar := create_tween()
	keluar.tween_property(_kotak, "modulate:a", 0.0, 0.22)
	keluar.tween_callback(queue_free)
