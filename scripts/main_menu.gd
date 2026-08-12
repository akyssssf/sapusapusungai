extends Control
## Menu utama. Empat panel (Nama / Utama / Pengaturan / Kredit) tinggal di satu
## scene dan saling bergantian tampil, bukan empat scene terpisah.
##
## Alasannya: berpindah scene berarti latar sungainya dimuat ulang dan
## musiknya berisiko tersendat setiap kali pemain membuka pengaturan lalu
## kembali. Untuk panel sekecil ini, mengganti visible jauh lebih murah dan
## perpindahannya terasa seketika -- yang memang seharusnya, karena pemain
## tidak pergi ke mana-mana.

# Panel tidak dipakai sebagai nama enum karena itu nama kelas bawaan Godot.
enum Halaman { NAMA, UTAMA, PENGATURAN, KREDIT }

@onready var _panels := {
	Halaman.NAMA: %PanelNama,
	Halaman.UTAMA: %PanelUtama,
	Halaman.PENGATURAN: %PanelPengaturan,
	Halaman.KREDIT: %PanelKredit,
}

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _reset_button: Button = %ResetButton
@onready var _total_label: Label = %TotalLabel
@onready var _sapaan: Label = %Sapaan
@onready var _name_edit: LineEdit = %NameEdit
@onready var _name_hint: Label = %NameHint
@onready var _settings_name: LineEdit = %SettingsNameEdit

## Tombol hapus progres perlu dipencet dua kali. Tanpa konfirmasi, satu salah
## klik menghapus seluruh capaian pemain -- dan itu tidak bisa dibatalkan.
var _reset_armed: bool = false
## Begitu juga MULAI BARU, dan justru lebih berbahaya: tombolnya ada di menu
## utama, tepat di bawah LANJUTKAN yang bentuknya sama persis.
var _new_game_armed: bool = false


func _ready() -> void:
	%PlayButton.pressed.connect(SceneRouter.go_to_chapter_select)
	_continue_button.pressed.connect(_on_continue)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	%SettingsButton.pressed.connect(_show_panel.bind(Halaman.PENGATURAN))
	%CreditsButton.pressed.connect(_show_panel.bind(Halaman.KREDIT))
	%QuitButton.pressed.connect(_on_quit)
	%BackFromSettings.pressed.connect(_show_panel.bind(Halaman.UTAMA))
	%BackFromCredits.pressed.connect(_show_panel.bind(Halaman.UTAMA))
	_reset_button.pressed.connect(_on_reset_pressed)

	%NameOkButton.pressed.connect(_on_name_submitted)
	# Enter di dalam kotak juga mengirim. Mengetik nama lalu harus memindahkan
	# tangan ke tetikus untuk satu klik adalah gangguan kecil yang terasa besar,
	# karena ini interaksi PERTAMA pemain dengan game ini.
	_name_edit.text_submitted.connect(func(_t: String) -> void: _on_name_submitted())

	_settings_name.text_changed.connect(_on_settings_name_changed)
	_settings_name.text = GameState.player_name

	_music_slider.value = GameState.music_volume
	_sfx_slider.value = GameState.sfx_volume
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	_refresh()
	# Pemain yang belum pernah menyebut namanya disambut kotak nama, bukan menu.
	# Menu penuh berisi enam tombol untuk orang yang belum tahu ini game apa
	# adalah pilihan yang buruk; satu pertanyaan jauh lebih mudah dijawab.
	_show_panel(Halaman.NAMA if not GameState.has_player_name() else Halaman.UTAMA)
	AudioManager.play_music(AudioManager.MUSIC_RIVER, 1.6)


func _refresh() -> void:
	# Tombol "Lanjutkan" hanya berguna kalau ada yang bisa dilanjutkan.
	# Disembunyikan, bukan dinonaktifkan: tombol mati yang tidak pernah bisa
	# ditekan cuma menambah kebisingan untuk pemain baru.
	_continue_button.visible = GameState.has_any_progress()
	if _continue_button.visible:
		var index := GameState.next_chapter()
		_continue_button.text = "LANJUTKAN  -  %s" % GameState.chapter_data(index).get("title", "")
	# MULAI BARU juga disembunyikan untuk pemain baru: buat mereka, "PILIH BAB"
	# sudah berarti mulai baru, dan dua tombol yang artinya sama cuma bikin ragu.
	_new_game_button.visible = GameState.has_any_progress()
	_new_game_button.text = "MULAI BARU"

	if GameState.has_player_name():
		_sapaan.text = "Hai, %s!" % GameState.display_name()
	else:
		_sapaan.text = ""

	_total_label.text = "Skor terbaik keseluruhan: %d" % GameState.total_best_score()


func _show_panel(which: int) -> void:
	for key in _panels:
		_panels[key].visible = key == which
	_reset_armed = false
	_reset_button.text = "Hapus semua progres"
	_new_game_armed = false
	if which == Halaman.UTAMA:
		_refresh()
	elif which == Halaman.NAMA:
		_name_edit.text = GameState.player_name
		_name_edit.grab_focus()
	elif which == Halaman.PENGATURAN:
		_settings_name.text = GameState.player_name
	# Sapaan hanya pantas di menu utama. Di layar lain dia cuma menumpuk teks
	# di atas judul panel yang sedang dibaca.
	_sapaan.visible = which == Halaman.UTAMA


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Esc di kotak nama tidak membawa ke mana-mana: belum ada menu untuk dituju,
	# dan pemain baru yang terlempar ke layar kosong akan mengira game-nya rusak.
	if _panels[Halaman.UTAMA].visible or _panels[Halaman.NAMA].visible:
		return
	_show_panel(Halaman.UTAMA)
	get_viewport().set_input_as_handled()


# --- Nama pemain ------------------------------------------------------------

func _on_name_submitted() -> void:
	var nama := _name_edit.text.strip_edges()
	if nama.is_empty():
		_name_hint.text = "Isi dulu namanya ya  -  satu huruf pun boleh"
		_name_hint.add_theme_color_override("font_color", Color(1, 0.62, 0.55))
		_name_edit.grab_focus()
		return
	GameState.set_player_name(nama)
	AudioManager.play("level_up", 0.0, 1.0)
	_show_panel(Halaman.UTAMA)


func _on_settings_name_changed(nilai: String) -> void:
	# Nama kosong di Pengaturan sengaja TIDAK ditolak mentah-mentah: pemain yang
	# sedang menghapus untuk mengetik ulang akan melewati keadaan kosong, dan
	# memarahinya di tengah pengetikan itu menyebalkan. Yang kosong cuma tidak
	# disimpan.
	if nilai.strip_edges().is_empty():
		return
	GameState.set_player_name(nilai)


# --- Tombol menu ------------------------------------------------------------

func _on_continue() -> void:
	SceneRouter.go_to_chapter(GameState.next_chapter())


## MULAI BARU: progres dihapus, cerita diputar ulang dari awal, lalu langsung
## masuk Bab 1 -- bukan dilempar ke layar pilih bab. Pemain yang menekan "mulai
## baru" sudah menyatakan mau main, bukan mau memilih.
func _on_new_game_pressed() -> void:
	if not _new_game_armed:
		_new_game_armed = true
		_new_game_button.text = "HAPUS PROGRES & MULAI DARI AWAL?"
		return
	GameState.new_game()
	SceneRouter.go_to_chapter(1)


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
