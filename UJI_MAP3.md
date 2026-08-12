# Daftar Uji — Map 3 Kali Jeroan Madiun

Status: **tiga sumbatan, kesulitannya menaik, dan sekarang ada jendela waktu.**
Sebelumnya bab ini cuma 1 sumbatan tanpa tekanan waktu dan skornya selalu 0.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map3_jeroan.tscn
```

Kontrol: **WASD / panah** berenang · **Tab** (atau **Q**, atau **klik ikan**) ganti kendali.

---

## Yang berubah di putaran ini

### 1. Jendela waktu akhirnya ada

Pertanyaan lama di dokumen ini — *"apakah ini sudah terasa seperti puzzle, atau cuma
tugas?"* — sumbernya adalah ikan yang ditinggal diam selamanya, sehingga syarat
"bertahan sekian detik" praktis terpenuhi otomatis.

Sekarang `idle_current_drift = 13` di kedua ikan. Ikan yang Anda tinggalkan pelan-pelan
hanyut **ke kiri**, melawan arah tujuan. Menaruh ikan pertama jadi punya batas waktu, dan
urutan yang Anda pilih mulai berpengaruh.

> **Ini keputusan desain Anda, dan satu angka untuk membatalkannya.**
> Isi `idle_current_drift = 0` di FishA dan FishB, dan bab ini kembali persis seperti
> sebelumnya. Tidak ada kode yang perlu disentuh.

### 2. Tiga sumbatan, bukan satu

| Sumbatan | Posisi | Radius | Waktu tahan | Yang bikin sulit |
|---|---|---|---|---|
| Sumbatan1 | (600, 430) | 200 | 1,4 dtk | air terbuka — di sini pemain belajar aturannya |
| Sumbatan2 | (1030, 310) | 200 | 1,9 dtk | menempel tebing atas, ikan harus berkumpul dari bawah |
| Sumbatan3 | (1380, 580) | 200 | 2,4 dtk | paling jauh, tahan paling lama, hanyut paling terasa |

Yang menaik sengaja **waktu tahan dan jarak tempuh**, bukan radiusnya. Radius yang
diperkecil terus akan bentrok dengan lantai fisik 116 px (badan sumbatan 86 + ikan 30) —
ikan tidak akan pernah bisa lebih dekat dari itu, jadi memperkecil radius cuma menyisakan
pita sempit yang membuat puzzle terasa jahil, bukan sulit.

### 3. Skor Bab 3 tidak lagi nol

Dulu `record_score(3, GameState.score)` dipanggil, tapi **tidak ada satu pun yang pernah
menambah skor di Map 3**. Akibatnya kartu Bab 3 di layar pilih bab selalu berbunyi
"SELESAI skor terbaik 0", dan "Skor terbaik keseluruhan" di menu utama diam-diam
mengabaikan sepertiga permainan.

Sekarang tiap sumbatan memberi **500 + bonus efisiensi sampai 500**, bonusnya menyusut
habis dalam 24 detik sejak sumbatan sebelumnya terbuka. Skor sempurna satu ronde = **3000**.

Kenapa waktu yang dipakai sebagai ukuran padahal ini bukan lomba lari: di bab ini tidak
ada nyawa dan tidak ada sampah, jadi tidak ada lagi yang bisa diukur dengan jujur. Pemain
yang salah membaca aturannya akan bolak-balik menggerakkan satu ikan dan membiarkan
progres menyusut — dan itu semua muncul sebagai detik yang terbuang. Waktu jeda tidak
ikut dihitung.

---

## Sudah diuji otomatis — tidak perlu diulang

- Tiga sumbatan terbaca wasit; waktu tahan menaik 1,4 → 1,9 → 2,4
- **Ketiganya masih bisa diselesaikan** dengan hanyut menyala. Jendela ikan yang diparkir
  6,5 dtk, sedangkan yang dibutuhkan (perjalanan ikan kedua + waktu tahan + jeda menekan
  Tab) paling banyak 5,1 dtk di Sumbatan3
- Radius antar sumbatan tidak bertumpuk (446 px dan 442 px, ambangnya 400 px) — jadi tidak
  pernah ada dua cincin progres terisi bersamaan
- Tidak ada sumbatan yang tertanam di dalam tebing
- Skor: cepat → 1000, lambat → tetap dapat 500 dasarnya, setengah waktu → 750
- Bar aliran tidak menghitung ganda saat satu sumbatan sedang pecah
- Gerbang progres, pergantian kendali, tebing menahan, kamera dua ikan, layar ending
  (semuanya dari putaran sebelumnya, masih lulus)

---

## A. Kejelasan mekanik (yang paling penting)

Main **tanpa membaca dokumen ini dulu**.

- [ ] Dari banner pembuka saja, paham bahwa butuh **dua** ikan?
- [ ] Satu ikan dekat (**outline kuning + garis kuning**) terbaca sebagai "benar, tapi
      kurang satu"?
- [ ] Dua ikan dekat (**outline biru + cincin mengisi**) jelas berarti tinggal bertahan?
- [ ] Detak suara yang makin cepat membantu saat mata Anda sedang melihat ikan?

## B. Jendela waktu — yang paling perlu dinilai sekarang

- [ ] **Sadar sendiri bahwa ikan yang ditinggal hanyut**, atau baru tahu setelah membaca
      petunjuk di bawah layar?
- [ ] 13 px/dtk terasa **pas, terlalu pelan (tidak berasa), atau terlalu cepat (menjengkelkan)**?
- [ ] Pernah gagal karena ikan pertama keluar radius tepat sebelum selesai? Kalau ya,
      terasa adil atau curang?
- [ ] Sumbatan3 (paling jauh + tahan 2,4 dtk) terasa sebagai puncak, atau sudah frustrasi?

## C. Kesulitan yang menaik

- [ ] Urutan Sumbatan1 → 2 → 3 terasa makin sulit, atau sama saja?
- [ ] Sumbatan2 yang menempel tebing: jelas harus dikerjakan dari bawah?
- [ ] Tiga sumbatan terasa **cukup, kurang, atau kepanjangan**? (catat menitnya)

## D. Skor

- [ ] Angka "+1000" / "+750" di banner terbaca sebagai hadiah karena cepat?
- [ ] Skor di kanan atas mengganggu, atau membantu?
- [ ] Setelah tamat, skor Bab 3 muncul benar di kartu layar pilih bab?

## E. Bagian akhir

- [ ] Sumbatan terdorong keluar lalu pecah: terbaca sebagai **didorong berdua**?
- [ ] Layar "SUNGAI LANCAR" terasa sebagai penutup yang pantas?

---

## Tombol setelan Map 3

| Yang mau diubah | Node | Properti |
|---|---|---|
| **Kuat arus menghanyutkan ikan yang ditinggal** | FishA / FishB | `idle_current_drift` (13; **0 = mati**) |
| Arah arus | FishA / FishB | `idle_current_direction` (kiri) |
| Nilai dasar tiap sumbatan | Map3Jeroan | `score_per_obstacle` (500) |
| Bonus cepat maksimum | Map3Jeroan | `max_efficiency_bonus` (500) |
| Lama bonus habis | Map3Jeroan | `bonus_fade_seconds` (24 dtk) |
| Radius "dekat sumbatan" | tiap Sumbatan | `push_radius` (200) |
| Lama harus bertahan | tiap Sumbatan | `hold_time` (1,4 / 1,9 / 2,4) |
| Cepatnya progres menyusut | tiap Sumbatan | `decay_rate` (0,55) |
| Kecepatan & rem ikan | FishA / FishB | `max_speed` (300), `water_drag` (1400) |
| Batas zoom kamera | DuoCamera | `zoom_range` (1,0 → 0,62) |
| Gerbang progres | Map3Jeroan | `requires_map2`, `bypass_progress_gate` |

## Menambah sumbatan lagi nanti

Duplikat salah satu node **Sumbatan** di dalam `Obstacles`, geser posisinya. Wasitnya
menghitung sendiri berapa yang ada dan mengatur bar aliran, skor, serta ending. Tidak ada
angka total yang perlu diubah manual.

**Dua syarat yang perlu dijaga** kalau menggeser atau menambah:
1. Jarak ke sumbatan tetangga harus **lebih besar dari jumlah kedua radiusnya** (dengan
   radius 200, artinya lebih dari 400 px), supaya tidak ada dua cincin terisi sekaligus.
2. `(push_radius - 116) / idle_current_drift` harus **lebih besar dari** waktu tempuh ikan
   kedua ditambah `hold_time`, kalau tidak sumbatan itu mustahil dibuka.

---

## Belum ada — sengaja

- **Latar masih sederhana**: gradasi air + tebing polos + partikel arus. Belum ada sprite
  lingkungan asli.
- **Layar ending masih placeholder**: latar biru + garis arus bergerak + teks.
- Map 3 tidak memakai satu pun script Map 1/2. `player_fish.gd`, `trash.gd`, `hud.gd`,
  dan `map_manager.gd` tidak disentuh, jadi tidak ada kode mati yang terbawa.
