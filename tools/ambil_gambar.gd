extends Node
## Alat pengembangan: mengambil tangkapan layar untuk README, langsung dari
## game yang berjalan. Bukan bagian dari game.
##
##     godot --path . res://tools/ambil_gambar.tscn
##
## Hasilnya ke user:// (lihat README untuk lokasinya), lalu disalin manual ke
## docs/. Harus dijalankan TANPA --headless: perender headless tidak menggambar
## apa pun, jadi gambarnya akan keluar hitam polos.

const SASARAN := [
	["res://scenes/maps/map3_jeroan.tscn", "user://bab3.png", 2.5],
	["res://scenes/maps/map1_brantas.tscn", "user://bab1.png", 8.0],
	["res://scenes/maps/map2_ciliwung.tscn", "user://bab2.png", 8.0],
	["res://scenes/ui/main_menu.tscn", "user://menu.png", 1.5],
]

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame

	for s in SASARAN:
		var scene: Node = load(s[0]).instantiate()
		add_child(scene)
		await get_tree().create_timer(s[2]).timeout
		await RenderingServer.frame_post_draw
		var gambar: Image = get_viewport().get_texture().get_image()
		var err := gambar.save_png(s[1])
		print("%s -> %s (%dx%d) err=%d" % [
			s[0].get_file(), s[1], gambar.get_width(), gambar.get_height(), err])
		scene.queue_free()
		await get_tree().process_frame

	get_tree().quit(0)
