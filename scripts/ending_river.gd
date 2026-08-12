extends Control
## Layar akhir baik: sungainya mengalir lagi. Masih PLACEHOLDER -- latar biru
## jernih, satu kalimat, dan garis-garis arus yang bergerak. Detail visualnya
## menyusul, tapi nadanya sudah harus benar sejak sekarang: ini kebalikan dari
## layar banjir Map 2, jadi warnanya terang dan geraknya tenang, bukan diam.

@export var input_lock: float = 1.6
## Kecepatan garis arus bergerak ke kanan, piksel per detik.
@export var flow_speed: float = 90.0

var _lock_left: float = 0.0
var _flow_offset: float = 0.0

@onready var _flow_lines: Node2D = %FlowLines
@onready var _hint: Label = %Hint


func _ready() -> void:
	_lock_left = input_lock
	_hint.text = "Skor terbaik keseluruhan %d   -   tekan Enter untuk melanjutkan" % GameState.total_best_score()
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 2.0)


func _process(delta: float) -> void:
	_lock_left = maxf(_lock_left - delta, 0.0)

	# Garis arus digeser terus lalu dibungkus kembali. Layar akhir yang benar
	# benar diam terlihat seperti permainan yang membeku, bukan seperti sungai
	# yang akhirnya jalan.
	_flow_offset = fmod(_flow_offset + flow_speed * delta, 320.0)
	_flow_lines.position.x = _flow_offset


func _unhandled_input(event: InputEvent) -> void:
	if _lock_left > 0.0:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	AudioManager.set_music_pitch(1.0)
	# Layar ini bukan akhir cerita, cuma pemandangannya. Kesimpulannya ada di
	# cutscene penutup -- dan cutscene itu yang mengantar pemain ke menu.
	SceneRouter.play_cutscene(Story.PENUTUP)
