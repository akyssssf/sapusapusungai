extends Area2D
## Batang bambu hanyut yang melesat menyeberangi sungai.
##
## Beda mendasar dari sampah biasa: benda ini TIDAK PERNAH bisa dimakan,
## sebesar apa pun ikannya. Satu-satunya jawaban adalah menyingkir dari
## jalurnya. Itu yang membuatnya jadi ancaman yang tetap berarti sampai akhir
## permainan, saat semua sampah lain sudah berubah jadi santapan.
##
## Bambu juga bukan pilihan acak: sumbatan bambu (brambongan) adalah biang
## banjir di Map 3, jadi pemain sudah berkenalan dengannya sejak Map 1.
##
## Yang membuatnya adil adalah aba-abanya. Benda ini bergerak jauh lebih cepat
## daripada ikan, jadi kalau muncul tanpa peringatan, satu-satunya cara selamat
## adalah hafal -- dan itu bukan tantangan, itu jebakan. Peringatan di tepi
## layar dimunculkan director SEBELUM batangnya lahir; lihat trash_director.gd.

## +1 = melesat ke kanan (masuk dari tepi kiri), -1 = sebaliknya.
@export var direction: int = -1
@export var speed: float = 780.0
## Kemiringan tetap saat lahir, dalam derajat. Diputar pada NODE INDUK, bukan
## pada Visual, supaya bentuk tabrakannya ikut miring. Kalau cuma gambarnya yang
## dimiringkan, pemain melihat batang serong tapi yang menabraknya kotak
## mendatar -- dan tabrakan yang tidak sesuai gambar selalu terasa curang.
@export var tilt_deg: float = 5.0
## Dibuang setelah sejauh ini melewati tepi peta.
@export var despawn_margin: float = 260.0

var world_width: float = 2048.0

var _hit_player: bool = false

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("rush_hazard")
	# Menghadap arah lesatannya, plus sedikit miring supaya terlihat terseret.
	_visual.scale.x = float(direction)
	rotation = deg_to_rad(randf_range(-tilt_deg, tilt_deg))
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Lurus mendatar, tanpa berguling. Benda yang melesat 2x lebih cepat daripada
	# pemain harus benar-benar bisa diperkirakan lintasannya; kalau tidak,
	# aba-aba di tepi layar kehilangan gunanya.
	position.x += direction * speed * delta

	if position.x < -despawn_margin or position.x > world_width + despawn_margin:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit_player or not body.is_in_group("player"):
		return
	# Tidak ada pemeriksaan ukuran sama sekali. Batang bambu bukan makanan.
	_hit_player = true
	body.take_damage(1, global_position)
	AudioManager.play("hurt", -1.0, 0.85)

	# Flag di atas cukup untuk menahan pukulan ganda; benda ini sengaja TIDAK
	# dihapus supaya tetap terlihat melesat pergi seperti seharusnya.
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(1.7, 0.75, 0.7), 0.06)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.3)
