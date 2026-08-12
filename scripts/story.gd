class_name Story
extends RefCounted
## Naskah cerita dan isi papan instruksi. DATA saja, tidak ada logika.
##
## Kenapa dijadikan satu berkas, bukan ditulis di scene masing-masing:
## naskah adalah bagian yang paling sering diubah dalam sebuah game, dan yang
## paling sering diubah harus jadi yang paling gampang ditemukan. Kalau
## kalimatnya tersebar di tujuh scene, mengganti satu istilah berarti membuka
## tujuh berkas dan berdoa tidak ada yang terlewat.
##
## Semua kalimat memakai "{nama}" sebagai penanda nama pemain. Cutscene yang
## menggantinya, bukan penulis naskah -- jadi menambah kalimat baru tidak perlu
## ingat memanggil format() sendiri.

# --- Adegan cutscene --------------------------------------------------------
#
# Tiap panel dirakit dari parameter, bukan dari gambar jadi. Alasannya jujur:
# proyek ini belum punya ilustrator, dan panel yang dirakit dari warna air,
# jumlah ikan, dan kepadatan sampah tetap bisa membedakan "sungai mati" dari
# "sungai hidup" tanpa satu pun berkas gambar baru.
#
#   air_atas / air_bawah : gradasi air, sekaligus penentu suasana panel
#   ikan                 : berapa ikan berenang di latar
#   warna_ikan           : warna ikannya
#   sampah               : berapa keping sampah hanyut
#   arus                 : kecepatan partikel arus, piksel per detik
#   getar                : true untuk panel yang gentingnya perlu terasa

const PEMBUKA := "pembuka"
const ANTARA_1_2 := "antara_1_2"
const ANTARA_2_3 := "antara_2_3"
const PENUTUP := "penutup"
const BANJIR := "banjir"

