extends CanvasLayer
## Menu jeda, dipasang di ketiga peta.
##
## Dua hal yang gampang salah pada menu jeda di Godot, dan keduanya diurus di
## sini:
##
##   1. process_mode HARUS PROCESS_MODE_ALWAYS, bukan WHEN_PAUSED.
##      Ini jebakan yang halus. WHEN_PAUSED terdengar paling tepat -- "menu jeda
##      ya jalan saat dijeda" -- tapi artinya node ini TIDAK memproses input
##      selama permainan berjalan normal, sehingga tombol Esc untuk MEMBUKA
##      menunya tidak akan pernah terbaca. Node ini harus hidup di kedua
##      keadaan: saat normal untuk menangkap Esc, saat dijeda supaya tombolnya
##      bisa ditekan.
##   2. Jeda harus DILEPAS sebelum berpindah scene. Kalau lupa, scene berikutnya
##      lahir dalam keadaan beku. SceneRouter sudah mengurusnya, tapi tombol
##      "lanjutkan" di sini tetap wajib melepasnya sendiri.

## Dimatikan wasit peta begitu permainan berakhir. Tanpa ini, pemain bisa
## membuka menu jeda di atas layar hasil dan menekan "lanjutkan" -- kembali ke
## permainan yang sebenarnya sudah selesai, dengan ikan yang sudah dibekukan.
var enabled: bool = true

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	%ResumeButton.pressed.connect(close)
	%RestartButton.pressed.connect(SceneRouter.restart_chapter)
	%ChapterButton.pressed.connect(SceneRouter.go_to_chapter_select)
	%MenuButton.pressed.connect(SceneRouter.go_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not enabled and not _panel.visible:
		return
	get_viewport().set_input_as_handled()
	if _panel.visible:
		close()
	else:
		open()


func open() -> void:
	var data := GameState.chapter_data(GameState.current_chapter)
	_title.text = String(data.get("title", "JEDA")).to_upper()
	_panel.visible = true
	get_tree().paused = true
	%ResumeButton.grab_focus()
	AudioManager.play("switch_fish", -4.0, 0.85)


func close() -> void:
	_panel.visible = false
	get_tree().paused = false
	AudioManager.play("switch_fish", -4.0, 1.15)
