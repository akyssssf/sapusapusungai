extends Node
## Autoload: satu-satunya pintu untuk membunyikan apa pun.
##
## Kenapa lewat satu tempat, bukan menaruh AudioStreamPlayer di tiap entitas?
##   1. Sampah yang dimakan langsung di-queue_free(). Kalau pemutarnya menempel
##      di sampah itu, suaranya ikut mati di tengah jalan.
##   2. Volume dan peredaman global cukup diatur di satu file.
##   3. Kumpulan pemutar (voice pool) bisa dipakai bergantian, jadi sepuluh
##      sampah yang dimakan beruntun tidak membuat sepuluh node baru.
##
## Cara pakai dari mana saja:
##     AudioManager.play("eat_small")
##     AudioManager.play("eat_big", -2.0, 1.15)
##     AudioManager.play_music(AudioManager.MUSIC_BOSS)

## Semua efek suara dimuat sekali saat game mulai. preload() berarti berkasnya
## sudah siap di memori sebelum dipakai -- tidak ada jeda saat pertama berbunyi.
const SFX := {
	"eat_small": preload("res://assets/audio/sfx/eat_small.wav"),
	"eat_big": preload("res://assets/audio/sfx/eat_big.wav"),
	"hurt": preload("res://assets/audio/sfx/hurt.wav"),
	"dash": preload("res://assets/audio/sfx/dash.wav"),
	"level_up": preload("res://assets/audio/sfx/level_up.wav"),
	"warning": preload("res://assets/audio/sfx/warning.wav"),
	"rush": preload("res://assets/audio/sfx/rush.wav"),
	"boss_appear": preload("res://assets/audio/sfx/boss_appear.wav"),
	"boss_suck": preload("res://assets/audio/sfx/boss_suck.wav"),
	"boss_hit": preload("res://assets/audio/sfx/boss_hit.wav"),
	"boss_spit": preload("res://assets/audio/sfx/boss_spit.wav"),
	"boss_defeated": preload("res://assets/audio/sfx/boss_defeated.wav"),
	"win": preload("res://assets/audio/sfx/win.wav"),
	"lose": preload("res://assets/audio/sfx/lose.wav"),
	"spit_out": preload("res://assets/audio/sfx/spit_out.wav"),
	"link_tick": preload("res://assets/audio/sfx/link_tick.wav"),
	"switch_fish": preload("res://assets/audio/sfx/switch_fish.wav"),
	"bamboo_break": preload("res://assets/audio/sfx/bamboo_break.wav"),
	"river_flows": preload("res://assets/audio/sfx/river_flows.wav"),
}

const MUSIC_RIVER := preload("res://assets/audio/music/brantas_ambience.wav")
const MUSIC_BOSS := preload("res://assets/audio/music/boss_theme.wav")
const MUSIC_CILIWUNG := preload("res://assets/audio/music/ciliwung_ambience.wav")

## Banyaknya suara yang boleh berbunyi bersamaan. 14 sudah lebih dari cukup;
## kalau kurang, suara paling lama yang dipotong.
const VOICE_COUNT := 14

## Peredam dasar, dalam desibel. Angka ini adalah volume saat penggeser di
## menu pengaturan berada di posisi paling kanan; penggeser hanya menurunkannya.
@export var sfx_base_db: float = -4.0
@export var music_base_db: float = -13.0

var sfx_volume_db: float = -4.0
var music_volume_db: float = -13.0

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _music_tween: Tween
var _pitch_tween: Tween


func _ready() -> void:
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)

	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(_on_music_finished)

	# Musik harus terus jalan saat permainan dijeda. Tanpa baris ini, membuka
	# menu jeda membuat lagunya ikut berhenti dan suasananya putus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	apply_volume_settings()


## Menerjemahkan penggeser 0..1 di menu pengaturan jadi desibel.
##
## Pemetaannya TIDAK lurus. Telinga manusia mendengar kenyaringan secara
## logaritmik: setengah penggeser terasa seperti setengah keras hanya kalau
## dihitung lewat linear_to_db. Kalau dipetakan lurus, seluruh perubahan yang
## terasa menumpuk di ujung kanan penggeser dan sisanya terdengar sama saja.
func apply_volume_settings() -> void:
	music_volume_db = music_base_db + _slider_to_db(GameState.music_volume)
	sfx_volume_db = sfx_base_db + _slider_to_db(GameState.sfx_volume)
	if _music.playing and (_music_tween == null or not _music_tween.is_running()):
		_music.volume_db = music_volume_db