const CUTSCENES := {
	PEMBUKA: {
		"judul": "KALI BRANTAS, JAWA TIMUR",
		"panel": [
			{
				"teks": "Namaku {nama}.\nAku ikan wader, dan sungai ini rumahku.",
				"air_atas": Color(0.24, 0.42, 0.45), "air_bawah": Color(0.07, 0.16, 0.2),
				"ikan": 1, "warna_ikan": Color(0.85, 0.92, 0.6), "sampah": 0, "arus": 40.0,
			},
			{
				"teks": "Dulu airnya jernih.\nKakekku bilang, dasarnya sampai kelihatan dari permukaan.",
				"air_atas": Color(0.32, 0.58, 0.6), "air_bawah": Color(0.12, 0.3, 0.34),
				"ikan": 6, "warna_ikan": Color(0.9, 0.95, 0.7), "sampah": 0, "arus": 55.0,
			},
			{
				"teks": "Lalu sampah mulai datang.\nSedikit demi sedikit, sampai tidak ada lagi yang menghitung.",
				"air_atas": Color(0.2, 0.28, 0.24), "air_bawah": Color(0.06, 0.11, 0.1),
				"ikan": 2, "warna_ikan": Color(0.6, 0.66, 0.45), "sampah": 14, "arus": 22.0,
			},
			{
				"teks": "Aku masih kecil. Yang besar-besar itu belum bisa kutelan.\n\nTapi aku bisa mulai dari yang kecil, lalu tumbuh.",
				"air_atas": Color(0.22, 0.34, 0.34), "air_bawah": Color(0.07, 0.14, 0.16),
				"ikan": 1, "warna_ikan": Color(0.85, 0.92, 0.6), "sampah": 9, "arus": 34.0,
			},
		],
	},

	ANTARA_1_2: {
		"judul": "SUNGAI CILIWUNG, JAKARTA",
		"panel": [
			{
				"teks": "Brantas bersih.\nUntuk pertama kalinya aku bisa melihat dasarnya sendiri.",
				"air_atas": Color(0.34, 0.6, 0.62), "air_bawah": Color(0.13, 0.32, 0.36),
				"ikan": 5, "warna_ikan": Color(0.9, 0.95, 0.7), "sampah": 0, "arus": 70.0,
			},
			{
				"teks": "Tapi sungai tidak berhenti di batas kota.\nAirnya terus jalan, dan sampahnya ikut jalan.",
				"air_atas": Color(0.26, 0.4, 0.42), "air_bawah": Color(0.09, 0.18, 0.22),
				"ikan": 2, "warna_ikan": Color(0.82, 0.9, 0.6), "sampah": 8, "arus": 95.0,
			},
			{
				"teks": "Ciliwung jauh lebih padat.\nDan di sini aku tidak sendirian --\nmasih ada ikan lain yang bertahan hidup.",
				"air_atas": Color(0.19, 0.27, 0.26), "air_bawah": Color(0.05, 0.1, 0.12),
				"ikan": 7, "warna_ikan": Color(0.55, 0.78, 0.85), "sampah": 16, "arus": 30.0,
				"spesies": ["seluang", "nilem", "kancra", "gabus", "baung"],
			},
			{
				"teks": "Mereka bukan sampah, {nama}.\nSekali pun jangan.",
				"air_atas": Color(0.2, 0.3, 0.3), "air_bawah": Color(0.06, 0.12, 0.14),
				"ikan": 4, "warna_ikan": Color(0.55, 0.78, 0.85), "sampah": 10, "arus": 26.0,
				"spesies": ["seluang", "nilem", "kancra"],
				"getar": true,
			},
		],
	},

	ANTARA_2_3: {
		"judul": "KALI JEROAN, MADIUN",
		"panel": [
			{
				"teks": "Ciliwung bersih juga.\nSampahnya habis, ikannya masih ada.",
				"air_atas": Color(0.32, 0.56, 0.6), "air_bawah": Color(0.12, 0.3, 0.34),
				"ikan": 8, "warna_ikan": Color(0.6, 0.85, 0.9), "sampah": 0, "arus": 80.0,
				"spesies": ["seluang", "nilem", "kancra", "gabus", "baung"],
			},
			{
				"teks": "Tapi jauh di hulu, ada kali yang airnya tetap tidak jalan.\nBersih, dan tetap mati.",
				"air_atas": Color(0.25, 0.34, 0.3), "air_bawah": Color(0.08, 0.14, 0.13),
				"ikan": 1, "warna_ikan": Color(0.8, 0.88, 0.6), "sampah": 0, "arus": 4.0,
			},
			{
				"teks": "Ternyata sampah cuma separuh masalahnya.\nSeparuhnya lagi: batang bambu yang menyumbat, bertahun-tahun.\nWarga menyebutnya brambongan.",
				"air_atas": Color(0.27, 0.36, 0.32), "air_bawah": Color(0.09, 0.15, 0.14),
				"ikan": 1, "warna_ikan": Color(0.8, 0.88, 0.6), "sampah": 6, "arus": 6.0,
			},
			{
				"teks": "Aku sudah coba mendorongnya sendirian.\nTidak bergerak sedikit pun.\n\nJadi kali ini aku tidak datang sendiri.",
				"air_atas": Color(0.24, 0.38, 0.4), "air_bawah": Color(0.08, 0.16, 0.19),
				"ikan": 2, "warna_ikan": Color(0.85, 0.92, 0.65), "sampah": 3, "arus": 12.0,
			},
		],
	},

	# Cutscene ini SATU-SATUNYA yang boleh diputar berulang kali, karena dia
	# bukan babak cerita melainkan akibat. Pemain yang mengulang kesalahan yang
	# sama berhak melihat akibat yang sama -- kalau ditandai "sudah ditonton",
	# kolaps kedua jadi terasa lebih murah daripada yang pertama, dan justru
	# itulah yang tidak boleh terjadi pada pesan bab ini.
	BANJIR: {
		"judul": "SUNGAI CILIWUNG, BEBERAPA MINGGU KEMUDIAN",
		"panel": [
			{
				"teks": "Sampahnya habis.\nAku benar-benar membersihkan semuanya.",
				"air_atas": Color(0.3, 0.5, 0.52), "air_bawah": Color(0.1, 0.26, 0.3),
				"ikan": 1, "warna_ikan": Color(0.85, 0.92, 0.6), "sampah": 0, "arus": 60.0,
			},
			{
				"teks": "Tapi airnya sepi.\nTidak ada lagi yang berenang selain aku.",
				"air_atas": Color(0.2, 0.3, 0.32), "air_bawah": Color(0.06, 0.13, 0.16),
				"ikan": 1, "warna_ikan": Color(0.7, 0.78, 0.5), "sampah": 0, "arus": 26.0,
			},
			{
				"teks": "Ikan-ikan kecil itu yang memakan lumut di batu.\nLumutnya tumbuh tanpa henti sekarang,\ndan akarnya menahan air.",
				"air_atas": Color(0.17, 0.26, 0.2), "air_bawah": Color(0.05, 0.11, 0.09),
				"ikan": 0, "warna_ikan": Color(0.6, 0.7, 0.4), "sampah": 4, "arus": 10.0,
				"getar": true,
			},
			{
				"teks": "Hujan turun tiga hari.\nAirnya tidak punya jalan, dan tidak ada lagi\nyang menahannya selain rumah orang.",
				"air_atas": Color(0.14, 0.16, 0.22), "air_bawah": Color(0.04, 0.05, 0.09),
				"ikan": 0, "warna_ikan": Color(0.5, 0.55, 0.4), "sampah": 12, "arus": 165.0,
				"getar": true,
			},
			{
				"teks": "Aku menang melawan sampahnya, {nama}.\n\nDan tetap kalah.",
				"air_atas": Color(0.11, 0.13, 0.18), "air_bawah": Color(0.03, 0.04, 0.07),
				"ikan": 1, "warna_ikan": Color(0.45, 0.5, 0.38), "sampah": 8, "arus": 120.0,
				"getar": true,
			},
		],
	},

	PENUTUP: {
		"judul": "SUNGAI YANG JALAN LAGI",
		"panel": [
			{
				"teks": "Airnya jalan lagi.\nDari Madiun, ke Ciliwung, sampai ke Brantas.",
				"air_atas": Color(0.4, 0.7, 0.72), "air_bawah": Color(0.16, 0.42, 0.48),
				"ikan": 10, "warna_ikan": Color(0.92, 0.97, 0.75), "sampah": 0, "arus": 130.0,
			},
			{
				"teks": "Aku belajar tiga hal, {nama}.",
				"air_atas": Color(0.36, 0.64, 0.68), "air_bawah": Color(0.14, 0.36, 0.42),
				"ikan": 4, "warna_ikan": Color(0.9, 0.95, 0.7), "sampah": 0, "arus": 100.0,
			},
			{
				"teks": "Satu: sungai yang kelihatan bersih belum tentu hidup.\nKalau penghuninya habis, yang tersisa cuma air.",
				"air_atas": Color(0.3, 0.52, 0.56), "air_bawah": Color(0.11, 0.28, 0.34),
				"ikan": 6, "warna_ikan": Color(0.6, 0.85, 0.9), "sampah": 0, "arus": 90.0,
				"spesies": ["seluang", "nilem", "kancra", "gabus"],
			},
			{
				"teks": "Dua: membersihkan sampah saja tidak cukup.\nAir juga harus punya jalan.",
				"air_atas": Color(0.33, 0.58, 0.62), "air_bawah": Color(0.13, 0.32, 0.38),
				"ikan": 5, "warna_ikan": Color(0.88, 0.94, 0.7), "sampah": 0, "arus": 115.0,
			},
			{
				"teks": "Tiga, dan ini yang paling lama kupahami:\nsumbatan yang paling besar memang tidak bisa didorong sendirian.",
				"air_atas": Color(0.38, 0.66, 0.7), "air_bawah": Color(0.15, 0.4, 0.46),
				"ikan": 2, "warna_ikan": Color(0.9, 0.95, 0.72), "sampah": 0, "arus": 120.0,
			},
			{
				"teks": "Sungai di luar layar ini juga sungguhan.\nBrantas, Ciliwung, Kali Jeroan -- semuanya ada.\n\nDan semuanya masih menunggu.",
				"air_atas": Color(0.42, 0.72, 0.74), "air_bawah": Color(0.18, 0.46, 0.52),
				"ikan": 12, "warna_ikan": Color(0.94, 0.98, 0.78), "sampah": 0, "arus": 140.0,
			},
		],
	},
}


