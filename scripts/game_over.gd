extends Control
## Layar akhir permainan. Untuk sekarang masih PLACEHOLDER: latar biru penuh
## dan satu kalimat. Isinya sengaja dibuat dari data GameState, bukan ditulis
## mati di scene, supaya nanti tinggal mengganti tampilannya tanpa menyentuh
## logika mana pun.
##
## Ending banjir tidak memakai kata "kalah". Pemain memang menyelesaikan
## tugasnya membersihkan sampah -- yang runtuh justru hal yang tidak pernah
## disebut di layar mana pun. Itu inti pesannya: sungai bisa terlihat bersih
## dan tetap mati.

## Jeda sebelum tombol diterima, supaya kalimatnya sempat terbaca dan pemain
## yang sedang menekan Spasi untuk dash tidak langsung melewati layar ini.
@export var input_lock: float = 1.4

var _lock_left: float = 0.0

@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _hint: Label = %Hint
@onready var _flood: ColorRect = %Flood


func _ready() -> void:
	_lock_left = input_lock

	match GameState.last_ending:
		GameState.Ending.BANJIR:
			_title.text = "EKOSISTEM KOLAPS"
			_body.text = "Sungai memang terlihat bersih.\nTapi ikan-ikan penghuninya sudah tidak ada,\ndan tidak ada lagi yang menahan air."
		GameState.Ending.NYAWA_HABIS:
			_title.text = "IKAN WADER KALAH"
			_body.text = "Sungainya menang kali ini."
		_:
			_title.text = "PERMAINAN BERAKHIR"
			_body.text = ""

	_hint.text = "Skor %d   -   Enter mengulang bab   -   Esc pilih bab" % GameState.score

	# Air naik memenuhi layar. Untuk sekarang cuma satu ColorRect yang tumbuh
	# dari bawah; detail visual banjirnya menyusul.
	_flood.anchor_top = 1.0
	var tween := create_tween()
	tween.tween_property(_flood, "anchor_top", 0.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	AudioManager.stop_music(1.2)
	AudioManager.play("lose", 2.0, 0.85, 0.0)


func _process(delta: float) -> void:
	_lock_left = maxf(_lock_left - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _lock_left > 0.0:
		return
	# Nada musik dikembalikan normal sebelum pindah. Kalau tidak, ronde
	# berikutnya dimulai dengan lagu yang masih melambat -- sisa dari kegagalan
	# yang sudah selesai.
	if event.is_action_pressed("ui_accept"):
		AudioManager.set_music_pitch(1.0)
		SceneRouter.restart_chapter()
	elif event.is_action_pressed("ui_cancel"):
		AudioManager.set_music_pitch(1.0)
		SceneRouter.go_to_chapter_select()