func _slider_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(clampf(value, 0.0, 1.0))


## volume_db menambah/mengurangi dari sfx_volume_db.
## pitch_jitter mengacak nada sedikit tiap kali dibunyikan. Ini penting: bunyi
## yang persis sama diulang cepat-cepat terdengar seperti mesin rusak, sedangkan
## variasi kecil membuatnya terdengar organik.
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.06) -> void:
	if not SFX.has(sound):
		push_warning("AudioManager: suara '%s' tidak ada." % sound)
		return

	var voice := _take_voice()
	voice.stream = SFX[sound]
	voice.volume_db = sfx_volume_db + volume_db
	voice.pitch_scale = maxf(pitch + randf_range(-pitch_jitter, pitch_jitter), 0.05)
	voice.play()


## Mencari pemutar yang sedang menganggur. Kalau semuanya sibuk, pakai giliran
## berikutnya -- lebih baik memotong satu suara lama daripada menelan yang baru.
func _take_voice() -> AudioStreamPlayer:
	for voice in _voices:
		if not voice.playing:
			return voice
	_next_voice = (_next_voice + 1) % _voices.size()
	return _voices[_next_voice]


## Ganti musik dengan silang-redam. Kalau lagunya sudah yang itu, tidak
## diulang dari awal -- supaya ganti map tidak memotong lagu yang sama.
func play_music(stream: AudioStream, fade: float = 1.2) -> void:
	if _music.stream == stream and _music.playing:
		return

	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()

	if not _music.playing:
		_start_music(stream, fade)
		return

	# Redupkan dulu lagu lama, baru tukar.
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -60.0, fade * 0.5)
	_music_tween.tween_callback(_start_music.bind(stream, fade * 0.5))


func _start_music(stream: AudioStream, fade: float) -> void:
	_music.stream = stream
	# Lagu baru selalu mulai dari nada normal; kalau tidak, pergeseran nada dari
	# ronde sebelumnya ikut terbawa ke map berikutnya.
	if _pitch_tween != null and _pitch_tween.is_running():
		_pitch_tween.kill()
	_music.pitch_scale = 1.0
	_music.volume_db = -60.0
	_music.play()
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", music_volume_db, maxf(fade, 0.05))


## Menggeser nada musik yang sedang berjalan.
##
## Dipakai ecosystem_watch.gd sebagai peringatan samar: makin dekat ekosistem
## ke titik kolaps, makin turun nadanya, seperti tape yang melambat. Telinga
## menangkap perubahan sekecil 5% jauh lebih cepat daripada mata menangkap
## perubahan warna, jadi inilah lapisan peringatan yang paling dulu terasa
## walaupun paling sulit ditunjuk pemain.
##
## Digeser bertahap, bukan langsung, supaya tidak terdengar seperti kerusakan.
func set_music_pitch(pitch: float) -> void:
	var target := maxf(pitch, 0.05)
	if is_equal_approx(_music.pitch_scale, target):
		return
	if _pitch_tween != null and _pitch_tween.is_running():
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_property(_music, "pitch_scale", target, 1.5)


func stop_music(fade: float = 1.0) -> void:
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -60.0, fade)
	_music_tween.tween_callback(_music.stop)


## Tween yang masih berjalan saat aplikasi ditutup membuat Godot melaporkan
## objek "bocor" di konsol. Dimatikan di sini supaya log keluar bersih -- bukan
## kebocoran sungguhan, tapi log bersih memudahkan menemukan masalah asli.
func _exit_tree() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if _pitch_tween != null and _pitch_tween.is_valid():
		_pitch_tween.kill()
	_music.stop()
	for voice in _voices:
		voice.stop()


## Pengaman: file WAV di-loop lewat pengaturan impor, tapi kalau suatu saat
## pengaturan itu hilang, lagunya tetap disambung sendiri di sini.
func _on_music_finished() -> void:
	if _music.stream != null:
		_music.play()
