class_name SpriteIkan
extends AnimatedSprite2D
## Sprite ikan beranimasi, dipakai semua ikan di seluruh game.
##
## Aset barunya menyediakan EMPAT set gambar untuk tiap spesies: berenang dan
## makan, masing-masing menghadap kiri dan kanan. Jadi ikan yang berbalik arah
## TIDAK dibalik pakai flip_h -- gambarnya memang digambar terpisah, lengkap
## dengan sirip dan mata di sisi yang benar. Membalik gambar kanan untuk dipakai
## sebagai kiri akan membuang separuh pekerjaan ilustratornya.
##
## Node ini menyembunyikan seluruh urusan itu di balik dua perintah:
##
##     hadap(ke_kiri)   -- ikan berbalik
##     makan()          -- mainkan animasi makan sekali, lalu kembali berenang
##
## Sisanya (rotation, skew, scale, modulate) tetap seperti Sprite2D biasa,
## karena AnimatedSprite2D sama-sama Node2D. Itu sengaja: seluruh kode lama yang
## memiringkan, mengedipkan, dan membesarkan ikan tidak perlu diubah sama sekali.

## Nama folder spesies di dalam "assets/aset gemastik/".
@export var spesies: String = "wader_bintik"
## Kecepatan animasi berenang saat ikan diam. Ikan yang berenang cepat akan
## dipercepat oleh pemanggilnya lewat laju().
@export var fps_renang: float = 10.0
@export var fps_makan: float = 14.0

const JUMLAH_RENANG := 8
const JUMLAH_MAKAN := 6

const RENANG_KANAN := "renang_kanan"
const RENANG_KIRI := "renang_kiri"
const MAKAN_KANAN := "makan_kanan"
const MAKAN_KIRI := "makan_kiri"

## SpriteFrames yang sudah dirakit, dipakai bersama semua ikan sespesies.
##
## Tanpa cache ini, satu peta dengan dua puluh ikan lokal akan memuat 28 tekstur
## dua puluh kali. Godot memang menyimpan tekstur di cache-nya sendiri, tapi
## merakit SpriteFrames-nya tidak -- dan itu bagian yang mahal.
static var _cache: Dictionary = {}

var _ke_kiri: bool = false
var _sedang_makan: bool = false


func _ready() -> void:
	sprite_frames = frames_untuk(spesies)
	animation_finished.connect(_selesai_makan)
	play(RENANG_KANAN)


## Merakit SpriteFrames satu spesies dari berkas-berkasnya.
##
## Nomor bingkainya ditulis langsung (01..08, 01..06), bukan hasil memindai isi
## folder. Memindai folder res:// baru bermasalah setelah game diekspor: berkas
## PNG-nya sudah berubah jadi berkas impor, dan daftar isinya tidak lagi sama
## dengan yang terlihat di komputer pengembang. Nomor yang ditulis langsung
## berperilaku sama di editor maupun di build jadi.
static func frames_untuk(nama_spesies: String) -> SpriteFrames:
	if _cache.has(nama_spesies):
		return _cache[nama_spesies]

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	_isi(frames, nama_spesies, RENANG_KANAN, "swim_right", JUMLAH_RENANG, true)
	_isi(frames, nama_spesies, RENANG_KIRI, "swim_left", JUMLAH_RENANG, true)
	_isi(frames, nama_spesies, MAKAN_KANAN, "eat_right", JUMLAH_MAKAN, false)
	_isi(frames, nama_spesies, MAKAN_KIRI, "eat_left", JUMLAH_MAKAN, false)

	_cache[nama_spesies] = frames
	return frames


static func _isi(frames: SpriteFrames, nama_spesies: String, animasi: String,
		folder: String, jumlah: int, berulang: bool) -> void:
	frames.add_animation(animasi)
	frames.set_animation_loop(animasi, berulang)
	for i in range(1, jumlah + 1):
		var alamat := "res://assets/aset gemastik/%s/%s/%s_%02d.png" % [
			nama_spesies, folder, folder, i
		]
		var tekstur: Texture2D = load(alamat)
		if tekstur == null:
			push_warning("SpriteIkan: bingkai hilang -> %s" % alamat)
			continue
		frames.add_frame(animasi, tekstur)


## Mengganti spesies sesudah node ini hidup.
##
## Dipakai ikan lokal Bab 2, yang spesiesnya diundi tiap kali lahir. Tidak bisa
## lewat properti "spesies" saja: _ready() milik node anak berjalan SEBELUM
## induknya, jadi pengundian di induk selalu terlambat satu langkah.
func ganti_spesies(nama: String) -> void:
	if nama == spesies and sprite_frames != null:
		return
	spesies = nama
	sprite_frames = frames_untuk(nama)
	_pasang_animasi()


## Menghadapkan ikan. Aman dipanggil tiap frame -- kalau arahnya tidak berubah,
## animasinya tidak di-restart (kalau di-restart, ikannya akan terlihat
## tersendat-sendat karena selalu kembali ke bingkai pertama).
func hadap(ke_kiri: bool) -> void:
	if _ke_kiri == ke_kiri:
		return
	_ke_kiri = ke_kiri
	_pasang_animasi()


## Animasi makan sekali jalan, lalu kembali berenang sendiri.
func makan() -> void:
	_sedang_makan = true
	_pasang_animasi()


## Menyesuaikan kecepatan animasi dengan kecepatan renang, 0.0 sampai 1.0.
## Ikan yang meluncur cepat tapi siripnya bergerak sepelan ikan diam terlihat
## seperti gambar yang digeser, bukan seperti ikan yang berenang.
func laju(rasio: float) -> void:
	if _sedang_makan:
		speed_scale = 1.0
		return
	speed_scale = lerpf(0.55, 1.9, clampf(rasio, 0.0, 1.0))


## Dipakai kode lama yang dulu membaca flip_h untuk tahu arah hadap ikan.
func menghadap_kiri() -> bool:
	return _ke_kiri


func _pasang_animasi() -> void:
	var nama := ""
	if _sedang_makan:
		nama = MAKAN_KIRI if _ke_kiri else MAKAN_KANAN
	else:
		nama = RENANG_KIRI if _ke_kiri else RENANG_KANAN
	if animation != nama:
		play(nama)


func _selesai_makan() -> void:
	if not _sedang_makan:
		return
	_sedang_makan = false
	_pasang_animasi()
