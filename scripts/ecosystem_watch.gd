extends CanvasLayer
## Pengawas ekosistem Sungai Ciliwung.
##
## Node ini satu-satunya yang mendengarkan hitungan ikan lokal yang termakan,
## dan tugasnya menerjemahkan angka itu jadi sesuatu yang bisa DIRASAKAN, bukan
## dibaca. Tidak ada teks, tidak ada bar, tidak ada angka di layar.
##
## Tiga lapis peringatannya, dari paling halus ke paling jelas:
##
##   1. WARNA AIR  -- selubung gelap kebiruan menebal sedikit demi sedikit.
##      Pada tahap awal hampir tidak terlihat; pemain lebih dulu merasa "kok
##      makin suram ya" daripada tahu kenapa.
##   2. NADA MUSIK -- lagu turun nadanya sedikit, seperti tape yang melambat.
##      Telinga menangkap ini jauh lebih cepat daripada mata menangkap warna.
##   3. DENYUT     -- di ambang terakhir, selubungnya ikut berdenyut pelan.
##      Ini peringatan terakhir sebelum kolaps.
##
## Kenapa serumit ini untuk satu angka? Karena kalau ditampilkan sebagai
## "Ikan lokal termakan: 3/5", pemain akan memperlakukannya sebagai kuota yang
## boleh dihabiskan. Sebagai perubahan suasana, dia jadi firasat -- dan firasat
## itulah yang ingin ditanamkan game ini soal sungai sungguhan.

signal collapsed

## Warna selubung saat ekosistem masih sehat dan saat di ambang kolaps.
@export var calm_tint: Color = Color(0.043, 0.09, 0.153, 0.0)
@export var doomed_tint: Color = Color(0.043, 0.075, 0.204, 0.62)
## Seberapa lambat selubung menyusul nilai targetnya. Sengaja lama: perubahan
## yang menyentak akan terbaca sebagai "kejadian", padahal ini seharusnya
## terasa seperti sesuatu yang merayap.
@export var tint_response: float = 0.9
## Penurunan nada musik saat di ambang kolaps. 0.9 = 10% lebih rendah.
@export var music_pitch_at_doom: float = 0.9
## Denyut mulai terasa setelah tekanan melewati angka ini.
@export var pulse_from: float = 0.65

var _pulse_time: float = 0.0
var _collapsed_sent: bool = false

@onready var _veil: ColorRect = $Veil


func _ready() -> void:
	_veil.color = calm_tint
	GameState.local_fish_eaten_changed.connect(_on_local_fish_eaten)
	# Dipanggil sekali di awal supaya keadaan awal selalu benar, termasuk saat
	# scene dimuat ulang sesudah kalah.
	_on_local_fish_eaten(GameState.local_fish_eaten)


func _process(delta: float) -> void:
	var pressure := GameState.ecosystem_pressure()

	var target := calm_tint.lerp(doomed_tint, pressure)
	if pressure > pulse_from:
		# Denyut hanya menambah kepekatan, tidak pernah menguranginya di bawah
		# nilai dasar -- supaya peringatan tidak pernah terlihat "mereda".
		_pulse_time += delta
		var beat := 0.5 + 0.5 * sin(_pulse_time * 3.4)
		target.a += 0.1 * beat * (pressure - pulse_from) / maxf(1.0 - pulse_from, 0.01)

	_veil.color = _veil.color.lerp(target, clampf(tint_response * delta, 0.0, 1.0))


func _on_local_fish_eaten(count: int) -> void:
	var pressure := GameState.ecosystem_pressure()
	AudioManager.set_music_pitch(lerpf(1.0, music_pitch_at_doom, pressure))

	# Sinyal paling samar pun tetap butuh satu sentuhan yang bisa dikenali,
	# kalau tidak pemain menganggapnya kebetulan. Getaran kamera sekejap saat
	# hitungan bertambah sudah cukup, tanpa memberi tahu apa yang bertambah.
	if count >= GameState.ECOSYSTEM_WARNING_AT and not GameState.is_ecosystem_collapsed():
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.camera != null:
			player.camera.shake(6.0 + 4.0 * pressure)

	if GameState.is_ecosystem_collapsed() and not _collapsed_sent:
		_collapsed_sent = true
		collapsed.emit()
