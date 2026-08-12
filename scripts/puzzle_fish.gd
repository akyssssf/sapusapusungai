extends CharacterBody2D
## Ikan wader untuk Map 3 -- Kali Jeroan Madiun.
##
## Sengaja BUKAN player_fish.gd. Map 3 sudah bukan permainan makan-dimakan, jadi
## ikan di sini tidak punya ukuran, nyawa, pertumbuhan, dash, maupun urusan
## dengan sampah. Kalau script Map 1/2 dipakai ulang di sini, separuh isinya
## jadi kode mati yang tetap harus dibaca dan dipelihara setiap kali ada
## perubahan. Lebih murah menulis 100 baris baru daripada menyeret 350 baris
## yang setengahnya tidak relevan.
##
## Yang tersisa cuma yang benar-benar dibutuhkan puzzle: berenang, berhenti,
## dan menunjukkan dengan jelas ikan mana yang sedang dikendalikan.

signal became_active

@export_group("Gerak")
@export var max_speed: float = 300.0
@export var acceleration: float = 1500.0
## Perlambatan saat tidak ada input. Sengaja lebih besar daripada Map 1: puzzle
## butuh berhenti di titik yang tepat, bukan meluncur melewatinya.
@export var water_drag: float = 1400.0
@export var flip_threshold: float = 8.0
@export var max_tilt_deg: float = 18.0
@export var wiggle_deg: float = 8.0

@export_group("Saat menganggur")
## Kecepatan hanyut ikan yang sedang TIDAK dikendalikan, piksel per detik.
##
## Nol berarti dia benar-benar diam di tempat -- itu perilaku bawaan dan yang
## dipakai prototipe ini. Diberi angka di atas nol, ikan yang ditinggal akan
## pelan-pelan terbawa arus, dan puzzle-nya langsung berubah sifat: menaruh
## ikan pertama jadi punya batas waktu. Itu versi "jendela waktu" dari rancangan
## awal, dan saklarnya sengaja ditaruh di sini supaya bisa dicoba tanpa
## mengubah kode mana pun.
@export var idle_current_drift: float = 0.0
@export var idle_current_direction: Vector2 = Vector2.LEFT

## Nama yang tampil di HUD.
@export var display_name: String = "Wader"
## Warna cincin penanda dan label. Dua ikan harus jelas beda warnanya.
@export var marker_color: Color = Color(0.42, 0.94, 0.62)

var is_active: bool = false

## Kotak air tempat ikan boleh berenang. Diisi map3_manager.
var swim_bounds: Rect2 = Rect2()

## Dorongan arus dari luar, piksel per detik. Diisi map3_manager saat sebuah
## sumbatan dibuka dan air yang tertahan menghambur.
##
## Ditambahkan SESUDAH gerak sendiri dihitung, bukan dicampur ke dalamnya.
## Bedanya terasa: kalau dicampur, ikan yang berenang melawan arus akan pelan
## tapi tetap "menurut". Kalau ditambahkan terpisah, pemain merasakan dirinya
## didorong -- kendalinya utuh, tapi airnya menang. Itu yang benar, karena arus
## di sini memang hukuman atas urutan yang salah, bukan kontrol yang rusak.
var arus: Vector2 = Vector2.ZERO

var _wiggle_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _marker: Line2D = $Marker
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("puzzle_fish")
	_sprite.modulate = marker_color
	_marker.default_color = marker_color
	_refresh_marker()


func _physics_process(delta: float) -> void:
	if is_active:
		var direction := Input.get_vector("swim_left", "swim_right", "swim_up", "swim_down")
		if direction.is_zero_approx():
			velocity = velocity.move_toward(Vector2.ZERO, water_drag * delta)
		else:
			velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	else:
		# Ikan yang ditinggal direm sampai berhenti, lalu (kalau arusnya
		# dinyalakan) hanyut pelan. Direm dulu, bukan langsung dinolkan, supaya
		# pergantian kendali tidak terasa seperti tombol jeda.
		velocity = velocity.move_toward(idle_current_direction.normalized() * idle_current_drift,
			water_drag * delta)

	# Arus deras berlaku untuk KEDUA ikan, yang dikendalikan maupun yang
	# ditinggal. Air tidak memilih siapa yang sedang dipegang pemain.
	var simpan := velocity
	velocity += arus
	move_and_slide()
	# Kecepatan sendiri dikembalikan setelah bergerak, supaya dorongan arus tidak
	# menumpuk jadi percepatan tiap frame. Tanpa ini, ikan yang berdiri diam
	# selama tiga detik akan melesat seperti ditembakkan.
	velocity = simpan

	_keep_inside_bounds()
	_animate(delta)


func set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	_refresh_marker()
	if is_active:
		became_active.emit()


## Cincin penanda hanya muncul di ikan yang sedang dikendalikan, dan yang
## menganggur diredupkan. Dua isyarat sekaligus (ada cincin + lebih terang)
## dipakai supaya tetap terbaca oleh pemain yang sulit membedakan warna.
func _refresh_marker() -> void:
	_marker.visible = is_active
	_sprite.modulate = marker_color if is_active else marker_color.darkened(0.45)
	if is_active:
		var tween := create_tween()
		tween.tween_property(_marker, "scale", Vector2(1.25, 1.25), 0.08)
		tween.tween_property(_marker, "scale", Vector2.ONE, 0.16)


func _keep_inside_bounds() -> void:
	if swim_bounds.size.is_zero_approx():
		return
	var r: float = _collision.shape.radius
	var target_x := clampf(global_position.x, swim_bounds.position.x + r, swim_bounds.end.x - r)
	var target_y := clampf(global_position.y, swim_bounds.position.y + r, swim_bounds.end.y - r)
	if not is_equal_approx(target_x, global_position.x):
		global_position.x = target_x
		velocity.x = 0.0
	if not is_equal_approx(target_y, global_position.y):
		global_position.y = target_y
		velocity.y = 0.0


func _animate(delta: float) -> void:
	# Sprite ikan Kenney menghadap ke KANAN secara bawaan.
	if absf(velocity.x) > flip_threshold:
		_sprite.flip_h = velocity.x < 0.0

	var speed_ratio := clampf(velocity.length() / maxf(max_speed, 1.0), 0.0, 1.0)
	var tilt := clampf(velocity.y / maxf(max_speed, 1.0), -1.0, 1.0) * deg_to_rad(max_tilt_deg)
	if _sprite.flip_h:
		tilt = -tilt
	_sprite.rotation = lerp_angle(_sprite.rotation, tilt, clampf(8.0 * delta, 0.0, 1.0))

	# Liukan badan tetap jalan walau ikan diam, cuma jauh lebih pelan. Ikan yang
	# benar-benar beku terlihat seperti scene yang crash.
	_wiggle_time += delta * (3.0 + 10.0 * speed_ratio)
	_sprite.skew = sin(_wiggle_time) * deg_to_rad(wiggle_deg) * (0.25 + 0.75 * speed_ratio)