## Cutscene yang diputar SEBELUM sebuah bab dibuka. Bab yang tidak ada di sini
## langsung masuk permainan.
const INTRO_UNTUK_BAB := {
	1: PEMBUKA,
	2: ANTARA_1_2,
	3: ANTARA_2_3,
}


static func intro_untuk_bab(index: int) -> String:
	return String(INTRO_UNTUK_BAB.get(index, ""))


# --- Papan instruksi --------------------------------------------------------
#
# Empat pertanyaan yang harus terjawab SEBELUM pemain menyentuh tombol, dan
# urutannya bukan kebetulan:
#   1. Apa tujuanku?      -- tanpa ini, sisanya tidak ada artinya
#   2. Bagaimana bergerak? -- baru boleh dilepas ke air
#   3. Apa yang bahaya?    -- supaya kematian pertama tidak terasa curang
#   4. Bagaimana melawan?  -- jalan keluarnya, biar tidak cuma menghindar

const BRIEFINGS := {
	1: {
		"judul": "KALI BRANTAS",
		"tujuan": "Habiskan seluruh sampah di sungai, lalu hadapi Induk Sapu-Sapu.",
		"kontrol": [
			["W A S D  /  panah", "berenang ke segala arah"],
			["Spasi  /  Shift", "dash -- meluncur cepat sesaat"],
			["Esc", "menu jeda"],
		],
		"bahaya": [
			"Sampah bercincin MERAH lebih besar dari mulutmu. Menabraknya = kehilangan satu nyawa.",
			"Nyawamu tiga. Habis nyawa, babak diulang.",
			"Sesekali ada ARUS DERAS: garis merah melintang memberi aba-aba sedetik sebelumnya.",
		],
		"cara": [
			"Makan sampah bercincin HIJAU -- itu yang muat di mulutmu sekarang.",
			"Tiap kali cukup makan, kamu naik ukuran dan sampah yang tadinya merah berubah hijau.",
			"Setelah ukuran maksimum, semua sampah bisa dimakan. Habiskan sisanya.",
			"Induk Sapu-Sapu: gigit INSANGNYA hanya saat menyala. Dash untuk menghindari terjangannya.",
		],
	},
	2: {
		"judul": "SUNGAI CILIWUNG",
		"tujuan": "Bersihkan sungai yang jauh lebih padat -- tanpa memakan penghuninya.",
		"kontrol": [
			["W A S D  /  panah", "berenang ke segala arah"],
			["Spasi  /  Shift", "dash -- meluncur cepat sesaat"],
			["Esc", "menu jeda"],
		],
		"bahaya": [
			"Semua bahaya Bab 1 masih berlaku, dan sampahnya lebih rapat.",
			"IKAN LOKAL berwarna biru keperakan. Mereka penghuni sungai, bukan makanan.",
			"Memakan ikan lokal tidak mengurangi nyawamu -- dan justru itu jebakannya. Tidak ada hukuman yang langsung terasa.",
			"Hama SAPU-SAPU butuh beberapa gigitan sampai habis.",
		],
		"cara": [
			"Kalau ikan lokal termakan, dia akan dimuntahkan -- tapi kerusakannya sudah terjadi.",
			"Perhatikan warna air dan nada musiknya. Kalau mulai menggelap dan melambat, berhentilah memakan yang biru.",
			"Sungai dianggap bersih kalau sampah HABIS dan hama sapu-sapu HABIS.",
		],
	},
	3: {
		"judul": "KALI JEROAN",
		"tujuan": "Dorong balok bambu keluar dari lorong air sampai airnya tembus dari HULU (kanan) ke MULUT SUNGAI (kiri). Wader B ikut sendiri -- kamu cuma memegang satu ikan.",
		"kontrol": [
			["W A S D  /  panah", "berenang, dan mendorong balok"],
			["R", "ulangi papan dari awal"],
			["Esc", "menu jeda"],
		],
		"bahaya": [
			"Tidak ada yang bisa membunuhmu di sini. Yang bisa gagal cuma rencanamu.",
			"Balok cuma bisa DIDORONG, tidak bisa ditarik. Balok yang terlanjur mentok tidak bisa dibawa kembali.",
			"Wader B tidak akan pernah mendorong balok yang tidak sedang kamu dorong -- dia tidak akan merusak rencanamu.",
			"Kalau papannya jadi buntu, tekan R untuk mengulang. Itu bukan kalah, itu bagian dari berpikir.",
			"Makin banyak dorongan yang kamu pakai, makin kecil bonusnya.",
		],
		"cara": [
			"Berenanglah menekan sisi balok. Muka yang bisa didorong akan MENYALA lengkap dengan panah arahnya.",
			"Kamu cuma memegang Wader A. Wader B mengikutimu sendiri -- tidak ada tombol ganti ikan.",
			"Balok KECIL cukup kamu sendiri. Balok bertulisan 2 IKAN hanya bergerak kalau Wader B sudah ikut merapat, jadi tunggu sebentar sampai dia sampai.",
			"Lorong yang gelap itu jalan airnya. Petak yang lebih terang di atas dan bawah adalah TEPIAN -- kamu bisa berenang di sana, tapi air tidak lewat.",
			"Jadi buanglah balok ke tepian, dan pakai tepian juga untuk memutari balok yang mau kamu dorong dari sisi lain.",
			"Tidak semua kolom punya jalan keluar ke tepian. Sebagian balok harus digeser menyamping dulu.",
		],
	},
}


