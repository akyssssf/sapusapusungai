# Daftar Uji — Map 2 Sungai Ciliwung

Status: **Map 2 selesai dan bisa dimainkan.** Map 3 belum dimulai.

```
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/maps/map2_ciliwung.tscn
```

Atau mainkan Map 1 sampai menang — layar menangnya sekarang menawarkan lanjut ke Ciliwung.

> ### ⚠ Satu hal yang WAJIB diubah sebelum build final
> Di `map2_ciliwung.tscn`, node **Map2Ciliwung** punya properti `bypass_progress_gate`
> yang saya set **true** supaya Anda bisa membuka Map 2 langsung tanpa menamatkan Map 1
> setiap kali menguji. **Matikan sebelum build**, kalau tidak gerbang progresnya percuma.

---

## Sudah diuji otomatis — tidak perlu diulang

- Gerbang progres: `map1_completed=false` → babak TERKUNCI + overlay; `true` → main normal
- Map 1 menang → `map1_completed` jadi true, layar menang menawarkan lanjut ke Ciliwung
- Ikan lokal: 7 ditebar, bergerak sendiri, **node tidak hancur saat termakan**,
  terlempar menjauh, **skor tidak naik, pemain tidak tumbuh**, hitungan tersembunyi +1
- Jeda kebal 1,6 dtk menahan hitungan ganda (menempel 0,5 dtk tetap terhitung 1)
- Ikan lokal kembali berenang normal sesudah terhuyung (52 px dalam 1 detik)
- Sapu-sapu: 3 HP, ikan level 1 menabrak → HP tetap 3; ikan besar → hancur, skor +120
- Ambang tersembunyi: alpha selubung dan nada musik naik-turun bertahap dari hitungan ke-3
- Hitungan ke-5 → babak BANJIR, pemain dibekukan, `last_ending = BANJIR`
- Layar game over: teks ending banjir benar, air naik memenuhi layar, kunci input 1,4 dtk
- `scripts/hud.gd` dan `hud.tscn` **tidak punya satu pun rujukan** ke hitungan ikan lokal,
  jadi angkanya tidak mungkin bocor ke layar

---

## A. Ikan lokal — yang harus dilindungi

- [ ] Gerakannya terbaca sebagai **ikan hidup**, bukan titik yang bergeser?
- [ ] Mereka menghindar saat Anda mendekat — terasa membantu atau malah menjengkelkan?
- [ ] Saat tidak sengaja termakan: **jelas** bahwa ikannya dimuntahkan, bukan hilang?
- [ ] Tiga rona warnanya cukup membedakan mereka sebagai spesies berbeda?
- [ ] **Bisa dibedakan dari sampah** saat sedang buru-buru makan?

## B. Sapu-sapu — hama yang harus dibersihkan

- [ ] Geraknya yang lamban **langsung terbaca berbeda** dari ikan lokal yang lincah?
- [ ] Tiga titik biru di punggungnya kebaca sebagai sisa ketahanan?
- [ ] Terpental tiap gigitan: terasa sebagai perjuangan, atau menjengkelkan?
- [ ] Saat ikan masih kecil dan menabraknya, jelas bahwa "belum cukup besar"?
- [ ] 3 HP dan 6 ekor: pas, atau terlalu cepat/lama?

## C. Ambang tersembunyi (bagian paling penting)

**Jangan baca kodenya dulu.** Mainkan seolah-olah Anda pemain baru.

- [ ] Makan **3 ikan lokal**, lalu main biasa 30 detik. **Sadar ada yang berubah?**
- [ ] Kalau sadar — dari **warna air** dulu, atau dari **nada musik** dulu?
- [ ] Apakah terasa seperti firasat, atau seperti bug ("kok layarnya jadi gelap")?
- [ ] Di hitungan ke-4 (selubung berdenyut), sudah cukup jelas sebagai peringatan?
- [ ] Hitungan ke-5 → banjir: terasa **pantas**, atau tiba-tiba tanpa peringatan?
- [ ] Teks "Ekosistem kolaps" menyampaikan pesannya, atau perlu diperjelas?

Kalau Anda main dan **tidak sadar sama sekali** sampai banjir datang, sinyalnya terlalu
samar — naikkan `doomed_tint.a` atau turunkan `music_pitch_at_doom` di node
**EcosystemOverlay**. Kalau justru langsung ketahuan di ikan pertama, kebalikannya.

## D. Gerbang progres

- [ ] Matikan `bypass_progress_gate`, buka Map 2 langsung → muncul layar terkunci?
- [ ] Tekan Enter di layar terkunci → kembali ke Kali Brantas?
- [ ] Menangkan Map 1 → Enter membawa ke Ciliwung dan bisa dimainkan?

## E. Suasana Map 2

- [ ] Air Ciliwung terasa **lebih keruh dan lebih tercemar** daripada Brantas?
- [ ] Musik Ciliwung terasa berbeda dari Brantas, bukan cuma lagu yang sama?
- [ ] Latar placeholder-nya cukup enak dilihat untuk sementara, atau mengganggu?

---

## Tombol setelan Map 2

| Yang mau diubah | Node | Properti |
|---|---|---|
| Ambang peringatan & kolaps | — | `ECOSYSTEM_WARNING_AT` / `ECOSYSTEM_LIMIT` di `game_state.gd` |
| Pekatnya selubung saat kritis | EcosystemOverlay | `doomed_tint` (alpha 0.62) |
| Kecepatan selubung menggelap | EcosystemOverlay | `tint_response` (0.9) |
| Turunnya nada musik | EcosystemOverlay | `music_pitch_at_doom` (0.9) |
| Kapan selubung mulai berdenyut | EcosystemOverlay | `pulse_from` (0.65) |
| Jumlah ikan lokal & hama | WildlifeDirector | `local_fish_count` (7), `sapu_sapu_count` (6) |
| Kelincahan ikan lokal | LocalFish | `swim_speed` (108), `flee_radius` (150) |
| Jeda kebal hitungan | LocalFish | `immune_time` (1.6) |
| Ketahanan sapu-sapu | SapuSapu | `max_health` (3), `required_size_level` (2) |
| Pentalan tiap gigitan | SapuSapu | `knockback_force` (380) |
| Kepadatan sampah Map 2 | TrashDirector | `target_count` (26) |
| Gerbang progres | Map2Ciliwung | `requires_map1`, `bypass_progress_gate` |

---

## Belum ada di Map 2 — sengaja

- **Bos.** `boss_scene` sengaja dikosongkan; sungai bersih langsung berarti menang.
  Kalau nanti Map 2 mau punya bos, cukup isi properti itu — alurnya sudah siap.
- **Sprite environment asli.** Latar masih placeholder gradasi + dasar sungai polos,
  sesuai permintaan.
- **Sprite ikan lokal asli** (nilem/tawes/betok). Sekarang masih satu tekstur Kenney
  dengan tiga rona.
- **Detail visual banjir.** Layar game over baru berupa latar biru + teks.
