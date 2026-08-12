extends Control
## Menu utama. Tiga panel (Utama / Pengaturan / Kredit) tinggal di satu scene
## dan saling bergantian tampil, bukan tiga scene terpisah.
##
## Alasannya: berpindah scene berarti latar sungainya dimuat ulang dan
## musiknya berisiko tersendat setiap kali pemain membuka pengaturan lalu
## kembali. Untuk panel sekecil ini, mengganti visible jauh lebih murah dan
## perpindahannya terasa seketika -- yang memang seharusnya, karena pemain
## tidak pergi ke mana-mana.

# Panel tidak dipakai sebagai nama enum karena itu nama kelas bawaan Godot.
enum Halaman { UTAMA, PENGATURAN, KREDIT }

@onready var _panels := {
	Halaman.UTAMA: %PanelUtama,
	Halaman.PENGATURAN: %PanelPengaturan,
	Halaman.KREDIT: %PanelKredit,
}

@onready var _continue_button: Button = %ContinueButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _reset_button: Button = %ResetButton
@onready var _total_label: Label = %TotalLabel

## Tombol hapus progres perlu dipencet dua kali. Tanpa konfirmasi, satu salah
## klik menghapus seluruh capaian pemain -- dan itu tidak bisa dibatalkan.
var _reset_armed: bool = false


func _ready() -> void:
	%PlayButton.pressed.connect(SceneRouter.go_to_chapter_select)
	_continue_button.pressed.connect(_on_continue)
	%SettingsButton.pressed.connect(_show_panel.bind(Halaman.PENGATURAN))
	%CreditsButton.pressed.connect(_show_panel.bind(Halaman.KREDIT))
	%QuitButton.pressed.connect(_on_quit)
	%BackFromSettings.pressed.connect(_show_panel.bind(Halaman.UTAMA))
	%BackFromCredits.pressed.connect(_show_panel.bind(Halaman.UTAMA))
	_reset_button.pressed.connect(_on_reset_pressed)

	_music_slider.value = GameState.music_volume
	_sfx_slider.value = GameState.sfx_volume
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	_refresh()
	_show_panel(Halaman.UTAMA)
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 1.6)


func _refresh() -> void:
	# Tombol "Lanjutkan" hanya berguna kalau ada yang bisa dilanjutkan.
	# Disembunyikan, bukan dinonaktifkan: tombol mati yang tidak pernah bisa
	# ditekan cuma menambah kebisingan untuk pemain baru.
	_continue_button.visible = GameState.has_any_progress()
	if _continue_button.visible:
		var index := GameState.next_chapter()
		_continue_button.text = "LANJUTKAN  -  %s" % GameState.chapter_data(index).get("title", "")
	_total_label.text = "Skor terbaik keseluruhan: %d" % GameState.total_best_score()


func _show_panel(which: int) -> void:
	for key in _panels:
		_panels[key].visible = key == which
	_reset_armed = false
	_reset_button.text = "Hapus semua progres"
	if which == Halaman.UTAMA:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _panels[Halaman.UTAMA].visible:
		return
	_show_panel(Halaman.UTAMA)
	get_viewport().set_input_as_handled()


func _on_continue() -> void:
	SceneRouter.go_to_chapter(GameState.next_chapter())


func _on_quit() -> void:
	get_tree().quit()


func _on_music_changed(value: float) -> void:
	GameState.music_volume = value
	AudioManager.apply_volume_settings()
	GameState.save_progress()


func _on_sfx_changed(value: float) -> void:
	GameState.sfx_volume = value
	AudioManager.apply_volume_settings()
	# Contoh bunyi tiap penggeser digerakkan, supaya pemain mendengar akibatnya
	# langsung alih-alih menebak dari angka.
	AudioManager.play("eat_small", 0.0, 1.1)
	GameState.save_progress()


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Yakin? Tekan sekali lagi"
		return
	GameState.reset_progress()
	_reset_armed = false
	_reset_button.text = "Progres sudah dihapus"
	_refresh()
