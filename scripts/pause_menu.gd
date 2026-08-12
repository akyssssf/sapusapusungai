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

const BRIEFING_SCENE := preload("res://scenes/ui/briefing.tscn")

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title

## Papan instruksi yang sedang menempel di atas menu jeda, kalau ada.
var _papan: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	%ResumeButton.pressed.connect(close)
	%BriefingButton.pressed.connect(_buka_papan)
	%RestartButton.pressed.connect(SceneRouter.restart_chapter)
	%ChapterButton.pressed.connect(SceneRouter.go_to_chapter_select)
	%MenuButton.pressed.connect(SceneRouter.go_to_menu)


## Papan instruksi dibuka sebagai TEMPELAN, bukan lewat pindah scene.
##
## Ini bukan pilihan gaya. Berpindah scene di tengah permainan berarti peta yang
## sedang dimainkan dibuang -- sampahnya, posisi ikannya, skor berjalannya,
## semuanya hilang. Pemain yang cuma lupa tombol dash tidak boleh kehilangan
## rondenya karena membuka bantuan.
func _buka_papan() -> void:
	if _papan != null:
		return
	_papan = BRIEFING_SCENE.instantiate()
	_papan.mandiri = false
	_papan.bab = GameState.current_chapter
	_papan.ditutup.connect(_papan_ditutup)
	add_child(_papan)
	_panel.visible = false


func _papan_ditutup() -> void:
	_papan = null
	# Kembali ke menu jeda, bukan langsung ke permainan: pemain menutup papan
	# untuk berhenti membaca, bukan untuk melompat balik ke air.
	_panel.visible = true
	%ResumeButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Selama papan instruksi terbuka, Esc miliknya -- dia yang menutup dirinya
	# sendiri. Tanpa penjaga ini, satu Esc menutup papan DAN menu jedanya
	# sekaligus, dan pemain terlempar kembali ke permainan tanpa diminta.
	if _papan != null:
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
