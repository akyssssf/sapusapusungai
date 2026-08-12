extends Node2D
## Berkas cahaya matahari yang menembus permukaan air.
##
## Isinya cuma beberapa jajar genjang tipis, tapi karena bergeser dan
## meredup-menyala pelan, otak penonton membacanya sebagai permukaan air yang
## beriak di atas sana. Ini trik latar termurah dengan hasil paling besar:
## tidak ada tekstur, tidak ada shader, tidak ada beban ke GPU ponsel.

## Sejauh mana seluruh berkas bergeser ke kiri-kanan, dalam piksel.
@export var drift_px: float = 70.0
## Siklus penuh geseran per detik. Harus sangat pelan supaya tidak mengganggu.
@export var drift_speed: float = 0.06
@export var pulse_speed: float = 0.11
## Batas bawah dan atas terang berkas cahaya.
@export var alpha_range: Vector2 = Vector2(0.45, 1.0)

var _time: float = 0.0
var _base_x: float = 0.0


func _ready() -> void:
	_base_x = position.x
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta
	position.x = _base_x + sin(_time * drift_speed * TAU) * drift_px
	# 0.5 + 0.5 * sin() memetakan gelombang ke rentang 0..1 dulu, baru
	# dipetakan lagi ke alpha_range lewat lerpf().
	var wave := 0.5 + 0.5 * sin(_time * pulse_speed * TAU)
	modulate.a = lerpf(alpha_range.x, alpha_range.y, wave)
