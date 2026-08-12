# Daftar Uji — Map 1 Kali Brantas

Status: **Map 1 lengkap dan siap dites.** Map 2 dan Map 3 belum dimulai.

Jalankan dengan **F5** di Godot, atau:

```
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Kontrol: **WASD / panah** berenang · **Spasi / Shift** dash · **Enter** ulang di layar hasil.

> **Perubahan 11 Agustus 2026 (putaran ketiga)**
> Dari laporan "tempo kurang berasa, cepat sampai level maksimum, bos cuma sedot-sedot":
> fase berburu diperpanjang (`growth_per_level` 100 → **350**), ketukan kejadian dirapatkan
> jadi 2,2–3,4 detik, pemilihan kejadian diganti **kantong acak** yang menjamin keempat
> jenis muncul bergiliran, ditemukan dan diperbaiki **bug sungai tersumbat**, dan bos
> sekarang punya **tiga serangan** (SEDOT / TERJANG / HUJAN) yang diundi tanpa pengulangan
> beruntun, masing-masing dengan aba-aba dan panjang jendela serang berbeda.

> **Perubahan 11 Agustus 2026 (putaran kedua)**
> Peta dikecilkan dari 2048x1152 jadi **1664x936** (luas air turun 35%), sampah dinaikkan
> jadi 30 butir sehingga **kepadatannya 2,2x lipat**, cooldown dash dipotong 2,2 -> **1,1 detik**,
> dan ada tiga sumber tantangan baru: **tekanan yang naik seiring waktu**, **arus deras**,
> serta **batang bambu hanyut** dari kiri/kanan yang harus dihindari.

---

## Sudah diuji otomatis — tidak perlu Anda ulang

Semua ini sudah saya jalankan lewat Godot headless dan hasilnya benar. Kalau salah satunya
ternyata rusak saat Anda main, berarti ada yang saya lewatkan — tolong laporkan.

- Sampah kecil dimakan → skor naik, ikan tumbuh; sampah kebesaran → nyawa berkurang 1
- Ukuran mentok di level 5; skor tetap naik sesudahnya, ukuran tidak
- Batas renang: ikan tidak bisa keluar peta maupun masuk ke dasar sungai
- Dash: 3,2× kecepatan, ~192 px sekali lompat, cooldown 1,1 detik, tidak bisa dipakai dobel
- Nyawa habis → babak KALAH, ikan beku, overlay muncul, semua hati padam
- Kunci 1 detik sebelum tombol ulang aktif
- Mulai ulang benar-benar bersih (nyawa 3, ukuran 1, skor 0, dash siap)
- Arus sampah stabil di 30 butir, naik sementara saat gerombolan/pagar lewat
- Kantong kejadian: dari 60 undian, tiap jenis muncul rata dan jeda terpanjangnya
  4 kejadian (dulu satu jenis bisa tidak muncul sama sekali dalam satu sesi)
- Sungai tidak tersumbat: bagian isi yang belum bisa dimakan ditahan di ~0,39
- Robot pemburu sempurna: 23,6 dtk ke ukuran maksimum, kebagian 2 arus deras +
  2 batang bambu (manusia biasanya 1,5–2x lebih lama, jadi 3–4 kali masing-masing)
- Bos: tiga serangan bergiliran tanpa pengulangan beruntun, aba-aba terjangan terpancar,
  hujan sampah melepas 15 butir dalam 3 gelombang
- Kepadatan sampah 22,6 butir per juta px² (sebelum perubahan: 10,2)
- Batang bambu: aba-aba tampil dulu → batang lahir setelah jeda → melukai walau ikan
  sudah ukuran maksimum → hilang sendiri setelah menyeberang
- Batang bambu tidak ikut terhitung sebagai "sampah", jadi tidak menunda kedatangan bos
- Arus deras mengalikan kecepatan semua sampah lalu mengembalikannya ke 1,0
- Aba-aba yang belum berbuah dibatalkan saat sungai dinyatakan bersih
- Bos: kelima fase berjalan, semburan keluar 5 butir, insang bisa digigit, 5 pelat → tumbang → MENANG
- Musik bertukar ke tema bos dan kembali tenang saat menang
- Mode kontrol pointer berfungsi

**Yang tersisa cuma hal yang tidak bisa diukur mesin: rasa.** Fokus ke situ.

---

## A. Rasa gerak & dash

- [ ] Berenang di **level 1** enak? (ini yang dulu sudah Anda bilang enak — pastikan tidak rusak)
- [ ] Berenang di **level 5** masih enak, tidak berat lagi?
- [ ] Kamera yang menjauh saat ikan membesar membantu, atau malah bikin ikan terasa lambat?
- [ ] Dash terasa punya tenaga, atau cuma seperti "agak cepat sebentar"?
- [ ] Cooldown 1,1 detik: sudah pas, atau masih kelamaan / malah jadi tombol spam?
- [ ] Dash tanpa menekan arah (melesat ke arah hadap) terasa benar atau membingungkan?
- [ ] Liukan badan + kemiringan saat naik-turun: hidup, atau berlebihan sampai mengganggu?

## B2. Batang bambu hanyut (BARU)

Melesat menyeberangi sungai ~2x lebih cepat daripada ikan, dari tepi kiri **atau** kanan.
**Tidak bisa dimakan seukuran apa pun** -- satu-satunya jawaban adalah menyingkir.
Sebelum datang, muncul panah merah di tepi layar plus garis merah yang menandai jalurnya.

- [ ] Aba-abanya cukup lama untuk sempat menyingkir? (1,45 dtk di awal, menyempit jadi 1,0)
- [ ] Garis merah jalurnya terbaca jelas, tidak tertukar dengan hiasan lain?
- [ ] Batangnya benar-benar lurus mendatar, tepat di garis merah tadi?
- [ ] Bunyi peringatan (dua bip) langsung dikenali sebagai "awas", bukan sekadar bunyi?
- [ ] Saat tekanan tinggi kadang datang dua sekaligus dari sisi berbeda -- masih adil?
- [ ] Dash terasa berguna untuk kabur dari jalurnya?

## B3. Arus deras (BARU)

Sesekali seluruh isi sungai mendadak melesat 3,4x lebih cepat selama ~2,8 detik,
disertai banner "ARUS DERAS!" dan deru air.

- [ ] Terasa sebagai kejadian besar, atau cuma gangguan?
- [ ] Masih bisa dikendalikan, atau langsung kehilangan nyawa tanpa bisa berbuat apa-apa?

## B. Sampah, nyawa, tantangan

- [ ] Cincin merah pada sampah kebesaran **langsung terbaca** sebagai "jangan disentuh"?
- [ ] Momen cincin hilang (saat naik level 3 dan 5) terasa sebagai hadiah?
- [ ] **Gerombolan** sampah kecil terasa menyenangkan saat dipanen?
- [ ] **Pagar sampah** (kolom sampah besar dengan satu celah): adil atau menjengkelkan?
- [ ] Kena serang: pentalan + kedipan + getaran layar sudah jelas, atau malah bikin bingung?
- [ ] 3 nyawa cukup, atau terlalu sedikit/banyak?
- [ ] Berapa lama dari mulai sampai level 5? (**tolong catat menitnya** — target ideal 2–3 menit)
- [ ] **Peta sudah terasa pas, atau masih terlalu luas / malah jadi sempit?**
- [ ] Tekanan yang naik (kejadian makin rapat, arus makin deras setelah ~70 detik) terasa?
- [ ] Sekarang masih membosankan, atau justru sudah kelewat ramai?

## C. Babak bersih-bersih

- [ ] Banner "Ukuran maksimum! Habiskan sisa sampahnya" terbaca tepat waktu?
- [ ] Menghabiskan sisa sampah terasa memuaskan, atau jadi tugas membosankan?
- [ ] Sisanya terlalu banyak/sedikit? Kalau kelamaan, `target_count` diturunkan.

## D2. Tiga serangan bos (BARU)

Setiap putaran bos mengundi satu dari tiga serangan, **dijamin tidak berulang beruntun**.
Aba-abanya berbeda, dan jendela serang sesudahnya juga berbeda panjang.

| Serangan | Aba-aba | Jawaban | Jendela LEMAH |
|---|---|---|---|
| **SEDOT** | bergetar di tempat, mulut menganga | berenang menjauh | 2,1 dtk |
| **TERJANG** | badan **memerah**, mundur ancang-ancang, **garis merah** menandai jalur | **keluar dari jalur**, bukan lari lurus | **2,9 dtk** (paling lama) |
| **HUJAN** | badan menggembung kuning, mulut berdenyut cepat | terus bergerak menyelip celah | 1,7 dtk (paling singkat) |

- [ ] Ketiga serangan benar-benar terasa **berbeda cara menghadapinya**?
- [ ] Aba-abanya bisa dikenali sebelum serangannya keluar, atau masih menebak?
- [ ] Garis merah terjangan sama artinya dengan garis merah batang bambu (tidak membingungkan)?
- [ ] Jendela serang yang lebih panjang setelah terjangan terasa sebagai hadiah?
- [ ] Bosnya **masih membosankan atau sudah tidak**?

## D. Bos — Induk Sapu-Sapu

> **Diperbaiki 11 Agustus 2026** setelah laporan "tidak bisa menyerang bos, malah ikut luka".
> Ada empat cacat sekaligus: (1) fase masuk berakhir karena waktu habis, bukan karena
> sudah tiba, jadi bos berhenti di luar arena dan insangnya tak terjangkau; (2) arah hadap
> bos tidak pernah berbalik, jadi insang selalu di sisi kanan; (3) tidak ada yang menjaga
> insang tetap di dalam batas renang pemain; (4) begitu insang digigit, hitbox badan
> menyala tepat di atas pemain sehingga serangan yang berhasil langsung dibalas satu nyawa.
> Sekarang deteksi sentuhan tidak lagi memakai sinyal `body_entered` melainkan memeriksa
> tumpang tindih tiap frame, dan ada fase MUNDUR singkat setelah bos kena gigit.
> **Simulasi di peta baru: robot yang main benar menang tanpa kena sama sekali, 26,4 detik.**

- [ ] **Insang bisa digigit dan pelat benar-benar berkurang** (bar bos turun satu petak)
- [ ] **Menggigit insang TIDAK mengurangi nyawa Anda**
- [ ] Bos berenang menghadap ke arah yang benar, tidak mundur
- [ ] Bos tidak pernah menempel/keluar dari tepi peta sampai insangnya tak terjangkau
- [ ] Sentakan mundur bos setelah kena gigit terbaca sebagai "serangan saya masuk"
- [ ] Aba-aba fase INCAR (badan bergetar) cukup jelas sebelum sedotan datang?
- [ ] Sedotan terasa **berat tapi bisa dilawan**, bukan mustahil?
- [ ] Insang menyala cyan langsung terbaca sebagai "serang sekarang"?
- [ ] Jendela LEMAH cukup untuk sampai ke insang dari jarak aman?
- [ ] Semburan sampah bisa dihindari? Sudah tahu kalau yang sudah pudar boleh dimakan?
- [ ] Pertarungan makin menegang saat pelat tinggal sedikit, atau malah jadi kacau?
- [ ] **Berapa kali percobaan sampai menang?** (2–4 kali itu sehat)

## E. Audio

Ingat: semua suara ini **sintetis buatan sendiri, kualitas prototipe.** Yang dinilai bukan
kualitas rekamannya, tapi apakah *waktu dan perannya* sudah tepat.

- [ ] Volume seimbang? Ada yang terlalu keras/pelan? (setel `sfx_volume_db` / `music_volume_db`)
- [ ] Bunyi makan tidak melelahkan setelah 50 kali?
- [ ] Musik ambien slendro cocok dengan suasana Kali Brantas?
- [ ] Loop musik terasa mulus, atau ada jeda/klik di sambungannya?
- [ ] Pergantian ke musik bos terasa menegangkan?
- [ ] Nada `boss_hit` yang naik tiap pelat pecah kebaca sebagai hitung mundur?

## F. Tampilan

- [ ] Ikan pemain cukup kontras dengan air di semua kedalaman?
- [ ] Berkas cahaya + debu air + gelembung: hidup, atau terlalu ramai?
- [ ] Dasar sungai dan tanaman bergoyang enak dilihat?
- [ ] Bos terbaca sebagai ikan sapu-sapu, atau perlu diperjelas?
- [ ] HUD terbaca tanpa harus dicari? (skor, ukuran, nyawa, dash, bar bos)

## G. Cari bug

- [ ] Main **10 menit tanpa berhenti** — ada yang melambat atau macet?
- [ ] Ulang 5 kali berturut-turut lewat Enter — ada yang tertinggal dari ronde sebelumnya?
- [ ] Kalah **saat sedang lawan bos** — layar hasil dan tombol ulang tetap benar?
- [ ] Dash tepat ke mulut bos saat menyedot — ada yang aneh?
- [ ] Coba ubah ukuran jendela / fullscreen — HUD tetap pada tempatnya?

---

## Tombol setelan (semua di Inspector)

| Yang mau diubah | Node | Properti |
|---|---|---|
| Kecepatan ikan besar | PlayerFish | `speed_scale_per_level` (1.05) |
| Jarak & tenaga dash | PlayerFish | `dash_speed_multiplier` (3.2), `dash_duration` (0.18) |
| Jeda dash | PlayerFish | `dash_cooldown` (1.1) |
| Dash bisa menembus bahaya | PlayerFish | `dash_grants_invulnerability` (mati) |
| Jumlah nyawa | PlayerFish | `max_health` (3) |
| Lama kebal sesudah kena | PlayerFish | `invulnerable_time` (1.3) |
| Kepadatan sampah | TrashDirector | `target_count` (30) |
| Ukuran peta | Map1Brantas | `world_size` (1664 x 936) |
| Cepat lambatnya tekanan naik | TrashDirector | `ramp_seconds` (45) |
| Batas sumbatan ranjau | TrashDirector | `max_blocked_ratio` (0.35) |
| Kecepatan terjangan bos | BossSapu | `charge_speed` (1000) |
| Jumlah gelombang hujan sampah | BossSapu | `hujan_waves` (3) x `hujan_per_wave` (5) |

| Lama aba-aba batang bambu | TrashDirector | `rush_lead_time` (1.45 -> 1.0) |
| Kecepatan batang bambu | TrashDirector | `rush_speed` (700 -> 980) |

| Seberapa sering kejadian | TrashDirector | `beat_delay_range` (2,2–3,4 dtk) |
| Panjang fase berburu | PlayerFish | `growth_per_level` (350) |
| Nilai tiap tier sampah | — | tabel `TIER_DATA` di `scripts/trash.gd` baris 24 |
| Lama tiap fase bos | BossSapu | `aim_time` / `suck_time` / `weak_time` / `spit_time` |
| Kekuatan sedotan | BossSapu | `suction_pull_speed` (265) |
| Jumlah pelat bos | BossSapu | `max_plates` (5) |
| Volume | AudioManager | `sfx_volume_db` (−4), `music_volume_db` (−13) |

---

## Belum ada — sengaja, bukan terlewat

- **Kontrol sentuh Android.** Mode pointer sudah jalan, tapi belum ada joystick layar
  maupun tombol dash di layar. Perlu dikerjakan sebelum build Android.
- **Menu utama** dan `game_over.tscn` terpisah. Sekarang layar hasil masih menumpang di HUD.
- **Audio final.** Yang ada sekarang sintetis. Untuk karya penyisihan sebaiknya diganti
  rekaman asli atau aset CC0.
- **Sprite final** sampah, sapu-sapu, dan ikan wader. Semua masih Polygon2D/Kenney.
- **Map 2 dan Map 3.**
- `node_2d.tscn` di folder root — scene kosong yang tidak terpakai, aman dihapus.

---

## Cara melapor balik

Yang paling berguna buat saya, berurutan:

1. **Angka**: berapa menit sampai level 5, berapa kali mati sebelum menang lawan bos.
2. **Kalimat rasa**: "dash-nya kurang nendang", "pagar sampah bikin kesal" — persis
   seperti "makin besar makin berat" kemarin. Itu langsung bisa saya terjemahkan ke angka.
3. **Bug**: apa yang Anda lakukan tepat sebelum kejadian.

Tidak perlu menyaring dulu. Sebutkan apa saja yang mengganjal, biar saya yang pilah.