# --- Penilaian bintang ------------------------------------------------------
#
# Skor yang dianggap "main sampai tuntas" untuk tiap bab. Tiga bintang berarti
# mencapai angka ini, bukan menyentuh langit-langit teoretis -- bintang penuh
# yang cuma bisa diraih dengan permainan sempurna akan dibaca pemain sebagai
# "tidak mungkin", dan yang tidak mungkin berhenti memotivasi.
const TARGET_SKOR := {1: 2000, 2: 2600, 3: 3000}

## 0 sampai 3.
static func bintang(index: int, skor: int) -> int:
	var target := float(TARGET_SKOR.get(index, 2000))
	if target <= 0.0:
		return 3
	var rasio := float(skor) / target
	if rasio >= 1.0:
		return 3
	if rasio >= 0.7:
		return 2
	if rasio >= 0.4:
		return 1
	return 0


static func briefing_untuk_bab(index: int) -> Dictionary:
	return BRIEFINGS.get(index, {})


## Kunci jejak "sudah pernah lihat" untuk papan instruksi tiap bab. Dibuat lewat
## fungsi, bukan ditulis manual, supaya tidak ada salah ketik yang bikin papan
## muncul terus atau malah tidak pernah muncul.
static func kunci_briefing(index: int) -> String:
	return "briefing_bab%d" % index
