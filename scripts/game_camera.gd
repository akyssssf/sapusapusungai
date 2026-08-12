extends Camera2D
## Kamera yang mengikuti ikan pemain. Dua tugas tambahan di luar mengikuti:
##
##   1. MENJAUH pelan-pelan saat ikan membesar. Tanpa ini, ikan level 5 memenuhi
##      layar dan pemain tidak sempat melihat bahaya yang datang.
##   2. BERGETAR saat ada benturan. Getaran kecil ini yang membuat "makan" dan
##      "kena serang" terasa punya bobot, bukan cuma angka yang berubah.

## Zoom di bawah 1.0 berarti kamera menjauh (pandangan makin luas).
@export var zoom_at_level_1: float = 1.3
@export var zoom_at_max_level: float = 1.05
## Kecepatan zoom menyusul nilai targetnya. Sengaja pelan supaya perubahan
## ukuran terasa mulus, bukan menyentak tiap kali naik level.
@export var zoom_response: float = 2.5
## Seberapa cepat getaran mereda, dalam piksel per detik.
@export var shake_decay: float = 42.0

var _target_zoom: float = 1.0
var _shake_strength: float = 0.0


func _ready() -> void:
	_target_zoom = zoom_at_level_1
	zoom = Vector2.ONE * _target_zoom


func _process(delta: float) -> void:
	# Zoom dikejar pelan-pelan, bukan diset langsung.
	var current := zoom.x
	current = lerpf(current, _target_zoom, clampf(zoom_response * delta, 0.0, 1.0))
	zoom = Vector2(current, current)

	if _shake_strength > 0.0:
		_shake_strength = maxf(_shake_strength - shake_decay * delta, 0.0)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	elif not offset.is_zero_approx():
		offset = Vector2.ZERO


## progress: 0.0 (ikan terkecil) sampai 1.0 (ikan terbesar).
func set_size_progress(progress: float) -> void:
	_target_zoom = lerpf(zoom_at_level_1, zoom_at_max_level, clampf(progress, 0.0, 1.0))


## maxf() dipakai supaya guncangan besar tidak tertimpa guncangan kecil yang
## kebetulan terjadi sepersekian detik sesudahnya.
func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
