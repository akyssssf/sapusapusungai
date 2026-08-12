extends Control
## Layar pilih bab.
##
## Kartunya TIDAK ditulis satu per satu di scene, melainkan dibangun dari
## GameState.CHAPTERS saat scene dibuka. Menambah Bab 4 nanti cukup menambah
## satu baris di daftar itu -- tidak ada node yang perlu disalin, tidak ada
## indeks yang perlu diperbaiki.
##
## Layar inilah gerbang progres yang sesungguhnya. Bab yang belum terbuka
## bahkan tidak bisa diklik, jadi pemeriksaan di dalam tiap peta tinggal jadi
## jaring pengaman untuk saat scene peta dijalankan langsung dari editor.

const CARD_SIZE := Vector2(360, 300)

@onready var _row: HBoxContainer = %CardRow

var _cards: Array[Button] = []
var _focus: int = 0


func _ready() -> void:
	%BackButton.pressed.connect(SceneRouter.go_to_menu)
	_build_cards()
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 1.2)


func _build_cards() -> void:
	for chapter in GameState.CHAPTERS:
		var index := int(chapter["index"])
		var unlocked := GameState.is_unlocked(index)
		var done := GameState.is_completed(index)

		var card := Button.new()
		card.custom_minimum_size = CARD_SIZE
		card.disabled = not unlocked
		card.focus_mode = Control.FOCUS_ALL
		card.clip_text = false
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.text = _card_text(chapter, unlocked, done)
		card.add_theme_font_size_override("font_size", 19)
		if unlocked:
			card.pressed.connect(SceneRouter.go_to_chapter.bind(index))
		_row.add_child(card)
		_cards.append(card)

	# Fokus awal diletakkan di bab yang belum tamat, bukan selalu Bab 1.
	# Pemain yang kembali ke layar ini hampir selalu ingin melanjutkan.
	_focus = clampi(GameState.next_chapter() - 1, 0, maxi(_cards.size() - 1, 0))
	if not _cards.is_empty() and not _cards[_focus].disabled:
		_cards[_focus].grab_focus()


func _card_text(chapter: Dictionary, unlocked: bool, done: bool) -> String:
	var index := int(chapter["index"])
	var lines := PackedStringArray()
	lines.append(String(chapter["subtitle"]))
	lines.append("")
	lines.append(String(chapter["title"]).to_upper())
	lines.append("")

	if not unlocked:
		lines.append("[ TERKUNCI ]")
		lines.append("")
		lines.append("Selesaikan Bab %d dulu." % (index - 1))
		return "\n".join(lines)

	lines.append(String(chapter["blurb"]))
	lines.append("")
	if done:
		lines.append("SELESAI    skor terbaik %d" % int(GameState.best_scores.get(index, 0)))
	else:
		lines.append("BELUM SELESAI")
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneRouter.go_to_menu()
		get_viewport().set_input_as_handled()
		return

	# Navigasi panah tetap disediakan supaya layar ini bisa dipakai tanpa tetikus
	# -- penting untuk build Windows yang dijalankan juri dengan keyboard saja.
	var step := 0
	if event.is_action_pressed("ui_right"):
		step = 1
	elif event.is_action_pressed("ui_left"):
		step = -1
	if step == 0:
		return

	for i in _cards.size():
		var candidate := wrapi(_focus + step * (i + 1), 0, _cards.size())
		if not _cards[candidate].disabled:
			_focus = candidate
			_cards[candidate].grab_focus()
			AudioManager.play("switch_fish", -6.0, 1.2)
			break
	get_viewport().set_input_as_handled()
